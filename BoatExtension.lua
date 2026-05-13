--[[
    - inj_Boat_onBoatWaterPlaneRaycastCallback

      Override raycast callback in order to allow lifting boats out of the water if distance to waterplane is too great.
      It raycasts downwards at vehicle root node position with y offset + 25.0 looking for closest waterplane.
      Raycast distance is 50.0.

      Also handles animated water planes (e.g. lock/dam systems): when the water plane node moves but
      keeps the same node ID, the original code skips joint recreation. We detect the height change and
      force the physics joint to be rebuilt at the new water surface level so the joint spring pulls the
      boat to the new height. This covers boats that are active (player aboard or boat already moving).


    - inj_Boat_onUpdate

      Override waterEffectsMinSpeed in order to prevent water effects (if applicable) when the boat is out of the water.


    - inj_Boat_onPreLoad

      Make sure that Boats work on other maps, prevent specialization setting custom position compression parameters.


    - inj_Mission00_update

      Handles the case where a stationary, unoccupied boat needs to follow an animated water plane.
      When a boat is sleeping (stationary and unoccupied) its physics body is inactive, so onUpdateTick
      and its raycasts stop firing and the boat no longer tracks the water surface.

      Each frame we read the water plane node's world Y directly and compare it to the previous frame.
      When the water is moving we call setSleepingThresholds(0, 0) to disable physics sleeping on the
      boat body (waking it if already asleep) and raiseActive() to keep it in the script update loop.
      This lets the existing onUpdateTick raycasts and joint spring move the boat naturally and smoothly.
      When the water settles we restore the normal sleep thresholds (0.3 / 0.35) so the boat can sleep
      again. Server only — clients follow via normal vehicle position sync.
]]

