---@class BoatManager
---@field vehicles Boat[]
---@field raycastMaxDistance number
BoatManager = {}

local BoatManager_mt = Class(BoatManager)

---@return BoatManager
---@nodiscard
function BoatManager.new()
    ---@type BoatManager
    local self = setmetatable({}, BoatManager_mt)

    self.vehicles = {}
    self.raycastMaxDistance = 25

    self:registerSoundModifierTypes()
    self:registerOverwrittenFunctions()

    return self
end

function BoatManager:registerSoundModifierTypes()
    -- [min .. max] RPM from XML
    g_soundManager:registerModifierType("BOAT_MOTOR_RPM", Boat.getMotorRpmReal)

    -- [0 .. 1] acceleration (absolute, in either direction)
    g_soundManager:registerModifierType("BOAT_ACCELERATION", Boat.getMotorRpmPercentage)
end

function BoatManager:registerOverwrittenFunctions()
    Boat.onPreLoad = Utils.overwrittenFunction(Boat.onPreLoad, BoatManager.inj_Boat_onPreLoad)
    Boat.onLoadFinished = Utils.overwrittenFunction(Boat.onLoadFinished, BoatManager.inj_Boat_onLoadFinished)
    Boat.onDelete = Utils.overwrittenFunction(Boat.onDelete, BoatManager.inj_Boat_onDelete)
    Boat.onUpdate = Utils.overwrittenFunction(Boat.onUpdate, BoatManager.inj_Boat_onUpdate)
    Boat.onBoatWaterPlaneRaycastCallback = Utils.overwrittenFunction(Boat.onBoatWaterPlaneRaycastCallback, BoatManager.inj_Boat_onBoatWaterPlaneRaycastCallback)
    Boat.setBoatWaterPlaneId = Utils.overwrittenFunction(Boat.setBoatWaterPlaneId, BoatManager.inj_Boat_setBoatWaterPlaneId)
end

---@param vehicle Boat
function BoatManager:add(vehicle)
    table.insert(self.vehicles, vehicle)
end

---@param vehicle Boat
function BoatManager:remove(vehicle)
    table.removeElement(self.vehicles, vehicle)
end

--[[
    Handles the case where a stationary, unoccupied boat needs to follow an animated water plane.
    When a boat is sleeping (stationary and unoccupied) its physics body is inactive, so onUpdateTick
    and its raycasts stop firing and the boat no longer tracks the water surface.
    --
    Each frame we read the water plane node's world Y directly and compare it to the previous frame.
    When the water is moving we call setSleepingThresholds(0, 0) to disable physics sleeping on the
    boat body (waking it if already asleep) and raiseActive() to keep it in the script update loop.
    This lets the existing onUpdateTick raycasts and joint spring move the boat naturally and smoothly.
    When the water settles we restore the normal sleep thresholds (0.3 / 0.35) so the boat can sleep
    again. Server only — clients follow via normal vehicle position sync.
]]
---@param dt number
function BoatManager:update(dt)
    local heightChangeThreshold = 0.005

    for _, vehicle in ipairs(self.vehicles) do
        if vehicle.isDeleted or (vehicle.isDeleting or not vehicle.isAddedToPhysics) then
            continue
        end

        ---@type Boat_spec
        local spec = vehicle[Boat.SPEC_TABLE_NAME]

        if spec.waterPlaneId ~= nil then
            local _, nodeY, _ = getWorldTranslation(spec.waterPlaneId)
            local lastY = spec.lastWaterPlaneHeight
            spec.lastWaterPlaneHeight = nodeY

            if lastY ~= nil then
                local waterDelta = nodeY - lastY

                if math.abs(waterDelta) > heightChangeThreshold then
                    -- Water is moving: disable physics sleeping so the body stays awake,
                    -- then keep the vehicle in the update loop so raycasts keep firing.
                    -- The existing joint spring moves the boat smoothly to the new height.
                    if not spec.keepAwake then
                        setSleepingThresholds(vehicle.rootNode, 0, 0)
                        spec.keepAwake = true
                    end
                    vehicle:raiseActive()
                elseif spec.keepAwake then
                    -- Water has settled: restore the thresholds set in Boat.addToPhysics.
                    setSleepingThresholds(vehicle.rootNode, 0.3, 0.35)
                    spec.keepAwake = false
                end
            end
        else
            spec.lastWaterPlaneHeight = nil

            if spec.keepAwake then
                setSleepingThresholds(vehicle.rootNode, 0.3, 0.35)
                spec.keepAwake = false
            end
        end
    end
end

--[[
    Prevent the Boat specialization setting custom vehicle position compression parameters.
]]
---@param vehicle Boat
---@param superFunc function
function BoatManager.inj_Boat_onPreLoad(vehicle, superFunc)
    -- void
end

