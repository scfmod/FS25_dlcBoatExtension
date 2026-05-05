---@class ModUtils
ModUtils = {}

---@param filepath string
---@return string
---@nodiscard
function ModUtils.getFilename(filepath)
    ---@diagnostic disable-next-line: return-type-mismatch
    return filepath:match("([^/\\]+)$")
end

---@param mass number
---@return string
function ModUtils.formatMass(mass)
    local str = string.format("%.0f", mass * 1000)

    str = str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^%,", "")

    return str .. ' kg'
end
