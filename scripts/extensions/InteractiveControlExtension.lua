---@class InteractiveFunctions
---@field addFunction fun(name: string, params: InteractiveFunctionsParams)

---@class InteractiveFunctionsParams
---@field posFunc fun(target: BoatControlExtension, data: any, noEventSend: boolean?)
---@field negFunc? fun(target: BoatControlExtension, data: any, noEventSend: boolean?)
---@field updateFunc? fun(target: BoatControlExtension): boolean?
---@field isBlockedFunc? fun(target: BoatControlExtension): boolean?
---@field loadFunc? fun(xmlFile: XMLFile, key: string, data: table): boolean

---@class InteractiveControlExtension
---@field interactiveFunctions InteractiveFunctions
InteractiveControlExtension = {}

local InteractiveControlExtension_mt = Class(InteractiveControlExtension)

---@return InteractiveControlExtension
---@nodiscard
function InteractiveControlExtension.new()
    ---@type InteractiveControlExtension
    local self = setmetatable({}, InteractiveControlExtension_mt)

    return self
end

function InteractiveControlExtension:onModsLoaded()
    local modName = 'FS25_interactiveControl'

    if g_modIsLoaded[modName] then
        local modEnv = _G[modName]
        self.interactiveFunctions = modEnv['InteractiveFunctions']

        if self.interactiveFunctions ~= nil then
            g_modController:debug('"FS25_interactiveControl" mod is active, adding new functions')

            self:registerFunction('BOAT_CONTROL_GROUP_CHANGE', InteractiveControlExtension.controlGroupChangeFunction)
            self:registerFunction('BOAT_CONTROL_GROUP_SET_INDEX', InteractiveControlExtension.controlGroupSetIndexFunction)
            self:registerFunction('BOAT_CONTROL_GROUP_NEXT', InteractiveControlExtension.controlGroupNextFunction)
            self:registerFunction('BOAT_CONTROL_GROUP_PREV', InteractiveControlExtension.controlGroupPrevFunction)
            self:registerFunction('BOAT_CONTROL_GROUP_RESET', InteractiveControlExtension.controlGroupResetFunction)
        end
    end
end

---@param name any
---@param fn fun(): InteractiveFunctionsParams
function InteractiveControlExtension:registerFunction(name, fn)
    if self.interactiveFunctions.addFunction(name, fn()) then
        g_modController:debug('  Registered interactiveControl function "%s"', name)
    end
end

---@return InteractiveFunctionsParams
---@nodiscard
function InteractiveControlExtension.controlGroupSetIndexFunction()
    ---@type InteractiveFunctionsParams
    return {
        posFunc = function (target, data, noEventSend)
            if noEventSend then
                return
            end

            if target.spec_boatControl ~= nil and data ~= nil and data.index ~= nil then
                BoatControlExtension.setActiveControlGroup(target, data.index)
            end
        end,
        isBlockedFunc = function (target)
            local spec = target.spec_boatControl

            if spec ~= nil then
                return #spec.controlGroups > 0
            end
        end,
        loadFunc = function (xmlFile, key, data)
            data.index = xmlFile:getUInt(key .. '.group#index')

            return data.index ~= nil
        end
    }
end

---@return InteractiveFunctionsParams
---@nodiscard
function InteractiveControlExtension.controlGroupNextFunction()
    ---@type InteractiveFunctionsParams
    return {
        posFunc = function (target, data, noEventSend)
            if noEventSend then
                return
            end

            if target.spec_boatControl ~= nil then
                BoatControlExtension.actionEventControlGroupNext(target)
            end
        end,
        isBlockedFunc = function (target)
            local spec = target.spec_boatControl

            if spec ~= nil then
                return #spec.controlGroups > 0
            end
        end
    }
end

---@return InteractiveFunctionsParams
---@nodiscard
function InteractiveControlExtension.controlGroupPrevFunction()
    ---@type InteractiveFunctionsParams
    return {
        posFunc = function (target, data, noEventSend)
            if noEventSend then
                return
            end

            if target.spec_boatControl ~= nil then
                BoatControlExtension.actionEventControlGroupPrevious(target)
            end
        end,
        isBlockedFunc = function (target)
            local spec = target.spec_boatControl

            if spec ~= nil then
                return #spec.controlGroups > 0
            end
        end
    }
end

---@return InteractiveFunctionsParams
---@nodiscard
function InteractiveControlExtension.controlGroupResetFunction()
    ---@type InteractiveFunctionsParams
    return {
        posFunc = function (target, data, noEventSend)
            if noEventSend then
                return
            end

            if target.spec_boatControl ~= nil then
                BoatControlExtension.actionEventControlGroupReset(target)
            end
        end,
        isBlockedFunc = function (target)
            local spec = target.spec_boatControl

            if spec ~= nil then
                return #spec.controlGroups > 0
            end
        end
    }
end

---@return InteractiveFunctionsParams
---@nodiscard
function InteractiveControlExtension.controlGroupChangeFunction()
    ---@type InteractiveFunctionsParams
    return {
        posFunc = function (target, data, noEventSend)
            if noEventSend then
                return
            end

            if target.spec_boatControl ~= nil then
                BoatControlExtension.actionEventControlGroupNext(target)
            end
        end,
        negFunc = function (target, data, noEventSend)
            if noEventSend then
                return
            end

            if target.spec_boatControl ~= nil then
                BoatControlExtension.actionEventControlGroupPrevious(target)
            end
        end,
        isBlockedFunc = function (target)
            local spec = target.spec_boatControl

            if spec ~= nil then
                return #spec.controlGroups > 0
            end
        end
    }
end

---@diagnostic disable-next-line: lowercase-global
g_interactiveControlExtension = InteractiveControlExtension.new()
