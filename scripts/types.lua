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
---@field onUpdate fun(self: Boat)
---@field getMotorRpmReal fun(self: Boat): number
---@field getMotorRpmPercentage fun(self: Boat): number

---@class Enterable_spec
---@field isEntered boolean

---@class Boat_spec
---@field waterEffectsMinSpeed? number
---@field pendingWaterRaycast boolean
---@field waterPlaneId? number
---@field waterSamples? table
---@field waterSamplesArePlaying boolean
---@field jointIndex? number
---@field joint BoatJoint
---@field propellerForceNodes ForceNode[]
---@field accelerationForceCurve? AnimCurve
---@field motorAcceleration number -- [-1, ..., 1]
---@field steeringAccelerationFactor number
---@field reverseAccelerationFactor number
---@field steeringInput number

---@class BoatJoint
---@field waterDepth number
---@field jointPosition number[] -- [x, y, z] offset from component[1] node

---@class ForceNode
---@field node number
---@field lastSpeedReal number

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

---@class ShallowWaterObstacles_spec
---@field obstacleNodes ObstacleNode[]