--[[
    Prevent water sound samples playing by default when Boat is loaded.
]]
---@param vehicle Boat
---@param superFunc function
function BoatManager.inj_Boat_onLoadFinished(vehicle, superFunc)
    ---@type Boat_spec
    local spec = vehicle[Boat.SPEC_TABLE_NAME]

    superFunc(vehicle)

    if spec.waterSamples ~= nil then
        g_soundManager:stopSamples(spec.waterSamples)
        spec.waterSamplesArePlaying = false
    end

    g_boatManager:add(vehicle)
end

---@param vehicle Boat
---@param superFunc function
function BoatManager.inj_Boat_onDelete(vehicle, superFunc)
    g_boatManager:remove(vehicle)

    superFunc(vehicle)
end

--[[
    Override waterEffectsMinSpeed in order to prevent water effects (if applicable) when the boat is out of the water
]]
---@param vehicle Boat
---@param superFunc function
function BoatManager.inj_Boat_onUpdate(vehicle, superFunc, ...)
    ---@type Boat_spec
    local spec = vehicle[Boat.SPEC_TABLE_NAME]
    local previousWaterEffectsMinSpeed = spec.waterEffectsMinSpeed

    if spec.waterPlaneId == nil then
        spec.waterEffectsMinSpeed = 1000
    end

    superFunc(vehicle, ...)

    spec.waterEffectsMinSpeed = previousWaterEffectsMinSpeed
end

--[[
    Override raycast callback in order to allow lifting boats out of the water if distance to waterplane is too great.
    It raycasts downwards at vehicle root node position with y offset + 25.0 looking for closest waterplane
    Raycast distance is 50.0
    --
    Also handles animated water planes (e.g. lock/dam systems): when the water plane node moves but
    keeps the same node ID, the original code skips joint recreation. We detect the height change and
    force the physics joint to be rebuilt at the new water surface level so the joint spring pulls the
    boat to the new height. This covers boats that are active (player aboard or boat already moving).
]]
---@param vehicle Boat
---@param superFunc function
---@param nodeId number
---@param x number
---@param y number
---@param z number
---@param distance number
---@param nx number
---@param ny number
---@param nz number
---@param subShapeIndex number
---@param shapeId number
---@param isLast boolean
---@return boolean?
function BoatManager.inj_Boat_onBoatWaterPlaneRaycastCallback(vehicle, superFunc, nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
    ---@type Boat_spec
    local spec = vehicle[Boat.SPEC_TABLE_NAME]

    spec.pendingWaterRaycast = false

    if vehicle.isDeleted or (vehicle.isDeleting or not vehicle.isAddedToPhysics) then
        return true
    elseif distance > g_boatManager.raycastMaxDistance then
        vehicle:setBoatWaterHeightAndGeofence(0, 0)
        vehicle:setBoatWaterPlaneId(nil)
        return true
    end

    local heightChangeThreshold = 0.1
    local prevHeight = spec.waterPlaneHeight

    vehicle:setBoatWaterHeightAndGeofence(y, g_currentMission.boatWaterSystem:getCurrentGeofenceIndex(x, z))

    -- If waterPlaneHeight == 0 or the terrain height at the position of one of the water
    -- depth nodes are above the waterPlaneHeight, getIsBoatInWater() will return false
    if vehicle:getIsBoatInWater() then
        if nodeId == 0 then
            if isLast then
                vehicle:setBoatWaterPlaneId(nil)
                return
            end
        elseif nodeId == spec.waterPlaneId then
            if math.abs(prevHeight - y) > heightChangeThreshold then
                vehicle:setBoatWaterPlaneId(nil)
                vehicle:setBoatWaterPlaneId(nodeId)
            end
            return true
        else
            if spec.waterPlaneId ~= nil then
                vehicle:setBoatWaterPlaneId(nil)
            end
            vehicle:setBoatWaterPlaneId(nodeId)
            return true
        end
    else
        vehicle:setBoatWaterPlaneId(nil)
        return true
    end
end

--[[
    Make sure that water sound samples starts playing if a waterPlaneId is set, or stop
    playing if there's no waterPlaneId set.
]]
---@param vehicle Boat
---@param superFunc function
---@param nodeId? number
function BoatManager.inj_Boat_setBoatWaterPlaneId(vehicle, superFunc, nodeId)
    ---@type Boat_spec
    local spec = vehicle[Boat.SPEC_TABLE_NAME]

    superFunc(vehicle, nodeId)

    if spec.waterSamples ~= nil then
        if nodeId ~= nil and not spec.waterSamplesArePlaying then
            g_soundManager:playSamples(spec.waterSamples)
            spec.waterSamplesArePlaying = true
        elseif nodeId == nil and spec.waterSamplesArePlaying then
            g_soundManager:stopSamples(spec.waterSamples)
            spec.waterSamplesArePlaying = false
        end
    end
end

---@diagnostic disable-next-line: lowercase-global
g_boatManager = BoatManager.new()

if g_server ~= nil then
    addModEventListener(g_boatManager)
end
