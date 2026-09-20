if isClient() then return end

require "Map/SGlobalObjectSystem"
require "EeltsForestryRemastered_TreeGrowthObject"

Eelt_STreeGrowthSystem = SGlobalObjectSystem:derive("Eelt_STreeGrowthSystem")

local MODE_STOCK = 1
local MODE_PLANTED_ONLY = 2
local MODE_ALL = 3

local GROWTH_OPTION = "EeltsForestryRemastered.TreeGrowth"
local TIME_OPTION = "EeltsForestryRemastered.TreeGrowthTimeMultiplier"
local TIMING_OPTION = "EeltsForestryRemastered.TreeGrowthTiming"

local TIMING_ON_ARRIVAL = 1

-- What the arrival catch-up has cost so far, for the debug menu. Chunk loads come in bursts,
-- so the worst single chunk matters more than the average
local chunks, caughtUp, grown, totalMs, worstMs = 0, 0, 0, 0, 0

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
    if mode == MODE_STOCK then return false end
    if mode == MODE_PLANTED_ONLY then return luaObject.planted == true end
    return mode == MODE_ALL
end

-- Renaming is what makes vanilla erosion relinquish the square, so it happens here and
-- nowhere else
local function adopt(system, square, tree, tileset, stage, planted)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    if not sprites.getBase(tileset, stage) then return nil end
    if system:getLuaObjectOnSquare(square) then return nil end

    tree:setName(sprites.ADOPTED_NAME)

    local luaObject = system:newLuaObjectOnSquare(square)
    luaObject:adoptFrom(tree, tileset, stage, planted)
    luaObject:stateToIsoObject(tree)
    return luaObject
end

function Eelt_STreeGrowthSystem:adoptTree(square, tree)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    if tree:getName() == sprites.ADOPTED_NAME then return end

    local sprite = tree:getSprite()
    local tileset, stage = sprites.identify(sprite and sprite:getName())
    if not tileset or stage >= sprites.MAX_STAGE then return end

    adopt(self, square, tree, tileset, stage, false)
end

-- Planting adopts on the spot; adoptNearPlayers only runs under the all trees setting,
-- which is the one setting a planted tree does not need
function Eelt_STreeGrowthSystem:adoptPlantedTree(square, tree, tileset)
    return adopt(self, square, tree, tileset, 0, true)
end

-- Correction owns the square whatever size the tree is, so this one carries no stage ceiling
function Eelt_STreeGrowthSystem:adoptCorrectedTree(square, tree, tileset, stage)
    return adopt(self, square, tree, tileset, stage, false)
end

-- Natural establishment has no item and no planter, so it builds the tree itself and then
-- takes it exactly as planting does, minus the planted flag
function Eelt_STreeGrowthSystem:adoptEstablishedTree(square, tileset)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local spriteName = sprites.getBase(tileset, 0)
    local sprite = spriteName and getSprite(spriteName)
    if not sprite then return nil end

    local tree = IsoTree.new(square, sprite)
    square:AddTileObject(tree)
    if isServer() then tree:transmitCompleteItemToClients() end
    triggerEvent("OnObjectAdded", tree)

    local luaObject = adopt(self, square, tree, tileset, 0, false)
    square:RecalcAllWithNeighbours(true)
    return luaObject
end

function Eelt_STreeGrowthSystem:catchesUpOnArrival()
    local option = getSandboxOptions():getOptionByName(TIMING_OPTION)
    local value = option and option:getValue()
    return (value or TIMING_ON_ARRIVAL) == TIMING_ON_ARRIVAL
end

-- Useless for discovery, since it reports only what this system already owns, which is exactly
-- the set that needs bringing up to date. The base body recycles its own list, so take another
function Eelt_STreeGrowthSystem:OnChunkLoaded(wx, wy)
    SGlobalObjectSystem.OnChunkLoaded(self, wx, wy)
    if not self:catchesUpOnArrival() then return end

    local started = getTimestampMs()
    local hoursPerStage = self:getHoursPerStage()
    local season, progress, staggered = Eelt_STreeGrowthObject.currentSeason()
    local globalObjects = self.system:getObjectsInChunk(wx, wy)
    local trees = globalObjects:size()
    for i = 1, trees do
        local luaObject = globalObjects:get(i - 1):getModData()
        if luaObject then
            if self:mayGrow(luaObject) and luaObject:catchUp(hoursPerStage) > 0 then
                grown = grown + 1
            end
            luaObject:refreshOverlay(season, progress, staggered)
        end
    end
    self.system:finishedWithList(globalObjects)

    local elapsed = getTimestampMs() - started
    chunks = chunks + 1
    caughtUp = caughtUp + trees
    totalMs = totalMs + elapsed
    if elapsed > worstMs then worstMs = elapsed end
end

function Eelt_STreeGrowthSystem.arrivalReport()
    print(string.format("Eelt's Forestry Remastered: arrival catch-up: %d chunks, %d trees looked at, %d grown, %d ms total, worst chunk %d ms",
        chunks, caughtUp, grown, totalMs, worstMs))
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
    local season, progress, staggered = Eelt_STreeGrowthObject.currentSeason()
    for i = 1, self.system:getObjectCount() do
        local luaObject = self.system:getObjectByIndex(i - 1):getModData()
        if self:mayGrow(luaObject) and luaObject:isReadyToGrow(hoursPerStage) then
            luaObject:grow()
        else
            luaObject:refreshOverlay(season, progress, staggered)
        end
    end
end

-- Season changes are driven by the hourly tick; the debug menu calls this to force one
function Eelt_STreeGrowthSystem:refreshAllOverlays()
    local season, progress, staggered = Eelt_STreeGrowthObject.currentSeason()
    for i = 1, self.system:getObjectCount() do
        self.system:getObjectByIndex(i - 1):getModData():refreshOverlay(season, progress, staggered)
    end
end

function Eelt_STreeGrowthSystem.everyHour()
    local instance = Eelt_STreeGrowthSystem.instance
    if not instance then return end
    instance:updateAdoptedTrees()
    instance:adoptNearPlayers()

    -- Chunk load catches a square arriving; this catches one a player is already standing on
    local succession = EeltsForestryRemastered_Succession
    if succession then succession.sweepNearPlayers() end
end

SGlobalObjectSystem.RegisterSystemClass(Eelt_STreeGrowthSystem)

Events.EveryHours.Add(Eelt_STreeGrowthSystem.everyHour)