---@param self Boat
local function inj_Boat_onBoatWaterPlaneRaycastCallback(self, superFunc, nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
    ---@type Boat_spec
    local spec = self[Boat.SPEC_TABLE_NAME]

    spec.pendingWaterRaycast = false

    if self.isDeleted or (self.isDeleting or not self.isAddedToPhysics) then
        return true
    elseif distance > 25 then
        self:setBoatWaterHeightAndGeofence(0, nil)
        self:setBoatWaterPlaneId(nil)
        return true
    end

    local prevHeight = spec.waterPlaneHeight

    superFunc(self, nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)

    -- When the water plane node is animated (e.g. a lock/dam raising/lowering water),
    -- the raycast hits the same nodeId at a new Y position. The original code only calls
    -- setBoatWaterPlaneId when the node changes, so the physics joint is never updated.
    -- Detect the height change here and force a joint rebuild at the new water surface.
    -- The body is awake (raycasts only run for active vehicles) so just rebuilding the
    -- joint is enough; the spring will pull the boat to the new height.
    if spec.waterPlaneId ~= nil and math.abs(prevHeight - spec.waterPlaneHeight) > 0.1 then
        local planeId = spec.waterPlaneId
        self:setBoatWaterPlaneId(nil)
        self:setBoatWaterPlaneId(planeId)
    end
end

---@param self Boat
local function inj_Boat_onUpdate(self, superFunc, dt, ...)
    ---@type Boat_spec
    local spec = self[Boat.SPEC_TABLE_NAME]
    local previousWaterEffectsMinSpeed = spec.waterEffectsMinSpeed

    if spec.waterPlaneId == nil then
        spec.waterEffectsMinSpeed = 1000
    end

    superFunc(self, dt, ...)

    spec.waterEffectsMinSpeed = previousWaterEffectsMinSpeed
end

---@param self Boat
---@param superFunc function
local function inj_Boat_onPreLoad(self, superFunc)
    if g_mpLoadingScreen.missionInfo.mapId == 'pdlc_highlandsFishingPack.HighlandsFishingMap' then
        superFunc(self)
    end
end

---@param self any
---@param superFunc any
local function inj_Boat_onLoadFinished(self, superFunc)
    ---@type Boat_spec
    local spec = self[Boat.SPEC_TABLE_NAME]

    superFunc(self)

    if spec.waterSamples ~= nil then
        g_soundManager:stopSamples(spec.waterSamples)
        spec.waterSamplesArePlaying = false
    end
end

local function inj_Boat_setBoatWaterPlaneId(self, superFunc, node)
    superFunc(self, node)

    ---@type Boat_spec
    local spec = self[Boat.SPEC_TABLE_NAME]

    if spec.waterPlaneId ~= nil then
        if spec.waterSamples ~= nil and not spec.waterSamplesArePlaying then
            g_soundManager:playSamples(spec.waterSamples)
            spec.waterSamplesArePlaying = true
        end
    else
        if spec.waterSamples ~= nil and spec.waterSamplesArePlaying then
            g_soundManager:stopSamples(spec.waterSamples)
            spec.waterSamplesArePlaying = false
        end
    end
end

-- ---@param self Boat
-- ---@param superFunc function
-- local function inj_Boat_getCanBeAddedToSales(self, superFunc)
--     return true
-- end

Boat.onBoatWaterPlaneRaycastCallback = Utils.overwrittenFunction(Boat.onBoatWaterPlaneRaycastCallback, inj_Boat_onBoatWaterPlaneRaycastCallback)
Boat.onUpdate = Utils.overwrittenFunction(Boat.onUpdate, inj_Boat_onUpdate)
Boat.onPreLoad = Utils.overwrittenFunction(Boat.onPreLoad, inj_Boat_onPreLoad)
Boat.onLoadFinished = Utils.overwrittenFunction(Boat.onLoadFinished, inj_Boat_onLoadFinished)
Boat.setBoatWaterPlaneId = Utils.overwrittenFunction(Boat.setBoatWaterPlaneId, inj_Boat_setBoatWaterPlaneId)
-- Boat.getCanBeAddedToSales = Utils.overwrittenFunction(Boat.getCanBeAddedToSales, inj_Boat_getCanBeAddedToSales)

-- [min .. max] RPM from XML
g_soundManager:registerModifierType("BOAT_MOTOR_RPM", Boat.getMotorRpmReal)

-- [0 .. 1] acceleration (absolute, in either direction)
g_soundManager:registerModifierType("BOAT_ACCELERATION", Boat.getMotorRpmPercentage)

-- Per-vehicle state for the animated water plane tracker below.
local _boatLastWaterY = {}  -- water plane node Y from the previous frame
local _boatKeepAwake = {}   -- true while sleep thresholds are overridden for this vehicle

---@param self Mission00
---@param dt number
local function inj_Mission00_update(self, dt)
    if g_server == nil then
        return
    end

    local vs = g_currentMission and g_currentMission.vehicleSystem
    local vehicles = vs and vs.vehicles
    if vehicles == nil then
        return
    end

    for _, vehicle in ipairs(vehicles) do
        local spec = vehicle[Boat.SPEC_TABLE_NAME]

        if spec ~= nil and spec.waterPlaneId ~= nil then
            local _, nodeY, _ = getWorldTranslation(spec.waterPlaneId)
            local lastY = _boatLastWaterY[vehicle]
            _boatLastWaterY[vehicle] = nodeY

            if lastY ~= nil then
                local waterDelta = nodeY - lastY

                if math.abs(waterDelta) > 0.005 then
                    -- Water is moving: disable physics sleeping so the body stays awake,
                    -- then keep the vehicle in the update loop so raycasts keep firing.
                    -- The existing joint spring moves the boat smoothly to the new height.
                    if not _boatKeepAwake[vehicle] then
                        setSleepingThresholds(vehicle.rootNode, 0, 0)
                        _boatKeepAwake[vehicle] = true
                    end
                    vehicle:raiseActive()

                elseif _boatKeepAwake[vehicle] then
                    -- Water has settled: restore the thresholds set in Boat.addToPhysics.
                    setSleepingThresholds(vehicle.rootNode, 0.3, 0.35)
                    _boatKeepAwake[vehicle] = false
                end
            end

        elseif spec ~= nil then
            -- waterPlaneId is nil (boat left water or not yet initialised).
            _boatLastWaterY[vehicle] = nil
            if _boatKeepAwake[vehicle] then
                setSleepingThresholds(vehicle.rootNode, 0.3, 0.35)
                _boatKeepAwake[vehicle] = false
            end
        end
    end
end

Mission00.update = Utils.appendedFunction(Mission00.update, inj_Mission00_update)
