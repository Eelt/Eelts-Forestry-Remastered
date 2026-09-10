if isClient() then return end

require "Map/SGlobalObjectSystem"
require "EeltsForestryRemastered_TreeGrowthObject"

Eelt_STreeGrowthSystem = SGlobalObjectSystem:derive("Eelt_STreeGrowthSystem")

local MODE_STOCK = 1
local MODE_PLANTED_ONLY = 2
local MODE_ALL = 3

local GROWTH_OPTION = "EeltsForestryRemastered.TreeGrowth"
local TIME_OPTION = "EeltsForestryRemastered.TreeGrowthTimeMultiplier"

-- Seven transitions at thirteen in game days each is roughly three months from stage 0 to 7
local BASE_HOURS_PER_STAGE = 312
local SCAN_RADIUS = 30

function Eelt_STreeGrowthSystem:new()
    return SGlobalObjectSystem.new(self, "Eelt_TreeGrowth")
end

function Eelt_STreeGrowthSystem:initSystem()
    SGlobalObjectSystem.initSystem(self)
    self.system:setModDataKeys({})
    self.system:setObjectModDataKeys({ 'tileset', 'stage', 'enteredHour', 'planted', 'overlaySeason' })
end

function Eelt_STreeGrowthSystem:newLuaObject(globalObject)
    return Eelt_STreeGrowthObject:new(self, globalObject)
end

function Eelt_STreeGrowthSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoTree")
        and isoObject:getName() == EeltsForestryRemastered_TreeGrowthSprites.ADOPTED_NAME
end

function Eelt_STreeGrowthSystem:getMode()
    local option = getSandboxOptions():getOptionByName(GROWTH_OPTION)
    local value = option and option:getValue()
    return value or MODE_ALL
end

function Eelt_STreeGrowthSystem:getHoursPerStage()
    local option = getSandboxOptions():getOptionByName(TIME_OPTION)
    local multiplier = option and option:getValue() or 1.0
    if multiplier <= 0 then multiplier = 1.0 end
    return BASE_HOURS_PER_STAGE * multiplier
end

function Eelt_STreeGrowthSystem:mayAdoptWildTrees()
    return self:getMode() == MODE_ALL
end

function Eelt_STreeGrowthSystem:mayGrow(luaObject)
    local mode = self:getMode()
    if mode == MODE_ALL then return true end
    if mode == MODE_PLANTED_ONLY then return luaObject.planted == true end
    return false
end

function Eelt_STreeGrowthSystem:adoptTree(square, tree)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    if tree:getName() == sprites.ADOPTED_NAME then return end

    local sprite = tree:getSprite()
    local tileset, stage = sprites.identify(sprite and sprite:getName())
    if not tileset or stage >= sprites.MAX_STAGE then return end
    if self:getLuaObjectOnSquare(square) then return end

    tree:setName(sprites.ADOPTED_NAME)

    local luaObject = self:newLuaObjectOnSquare(square)
    luaObject:adoptFrom(tree, tileset, stage, false)
    luaObject:stateToIsoObject(tree)
end

-- Planting adopts on the spot; adoptNearPlayers only runs under the all trees setting,
-- which is the one setting a planted tree does not need
function Eelt_STreeGrowthSystem:adoptPlantedTree(square, tree, tileset)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    if not sprites.getBase(tileset, 0) then return nil end
    if self:getLuaObjectOnSquare(square) then return nil end

    tree:setName(sprites.ADOPTED_NAME)

    local luaObject = self:newLuaObjectOnSquare(square)
    luaObject:adoptFrom(tree, tileset, 0, true)
    luaObject:stateToIsoObject(tree)
    return luaObject
end

-- SGlobalObjectSystem:OnChunkLoaded only fires for chunks this system already owns,
-- and no lua event sees a tree being placed, so adoption rides the hourly tick
function Eelt_STreeGrowthSystem:adoptNearPlayers()
    if not self:mayAdoptWildTrees() then return end

    local cell = getCell()
    if not cell then return end

    local online = getOnlinePlayers()
    local lastPlayer = isServer() and online:size() - 1 or getNumActivePlayers() - 1
    for i = 0, lastPlayer do
        local player = isServer() and online:get(i) or getSpecificPlayer(i)
        if player then
            local px = math.floor(player:getX())
            local py = math.floor(player:getY())
            local pz = math.floor(player:getZ())
            for x = px - SCAN_RADIUS, px + SCAN_RADIUS do
                for y = py - SCAN_RADIUS, py + SCAN_RADIUS do
                    local square = cell:getGridSquare(x, y, pz)
                    local tree = square and square:getTree()
                    if tree then self:adoptTree(square, tree) end
                end
            end
        end
    end
end

function Eelt_STreeGrowthSystem:updateAdoptedTrees()
    local hoursPerStage = self:getHoursPerStage()
    for i = 1, self.system:getObjectCount() do
        local luaObject = self.system:getObjectByIndex(i - 1):getModData()
        if self:mayGrow(luaObject) and luaObject:isReadyToGrow(hoursPerStage) then
            luaObject:grow()
        else
            luaObject:refreshOverlay()
        end
    end
end

-- Season changes are driven by the hourly tick; the debug menu calls this to force one
function Eelt_STreeGrowthSystem:refreshAllOverlays()
    for i = 1, self.system:getObjectCount() do
        self.system:getObjectByIndex(i - 1):getModData():refreshOverlay()
    end
end

function Eelt_STreeGrowthSystem.everyHour()
    local instance = Eelt_STreeGrowthSystem.instance
    if not instance then return end
    if instance:getMode() == MODE_STOCK then return end
    instance:updateAdoptedTrees()
    instance:adoptNearPlayers()
end

SGlobalObjectSystem.RegisterSystemClass(Eelt_STreeGrowthSystem)

Events.EveryHours.Add(Eelt_STreeGrowthSystem.everyHour)
