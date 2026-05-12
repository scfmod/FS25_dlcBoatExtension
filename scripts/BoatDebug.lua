---@class BoatDebug
---@field textX number
---@field textY number
---@field textSize number
---@field textHeight number
---@field currentTextY number
---@field enabled boolean
---@field debugBox DebugBox
BoatDebug = {}

local BoatDebug_mt = Class(BoatDebug)

---@return BoatDebug
---@nodiscard
function BoatDebug.new()
    ---@type BoatDebug
    local self = setmetatable({}, BoatDebug_mt)

    self.textX = 0.75
    self.textY = 0.5
    self.textSize = 0.014
    self.textHeight = self.textSize * 1.1
    self.currentTextY = self.textY
    self.enabled = StartParams.getIsSet('boatDebug')

    self.debugBox = DebugBox.new()
    self.debugBox:setDrawFaces(true)

    addConsoleCommand('gsBoatDebug', 'Toggle debugging controlled Boat', 'consoleBoatDebug', self)

    return self
end

function BoatDebug:consoleBoatDebug()
    if self.enabled then
        removeModEventListener(self)
        self.enabled = false
        return 'Boat debug disabled'
    else
        addModEventListener(self)
        self.enabled = true
        return 'Boat debug enabled'
    end
end

---@param str string
---@param ... any
function BoatDebug:drawText(str, ...)
    renderText(self.textX, self.currentTextY, self.textSize, string.format(str, ...))
    self.currentTextY = self.currentTextY - self.textHeight
end

function BoatDebug:draw()
    if g_localPlayer == nil then
        return
    end

    ---@type Boat?
    local vehicle = g_localPlayer:getCurrentVehicle()

    if vehicle == nil then
        return
    end

    self.textX = 0.75
    self.currentTextY = self.textY

    ---@type Boat_spec?
    local spec = vehicle[Boat.SPEC_TABLE_NAME]

    if spec == nil then
        -- self:drawVehicleMassInfo(vehicle)
        return
    end


    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)

    self:drawPhysicsInfo(vehicle, spec)
    self:drawObstacleNodes(vehicle)
    self:drawForceNodes(spec)
end

---@param spec Boat_spec
function BoatDebug:drawForceNodes(spec)
    for _, forceNode in ipairs(spec.propellerForceNodes) do
        self:drawForceNode(forceNode.node, spec)
    end
end

---@param node number
---@param spec Boat_spec
function BoatDebug:drawForceNode(node, spec)
    local radius = 0.25
    local r, g, b = 0.8, 0.9, 1
    local x, y, z = getWorldTranslation(node)

    DebugUtil.drawDebugCircle(x, y, z, 0.015, 8, { r, g, b }, nil, nil, false)
    DebugUtil.drawDebugCircle(x, y, z, radius, 16, { r, g, b }, nil, nil, false)

    local rotY = math.pi + spec.steeringInput * (math.pi * 0.5)
    local lx, lz = math.sin(rotY), math.cos(rotY)
    local dx, _, dz = localDirectionToWorld(node, lx, 0, lz)

    drawDebugLine(x, y, z, r, g, b, x + dx * radius, y, z + dz * radius, r, g, b, false)
end

---@param vehicle Vehicle
function BoatDebug:drawVehicleMassInfo(vehicle)
    ---@type VehicleComponent
    local component = vehicle.components[1]

    local defaultMass = ModUtils.formatMass(component.defaultMass)
    local additionalMass = ModUtils.formatMass(vehicle:getAdditionalComponentMass(component))
    local totalMass = ModUtils.formatMass(component.mass)
    local getMassResult = ModUtils.formatMass(getMass(component.node))

    setTextBold(true)
    self:drawText('Main component')
    setTextBold(false)

    self:drawText('  Default mass: %s', defaultMass)
    self:drawText('  Additional mass: %s', additionalMass)
    self:drawText('  Total mass: %s', totalMass)
    self:drawText('  getMass(component.node): %s', getMassResult)
    self:drawText('  vehicle.serverMass: %s', ModUtils.formatMass(vehicle.serverMass))
end

---@param vehicle Boat
---@param spec Boat_spec
function BoatDebug:drawPhysicsInfo(vehicle, spec)
    ---@type VehicleComponent
    local component = vehicle.components[1]
    local node = component.node
    local x, y, z = getWorldTranslation(node)
    local cx, cy, cz = getCenterOfMass(node)
    local wx, wy, wz = localToWorld(node, cx, cy, cz)
    local jointOffset = spec.joint.jointPosition
    local jx, jy, jz = localToWorld(node, jointOffset[1], jointOffset[2], jointOffset[3])

    DebugUtil.drawDebugCircle(x, y, z, 0.05, 8, { 1, 1, 1 }, nil, nil, false)
    DebugUtil.drawDebugCircle(wx, wy, wz, 0.1, 8, { 0.7, 0.1, 0.1 }, nil, nil, false)
    DebugUtil.drawDebugCircle(jx, jy, jz, 0.2, 8, { 0.1, 0.7, 0.1 }, nil, nil, false)

    local defaultMass = ModUtils.formatMass(component.defaultMass)
    local additionalMass = ModUtils.formatMass(vehicle:getAdditionalComponentMass(component))
    local totalMass = ModUtils.formatMass(component.mass)
    local getMassResult = ModUtils.formatMass(getMass(component.node))

    setTextBold(true)
    self:drawText('Main component')
    setTextBold(false)

    self:drawText('  Default mass: %s', defaultMass)
    self:drawText('  Additional mass: %s', additionalMass)
    self:drawText('  Total mass: %s', totalMass)
    self:drawText('  getMass(component.node): %s', getMassResult)
    self:drawText('  vehicle.serverMass: %s', ModUtils.formatMass(vehicle.serverMass))
    setTextColor(0.9, 0.2, 0.2, 1)
    self:drawText('  Center of mass: %.2f, %.2f, %.2f', cx, cy, cz)
    setTextColor(0.2, 0.9, 0.2, 1)
    self:drawText('  Joint position: %.2f, %.2f, %.2f', jointOffset[1], jointOffset[2], jointOffset[3])

    setTextColor(1, 1, 1, 1)
    if component.solverIterationCount ~= nil then
        self:drawText('  solverIterationCount: %d', component.solverIterationCount)
    end

    self:drawText('')
    self:drawText('waterDepth: %.4f', spec.joint.waterDepth)
    self:drawText('jointIndex: %s', tostring(spec.jointIndex))
end

---@param vehicle Boat
function BoatDebug:drawObstacleNodes(vehicle)
    local spec = vehicle.spec_shallowWaterObstacles

    if spec ~= nil then
        local nodes = spec.obstacleNodes

        for index, obstacleNode in ipairs(nodes) do
            local offsetX, offsetY, offsetZ = obstacleNode.offset[1], obstacleNode.offset[2], obstacleNode.offset[3]
            local sizeX, sizeY, sizeZ = obstacleNode.size[1], obstacleNode.size[2], obstacleNode.size[3]

            self.debugBox:createWithNode(obstacleNode.node, sizeX, sizeY, sizeZ, offsetX, offsetY, offsetZ)
            self.debugBox:setText(string.format('obstacleNode #%d', index))
            self.debugBox:draw()
        end
    end
end

---@diagnostic disable-next-line: lowercase-global
g_boatDebug = BoatDebug.new()
