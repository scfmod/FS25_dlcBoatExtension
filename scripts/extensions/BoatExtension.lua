--[[
    - inj_Boat_onBoatWaterPlaneRaycastCallback

      Override raycast callback in order to allow lifting boats out of the water if distance to waterplane is too great.
      It raycasts downwards at vehicle root node position with y offset + 25.0 looking for closest waterplane
      Raycast distance is 50.0


    - inj_Boat_onUpdate

      Override waterEffectsMinSpeed in order to prevent water effects (if applicable) when the boat is out of the water


    - inj_Boat_onPreLoad

      Make sure that Boats work on other maps, prevent specialization setting custom position compression parameters.
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

    return superFunc(self, nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end

---@param self Boat
local function inj_Boat_onUpdate(self, superFunc, ...)
    ---@type Boat_spec
    local spec = self[Boat.SPEC_TABLE_NAME]
    local previousWaterEffectsMinSpeed = spec.waterEffectsMinSpeed

    if spec.waterPlaneId == nil then
        spec.waterEffectsMinSpeed = 1000
    end

    superFunc(self, ...)

    spec.waterEffectsMinSpeed = previousWaterEffectsMinSpeed
end

---@param self Boat
---@param superFunc function
local function inj_Boat_onPreLoad(self, superFunc)
    -- void, skip calling superFunc to avoid setting custom vehicle
    -- position compression parameters regardless of map.
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
    ---@type Boat_spec
    local spec = self[Boat.SPEC_TABLE_NAME]

    if node ~= nil and spec.waterPlaneId ~= node then
        if spec.jointIndex ~= nil then
            removeJoint(spec.jointIndex)
            spec.jointIndex = nil
        end
    end

    superFunc(self, node)

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
