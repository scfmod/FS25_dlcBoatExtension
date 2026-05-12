--[[
    Specialization to make sure that vehicles (Boat especially) with fillUnits
    set to updateMass="true" updates component mass correctly. When loading from savegame
    it will not always set mass correctly on component node, depending on various known
    and unknown factors.
]]

---@class BoatFillUnitExtension_spec
---@field didUpdateMass boolean

---@class BoatFillUnitExtension : Boat, FillUnit
BoatFillUnitExtension = {}
BoatFillUnitExtension.SPEC_NAME = 'spec_' .. g_currentModName .. '.boatFillUnitExtension'

function BoatFillUnitExtension.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function BoatFillUnitExtension.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onUpdate', BoatFillUnitExtension)
end

---@param dt number
function BoatFillUnitExtension:onUpdate(dt)
    ---@type BoatFillUnitExtension_spec
    local spec = self[BoatFillUnitExtension.SPEC_NAME]

    if not spec.didUpdateMass and self.finishedFirstUpdate and not self.isMassDirty then
        self:setMassDirty()
        spec.didUpdateMass = true
    end
end
