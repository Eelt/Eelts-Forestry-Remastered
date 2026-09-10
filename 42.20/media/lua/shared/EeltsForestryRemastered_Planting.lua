require "EeltsForestryRemastered_Propagules"

EeltsForestryRemastered_Planting = {}

local planting = EeltsForestryRemastered_Planting

planting.MODULE = "EeltsForestryRemastered"
planting.PLANT_COMMAND = "plantTree"
planting.TAPE_OPTION = "EeltsForestryRemastered.RequireTreePlantingTape"
planting.KNOWN_KEY = "Eelt_KnowsTreePlanting"

-- Vanilla's own furrow test. Anything under blends_natural or exterior natural ground is
-- dirt, minus the gravel, sand and clay sprites it names, which are dug but never plowed
local function isDiggableGround(square)
    return ISShovelGroundCursor.GetDirtGravelSand(square) == "dirt"
end

local function hasCrop(square)
    local system = (CFarmingSystem and CFarmingSystem.instance)
        or (SFarmingSystem and SFarmingSystem.instance)
    return system ~= nil and system:getLuaObjectOnSquare(square) ~= nil
end

local function isOverWater(square)
    local floor = square:getFloor()
    local sprite = floor and floor:getSprite()
    return sprite ~= nil and sprite:getProperties():has(IsoFlagType.water)
end

function planting.isPlantableSquare(square)
    if not square then return false end
    if square:getZ() ~= 0 then return false end
    if not square:isOutside() then return false end
    if square:getBuilding() then return false end
    if square:HasTree() then return false end
    if not square:isFree(false) then return false end
    if isOverWater(square) or hasCrop(square) then return false end
    return isDiggableGround(square)
end

function planting.speciesName(tileset)
    return getText("IGUI_Eelt_Species_" .. tileset)
end


function planting.isTapeRequired()
    local option = getSandboxOptions():getOptionByName(planting.TAPE_OPTION)
    return option == nil or option:getValue() ~= false
end

function planting.knowsPlanting(player)
    if not planting.isTapeRequired() then return true end
    local modData = player and player:getModData()
    return modData ~= nil and modData[planting.KNOWN_KEY] == true
end

-- A poisoned berry is a foraged one, and the seed route is the berry a chopped Holly drops.
-- getPoisonPower only exists on Food, so the type check is not optional
function planting.isPlantableItem(item)
    local propagules = EeltsForestryRemastered_Propagules
    if not propagules.isPlantable(item) then return false end
    if instanceof(item, "Food") and item:getPoisonPower() > 0 then return false end
    return true
end
