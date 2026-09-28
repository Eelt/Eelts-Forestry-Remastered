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

-- Adopted trees in loaded ground, keyed by position. Never saved; chunk loads refill it
local loadedTrees = {}

local function track(luaObject)
    if luaObject then loadedTrees[luaObject.x .. "," .. luaObject.y .. "," .. luaObject.z] = luaObject end
end

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
    track(luaObject)
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

-- A renamed tree whose record was lost belongs to nothing; its planted flag and clock went with it
function Eelt_STreeGrowthSystem:reclaimTree(square, tree)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local sprite = tree:getSprite()
    local tileset, stage = sprites.identify(sprite and sprite:getName())
    if not tileset then return nil end
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
-- Records the base chunk check drops for want of a tree, which is one way a tree loses its record
local inChunkCheck = false
local droppedAtLoad = 0

function Eelt_STreeGrowthSystem:removeLuaObject(luaObject)
    if inChunkCheck and luaObject then
        droppedAtLoad = droppedAtLoad + 1
        if droppedAtLoad <= 5 then
            print(string.format("Eelt's Forestry Remastered: chunk check dropped the record at %s,%s,%s",
                tostring(luaObject.x), tostring(luaObject.y), tostring(luaObject.z)))
        end
    end
    return SGlobalObjectSystem.removeLuaObject(self, luaObject)
end

function Eelt_STreeGrowthSystem.droppedAtLoad()
    return droppedAtLoad
end

function Eelt_STreeGrowthSystem:OnChunkLoaded(wx, wy)
    inChunkCheck = true
    local ok, err = pcall(SGlobalObjectSystem.OnChunkLoaded, self, wx, wy)
    inChunkCheck = false
    if not ok then error(err) end

    local globalObjects = self.system:getObjectsInChunk(wx, wy)
    local trees = globalObjects:size()
    for i = 1, trees do track(globalObjects:get(i - 1):getModData()) end

    if not self:catchesUpOnArrival() then
        self.system:finishedWithList(globalObjects)
        return
    end

    local started = getTimestampMs()
    local hoursPerStage = self:getHoursPerStage()
    local season, progress, staggered = Eelt_STreeGrowthObject.currentSeason()
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

