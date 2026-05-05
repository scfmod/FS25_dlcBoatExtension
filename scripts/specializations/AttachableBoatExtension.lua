---@class AttachableBoatExtension_spec
---@field disableJointAttach boolean

---@class AttachableBoatExtension : Vehicle, Boat, Attachable, Enterable
AttachableBoatExtension = {}
AttachableBoatExtension.SPEC_NAME = 'spec_' .. g_currentModName .. '.attachableBoatExtension'

function AttachableBoatExtension.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Boat, specializations) and SpecializationUtil.hasSpecialization(Attachable, specializations)
end

function AttachableBoatExtension.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onLoad', AttachableBoatExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onPreAttach', AttachableBoatExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onPostAttach', AttachableBoatExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onPostDetach', AttachableBoatExtension)
end

function AttachableBoatExtension.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, 'updateBoatWaterPlane', AttachableBoatExtension.updateBoatWaterPlane)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, 'onBoatWaterPlaneRaycastCallback', AttachableBoatExtension.onBoatWaterPlaneRaycastCallback)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, 'getIsActiveForInput', AttachableBoatExtension.getIsActiveForInput)
end

function AttachableBoatExtension:onLoad()
    ---@type AttachableBoatExtension_spec
    local spec = self[AttachableBoatExtension.SPEC_NAME]

    spec.disableJointAttach = false
end

---@param attacherVehicle Vehicle
---@param inputJointDescIndex number
---@param joinDescIndex number
function AttachableBoatExtension:onPreAttach(attacherVehicle, inputJointDescIndex, joinDescIndex)
    ---@type AttachableBoatExtension_spec
    local spec = self[AttachableBoatExtension.SPEC_NAME]

    spec.disableJointAttach = true

    self:setBoatWaterHeightAndGeofence(0, nil)
    self:setBoatWaterPlaneId(nil)
end

---@param attacherVehicle Vehicle
---@param inputJointDescIndex number
---@param joinDescIndex number
---@param loadFromSavegame boolean
function AttachableBoatExtension:onPostAttach(attacherVehicle, inputJointDescIndex, joinDescIndex, loadFromSavegame)
    local boat_spec = self[Boat.SPEC_TABLE_NAME]

    if boat_spec.jointIndex ~= nil then
        Logging.warning('** AttachableBoatExtension:onPostAttach() vehicle still has an active boat joint attached, should not happen! **')
    end

    Boat.updateBoatWaterPlane(self)
end

function AttachableBoatExtension:onPostDetach()
    ---@type AttachableBoatExtension_spec
    local spec = self[AttachableBoatExtension.SPEC_NAME]

    spec.disableJointAttach = false
end

function AttachableBoatExtension:updateBoatWaterPlane(superFunc)
    ---@type AttachableBoatExtension_spec
    local spec = self[AttachableBoatExtension.SPEC_NAME]

    if not spec.disableJointAttach then
        superFunc(self)
    end
end

function AttachableBoatExtension:onBoatWaterPlaneRaycastCallback(superFunc, ...)
    ---@type AttachableBoatExtension_spec
    local spec = self[AttachableBoatExtension.SPEC_NAME]

    if not spec.disableJointAttach then
        return superFunc(self, ...)
    else
        ---@type Boat_spec
        local boat_spec = self[Boat.SPEC_TABLE_NAME]

        boat_spec.pendingWaterRaycast = false

        return true
    end
end

function AttachableBoatExtension:getIsActiveForInput(superFunc, ignoreSelection, activeForAI)
    ---@type AttachableBoatExtension_spec
    local spec = self[AttachableBoatExtension.SPEC_NAME]

    if spec.disableJointAttach and self.spec_enterable.isEntered then
        return true
    end

    return superFunc(self, ignoreSelection, activeForAI)
end
