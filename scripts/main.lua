local dlcName = 'pdlc_highlandsFishingPack'

---@diagnostic disable-next-line: lowercase-global
g_modName = g_currentModName
---@diagnostic disable-next-line: lowercase-global
g_modDirectory = g_currentModDirectory

if g_modIsLoaded[dlcName] then
    ---@type Boat
    Boat = _G[dlcName].Boat

    source(g_currentModDirectory .. 'scripts/ModUtils.lua')
    source(g_currentModDirectory .. 'scripts/ModController.lua')
    source(g_currentModDirectory .. 'scripts/BoatManager.lua')

    source(g_currentModDirectory .. 'scripts/extensions/InteractiveControlExtension.lua')
    source(g_currentModDirectory .. 'scripts/extensions/ShallowWaterObstaclesExtension.lua')
    source(g_currentModDirectory .. 'scripts/extensions/ShallowWaterSimulationExtension.lua')
    source(g_currentModDirectory .. 'scripts/extensions/XMLFileExtension.lua')

    g_specializationManager:addSpecialization('attachableBoatExtension', 'AttachableBoatExtension', g_currentModDirectory .. 'scripts/specializations/AttachableBoatExtension.lua', g_currentModName)
    g_specializationManager:addSpecialization('boatControlExtension', 'BoatControlExtension', g_currentModDirectory .. 'scripts/specializations/BoatControlExtension.lua', g_currentModName)
    g_specializationManager:addSpecialization('boatFillUnitExtension', 'BoatFillUnitExtension', g_currentModDirectory .. 'scripts/specializations/BoatFillUnitExtension.lua', g_currentModName)

    g_modController:addMissingDlcStoreItems()
    g_modController:addCustomDlcStoreItems()

    source(g_currentModDirectory .. 'scripts/BoatDebug.lua')
else
    Logging.warning('[%s] DLC "%s" is not loaded', g_currentModName, dlcName)
end