-- A copy, so dropping stale entries never changes the table while it is being walked
local function loadedTreeKeys()
    local keys = {}
    for key in pairs(loadedTrees) do keys[#keys + 1] = key end
    return keys
end

-- Nil when the tree has unloaded or is no longer this system's record, which also drops it
local function loadedTree(system, key)
    local luaObject = loadedTrees[key]
    if luaObject and getCell():getGridSquare(luaObject.x, luaObject.y, luaObject.z)
            and system:getLuaObjectAt(luaObject.x, luaObject.y, luaObject.z) == luaObject then
        return luaObject
    end
    loadedTrees[key] = nil
    return nil
end

local function updateTree(system, luaObject, hoursPerStage, season, progress, staggered)
    if system:mayGrow(luaObject) and luaObject:isReadyToGrow(hoursPerStage) then
        luaObject:grow()
    else
        luaObject:refreshOverlay(season, progress, staggered)
    end
end

-- An unloaded tree is caught up when its chunk loads, or under the older timing waits for it
function Eelt_STreeGrowthSystem:updateAdoptedTrees()
    local hoursPerStage = self:getHoursPerStage()
    local season, progress, staggered = Eelt_STreeGrowthObject.currentSeason()
    for _, key in ipairs(loadedTreeKeys()) do
        local luaObject = loadedTree(self, key)
        if luaObject then updateTree(self, luaObject, hoursPerStage, season, progress, staggered) end
    end
end

-- Season changes are driven by the hourly tick; the debug menu calls this to force one
function Eelt_STreeGrowthSystem:refreshAllOverlays()
    local season, progress, staggered = Eelt_STreeGrowthObject.currentSeason()
    for _, key in ipairs(loadedTreeKeys()) do
        local luaObject = loadedTree(self, key)
        if luaObject then luaObject:refreshOverlay(season, progress, staggered) end
    end

    local succession = EeltsForestryRemastered_Succession
    if succession then succession.refreshBushes() end
end

-- The hourly job

local PREFIX = "Eelt's Forestry Remastered: "
local BUDGET_MS = 2

Eelt_STreeGrowthSystem.reportJobs = false

local job = nil
local seeded = false

local function playerPositions()
    local positions = {}
    local online = getOnlinePlayers()
    local lastPlayer = isServer() and online:size() - 1 or getNumActivePlayers() - 1
    for i = 0, lastPlayer do
        local player = isServer() and online:get(i) or getSpecificPlayer(i)
        if player then
            positions[#positions + 1] = { math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()) }
        end
    end
    return positions
end

local function columnsAround(positions, radius, groundOnly)
    local columns = {}
    for _, p in ipairs(positions) do
        if not groundOnly or p[3] == 0 then
            for x = p[1] - radius, p[1] + radius do columns[#columns + 1] = { x, p[2], p[3] } end
        end
    end
    return columns
end

-- Each phase counts its items when it begins and handles one per step, in today's order.
-- Settings, season and player positions are read here once, as one pass read them before
local function buildJob(system)
    local cell = getCell()
    if not cell then return nil end

    local hoursPerStage = system:getHoursPerStage()
    local season, progress, staggered = Eelt_STreeGrowthObject.currentSeason()
    local positions = playerPositions()
    local succession = EeltsForestryRemastered_Succession
    if succession then succession.refresh() end
    local phases = {}

    -- Covers a starting area whose chunks loaded before anything reported them
    if not seeded then
        seeded = true
        phases[#phases + 1] = { name = "seed", checkEvery = 64,
            begin = function() return system.system:getObjectCount() end,
            step = function(i)
                if i > system.system:getObjectCount() then return end
                local luaObject = system.system:getObjectByIndex(i - 1):getModData()
                if luaObject and cell:getGridSquare(luaObject.x, luaObject.y, luaObject.z) then track(luaObject) end
            end }
    end

    local treeKeys
    phases[#phases + 1] = { name = "trees", checkEvery = 16,
        begin = function() treeKeys = loadedTreeKeys() return #treeKeys end,
        step = function(i)
            local luaObject = loadedTree(system, treeKeys[i])
            if luaObject then updateTree(system, luaObject, hoursPerStage, season, progress, staggered) end
        end }

    if system:mayAdoptWildTrees() then
        local columns = columnsAround(positions, SCAN_RADIUS, false)
        phases[#phases + 1] = { name = "adoption", checkEvery = 1,
            begin = function() return #columns end,
            step = function(i)
                local x, py, pz = columns[i][1], columns[i][2], columns[i][3]
                for y = py - SCAN_RADIUS, py + SCAN_RADIUS do
                    local square = cell:getGridSquare(x, y, pz)
                    local tree = square and square:getTree()
                    if tree then system:adoptTree(square, tree) end
                end
            end }
    end

    -- Chunk load catches a square arriving; this catches one a player is already standing on
    if succession then
        local radius = succession.SWEEP_RADIUS
        local columns = columnsAround(positions, radius, true)
        phases[#phases + 1] = { name = "sweep", checkEvery = 1,
            begin = function() return #columns end,
            step = function(i)
                local x, py = columns[i][1], columns[i][2]
                for y = py - radius, py + radius do succession.sweepSquare(x, y) end
            end }

        local bushKeys
        phases[#phases + 1] = { name = "bushes", checkEvery = 16,
            begin = function() bushKeys = succession.loadedBushKeys() return #bushKeys end,
            step = function(i) succession.refreshBush(bushKeys[i]) end }
    end

    return { phases = phases, phase = 1, index = 0, deadline = math.huge, counts = {},
             totalMs = 0, frames = 0, worstMs = 0 }
end

-- A phase and an index kept between frames
local function advance(j)
    while j.phase <= #j.phases do
        local phase = j.phases[j.phase]
        if not j.count then
            j.count, j.index = phase.begin(), 0
            j.counts[j.phase] = j.count
        end
        while j.index < j.count do
            j.index = j.index + 1
            phase.step(j.index)
            if j.index % phase.checkEvery == 0 and getTimestampMs() >= j.deadline then return false end
        end
        j.phase, j.count = j.phase + 1, nil
    end
    return true
end

-- True once the job is finished; with no deadline it runs to the end
local function work(j, deadline)
    j.deadline = deadline or math.huge
    return advance(j)
end

local function report(j)
    if not Eelt_STreeGrowthSystem.reportJobs then return end
    local parts = {}
    for p, phase in ipairs(j.phases) do parts[#parts + 1] = phase.name .. " " .. tostring(j.counts[p] or 0) end
    print(string.format("%shourly job: %d ms over %d frames, worst frame %d ms, %s",
        PREFIX, j.totalMs, j.frames, j.worstMs,
        table.concat(parts, ", ")))
end

local function onTick()
    if not job then return end
    local started = getTimestampMs()
    local ok, done = pcall(work, job, started + BUDGET_MS)
    local spent = getTimestampMs() - started
    job.totalMs, job.frames = job.totalMs + spent, job.frames + 1
    if spent > job.worstMs then job.worstMs = spent end

    if not ok then
        print(PREFIX .. "hourly job failed and was dropped: " .. tostring(done))
        job = nil
    elseif done then
        report(job)
        job = nil
    end
end

local function finishNow(j)
    local started = getTimestampMs()
    local ok, err = pcall(work, j, nil)
    local spent = getTimestampMs() - started
    j.totalMs, j.frames = j.totalMs + spent, j.frames + 1
    if spent > j.worstMs then j.worstMs = spent end
    if not ok then print(PREFIX .. "hourly job failed: " .. tostring(err)) end
    report(j)
end

function Eelt_STreeGrowthSystem.everyHour()
    local instance = Eelt_STreeGrowthSystem.instance
    if not instance then return end

    -- A job still running an hour later means the budget is too small for this machine
    if job then
        print(PREFIX .. "the last hourly job was still running at the hour and was finished at once")
        finishNow(job)
        job = nil
    end
    job = buildJob(instance)
end

-- For the debug menu, which reads the result straight after
function Eelt_STreeGrowthSystem.runHourNow()
    local instance = Eelt_STreeGrowthSystem.instance
    if not instance then return end
    if job then
        finishNow(job)
        job = nil
    end
    local j = buildJob(instance)
    if j then finishNow(j) end
end

-- Runs the whole job at once, timing each phase, for the debug menu
function Eelt_STreeGrowthSystem:timeHourlyJob(runs)
    local phaseMs, phaseItems, names = {}, {}, {}
    for _ = 1, runs do
        local j = buildJob(self)
        if not j then return nil end
        for p, phase in ipairs(j.phases) do
            local started = getTimestampMs()
            local count = phase.begin()
            for i = 1, count do phase.step(i) end
            local name = phase.name
            if not phaseMs[name] then names[#names + 1] = name end
            phaseMs[name] = (phaseMs[name] or 0) + getTimestampMs() - started
            phaseItems[name] = count
        end
    end
    return names, phaseMs, phaseItems, self.system:getObjectCount(), #loadedTreeKeys()
end

SGlobalObjectSystem.RegisterSystemClass(Eelt_STreeGrowthSystem)

Events.EveryHours.Add(Eelt_STreeGrowthSystem.everyHour)
Events.OnTick.Add(onTick)
