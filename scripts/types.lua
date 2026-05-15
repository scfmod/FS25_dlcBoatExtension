---@meta

---@class VehicleComponent
---@field node number
---@field mass number
---@field defaultMass number
---@field solverIterationCount? number

---@class Boat : Vehicle
---@field SPEC_TABLE_NAME string
---@field spec_shallowWaterObstacles ShallowWaterObstacles_spec
---@field spec_enterable Enterable_spec
---@field updateBoatWaterPlane fun(self: Boat)
---@field onBoatWaterPlaneRaycastCallback fun(self: Boat)
---@field onPlayerTriggerCallback fun(self: Boat)
---@field setBoatWaterPlaneId fun(self: Boat, waterplaneId: number?)
---@field setBoatWaterHeightAndGeofence fun(self: Boat, waterplaneHeight: number?, geofenceId: number?)
---@field getIsBoatInWater fun(self: Boat): boolean
---@field updateBoatControl fun(self: Boat)
---@field onBoatStopCrossLoaded fun(self: Boat)
---@field getBoatPropellerEffectSpeed fun(self: Boat): number
---@field onPreLoad fun(self: Boat)
---@field onLoadFinished fun(self: Boat)
---@field onDelete fun(self: Boat)
---@field onUpdate fun(self: Boat)
---@field getMotorRpmReal fun(self: Boat): number
---@field getMotorRpmPercentage fun(self: Boat): number

---@class Enterable_spec
---@field isEntered boolean

---@class Boat_spec
---@field waterEffectsMinSpeed? number
---@field pendingWaterRaycast boolean
---@field waterPlaneHeight number
---@field lastWaterPlaneHeight? number
---@field keepAwake boolean
---@field waterPlaneId? number
---@field waterSamples? table
---@field waterSamplesArePlaying boolean
---@field jointIndex? number
---@field joint BoatJoint
---@field motorAcceleration number -- [-1, ..., 1]
---@field steeringInput number
---@field maxSteeringAngle number
---@field maxAccelerationSpeed number
---@field steeringForce number
---@field steeringForceAngle number
---@field accelerationForceAngle number
---@field reverseAccelerationFactor number
---@field steeringAccelerationFactor number
---@field accelerationForceCurve AnimCurve
---@field propellerNodes PropellerNode[]
---@field rudderNodes RudderNode[]
---@field propellerForceNodes PropellerForceNode
---@field propellerEffects Effect[]
---@field shallowWaterNodes ShallowWaterNode[]
---@field propellerEffectsActive boolean

---@class RudderNode
---@field node number
---@field maxRotation number

---@class PropellerNode
---@field node number
---@field rotSpeed number
---@field curRot number

---@class PropellerForceNode
---@field node number
---@field lastSpeedReal number

---@class ShallowWaterNode
---@field node number
---@field radius number

---@class ControlGroup
---@field name string
---@field icon string
---@field maxSteeringAngle number
---@field maxAccelerationSpeed number
---@field steeringForce number
---@field steeringForceAngle number
---@field accelerationForceAngle number
---@field reverseAccelerationFactor number
---@field steeringAccelerationFactor number
---@field accelerationForceCurve AnimCurve
---@field propellerNodes PropellerNode[]
---@field propellerForceNodes PropellerForceNode[]
---@field propellerEffects Effect[]
---@field shallowWaterNodes ShallowWaterNode[]
---@field rudderNodes RudderNode[]
---@field changeObjects table[]
---
---@field propellerNodesIndex? number
---@field propellerForceNodesIndex? number
---@field propellerEffectsIndex? number
---@field shallowWaterNodesIndex? number
---@field rudderNodesIndex? number

---@class BoatJoint
---@field waterDepth number
---@field jointPosition number[] -- [x, y, z] offset from component[1] node

---@class ModItem
---@field id number
---@field title string
---@field modName string
---@field modDir string

---@class ObstacleNode
---@field node number
---@field directionNode number
---@field size number[] -- [x, y, z]
---@field offset number[] -- [x, y, z]
---@field vehicle Boat
---@field lastWorldPosition number[] -- [x, y, z]
---@field shallowWaterObstacle? Obstacle
---@field ignoreDirectionZ boolean

---@class Obstacle
---@field node number
---@field sizeX number
---@field sizeZ number
---@field sizeY number
---@field rotY number
---@field offset number[] -- [x, y, z]
---@field getXZVelocityAndRotYFunc function
---@field getXZVelocityAndRotYFuncTarget table

---@class ShallowWaterObstacles_spec
---@field obstacleNodes ObstacleNode[]
