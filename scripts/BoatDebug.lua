---@class BoatDebug
---@field textX number
---@field textY number
---@field textSize number
---@field textHeight number
---@field currentTextY number
---@field enabled boolean
BoatDebug = {}

BoatDebug.OBSTACLE_LINE_COLOR = { 1, 1, 1 }

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

    ---@type Boat_spec?
    local spec = vehicle[Boat.SPEC_TABLE_NAME]

    if spec == nil then
        return
    end

    self.currentTextY = self.textY

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)

    self:drawPhysicsInfo(vehicle, spec)
    self:drawObstacleNodes(vehicle)
    self:drawForceNodes(vehicle, spec)
end

---@param vehicle Boat
---@param spec Boat_spec
function BoatDebug:drawForceNodes(vehicle, spec)
    for _, forceNode in ipairs(spec.propellerForceNodes) do
        self:drawForceNode(forceNode.node, vehicle, spec)
    end
end

---@param node number
---@param vehicle Boat
---@param spec Boat_spec
function BoatDebug:drawForceNode(node, vehicle, spec)
    local radius = 0.25
    local r, g, b = 0.8, 0.9, 1
    local wx, wy, wz = getWorldTranslation(node)

    local steeringInput = spec.steeringInput
    local motorAcceleration = spec.motorAcceleration

    DebugUtil.drawDebugCircle(wx, wy, wz, 0.015, 8, { r, g, b }, nil, nil, false)

    motorAcceleration = motorAcceleration * radius

    local steeringAngle = -steeringInput * (math.pi * 0.5)

    local lx = math.sin(steeringAngle) * motorAcceleration
    local lz = -math.cos(steeringAngle) * motorAcceleration

    local dx, _, dz = localDirectionToWorld(vehicle.rootNode, lx, 0, lz)

    local ex = wx + dx
    local ey = wy
    local ez = wz + dz

    DebugUtil.drawDebugCircle(wx, wy, wz, radius, 16, { r, g, b }, nil, nil, false)

    drawDebugLine(wx, wy, wz, r, g, b, ex, ey, ez, r, g, b, false)
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

    setTextBold(true)
    self:drawText('Main component')
    setTextBold(false)
    self.textX = self.textX + 0.005
    self:drawText('Default mass: %s', defaultMass)
    self:drawText('Additional mass: %s', additionalMass)
    self:drawText('Total mass: %s', totalMass)
    setTextColor(0.9, 0.2, 0.2, 1)
    self:drawText('Center of mass: %.2f, %.2f, %.2f', cx, cy, cz)
    setTextColor(0.2, 0.9, 0.2, 1)
    self:drawText('Joint position: %.2f, %.2f, %.2f', jointOffset[1], jointOffset[2], jointOffset[3])

    setTextColor(1, 1, 1, 1)
    if component.solverIterationCount ~= nil then
        self:drawText('solverIterationCount: %d', component.solverIterationCount)
    end

    self.textX = self.textX - 0.005

    self:drawText('')
    self:drawText('waterDepth: %.4f', spec.joint.waterDepth)

    -- local rigidBodyType = getRigidBodyType(node)

    -- if rigidBodyType == RigidBodyType.STATIC then
    --     self:drawText('rigidBodyType: STATIC')
    -- elseif rigidBodyType == RigidBodyType.KINEMATIC then
    --     self:drawText('rigidBodyType: KINEMATIC')
    -- elseif rigidBodyType == RigidBodyType.DYNAMIC then
    --     self:drawText('rigidBodyType: DYNAMIC')
    -- end

    self:drawText('jointIndex: %s', tostring(spec.jointIndex))
end

---@param vehicle Boat
function BoatDebug:drawObstacleNodes(vehicle)
    local spec = vehicle.spec_shallowWaterObstacles

    local function drawLine(x1, y1, z1, x2, y2, z2)
        local color = BoatDebug.OBSTACLE_LINE_COLOR
        drawDebugLine(x1, y1, z1, color[1], color[2], color[3], x2, y2, z2, color[1], color[2], color[3], false)
    end

    if spec ~= nil then
        local nodes = spec.obstacleNodes

        for _, obstacleNode in ipairs(nodes) do
            local ox, oy, oz = obstacleNode.offset[1], obstacleNode.offset[2], obstacleNode.offset[3]
            local sx, sy, sz = obstacleNode.size[1], obstacleNode.size[2], obstacleNode.size[3]

            local cx, cy, cz = localToWorld(obstacleNode.node, ox, oy, oz)

            local lx, ly, lz = localDirectionToWorld(obstacleNode.directionNode, 1, 0, 0)
            local ux, uy, uz = localDirectionToWorld(obstacleNode.directionNode, 0, 1, 0)
            local fx, fy, fz = localDirectionToWorld(obstacleNode.directionNode, 0, 0, 1)

            local hx = sx * 0.5
            local hy = sy * 0.5
            local hz = sz * 0.5

            local function corner(ax, ay, az)
                return cx + lx * ax + ux * ay + fx * az,
                    cy + ly * ax + uy * ay + fy * az,
                    cz + lz * ax + uz * ay + fz * az
            end

            local p1x, p1y, p1z = corner(hx, hy, hz)
            local p2x, p2y, p2z = corner(-hx, hy, hz)
            local p3x, p3y, p3z = corner(-hx, -hy, hz)
            local p4x, p4y, p4z = corner(hx, -hy, hz)

            local p5x, p5y, p5z = corner(hx, hy, -hz)
            local p6x, p6y, p6z = corner(-hx, hy, -hz)
            local p7x, p7y, p7z = corner(-hx, -hy, -hz)
            local p8x, p8y, p8z = corner(hx, -hy, -hz)

            drawLine(p1x, p1y, p1z, p2x, p2y, p2z)
            drawLine(p2x, p2y, p2z, p3x, p3y, p3z)
            drawLine(p3x, p3y, p3z, p4x, p4y, p4z)
            drawLine(p4x, p4y, p4z, p1x, p1y, p1z)

            drawLine(p5x, p5y, p5z, p6x, p6y, p6z)
            drawLine(p6x, p6y, p6z, p7x, p7y, p7z)
            drawLine(p7x, p7y, p7z, p8x, p8y, p8z)
            drawLine(p8x, p8y, p8z, p5x, p5y, p5z)

            drawLine(p1x, p1y, p1z, p5x, p5y, p5z)
            drawLine(p2x, p2y, p2z, p6x, p6y, p6z)
            drawLine(p3x, p3y, p3z, p7x, p7y, p7z)
            drawLine(p4x, p4y, p4z, p8x, p8y, p8z)
        end
    end
end

---@diagnostic disable-next-line: lowercase-global
g_boatDebug = BoatDebug.new()
