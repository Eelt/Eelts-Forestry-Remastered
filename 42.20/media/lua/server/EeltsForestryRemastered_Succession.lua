if isClient() then return end

require "EeltsForestryRemastered_Planting"
require "EeltsForestryRemastered_Propagules"
require "EeltsForestryRemastered_Understory"
require "EeltsForestryRemastered_TreeGrowthSprites"
require "TimedActions/ISScything"
require "Farming/TimedActions/ISShovelAction"

-- Vanilla puts nothing back on a square that loses its vegetation, so recovery is entirely
-- the mod's. This runs for every square of every chunk load, so the order of the tests below
-- is what decides whether it is affordable
EeltsForestryRemastered_Succession = {}

local succession = EeltsForestryRemastered_Succession

local PREFIX = "Eelt's Forestry Remastered: "
local planting = EeltsForestryRemastered_Planting
local propagules = EeltsForestryRemastered_Propagules
local understory = EeltsForestryRemastered_Understory
local sprites = EeltsForestryRemastered_TreeGrowthSprites

-- A crowded square retries on every chunk load, and the neighbour scan is the one expensive
-- thing here, so each square only gets a try on one day in five
local ESTABLISH_EVERY_DAYS = 5
local BIAS_RADIUS = 8
local SWEEP_RADIUS = 20

-- A quarter of the 17 by 17 neighbourhood
local UNLOADED_TOLERANCE = 72

succession.verbose = false
succession.timing = false

-- Measured at 0.100 microseconds a square, against about one for the pass itself, so it is
-- a correction rather than the bulk of the reading
local timerOverheadMs = 0

-- Upvalues rather than fields, since these are touched on every square
local squares, offLevel, treed, tooSoon, untouched, vegetated, unchanged, ineligible, placed, established = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
local timedSquares, timedMs = 0, 0
local REPORT_EVERY = 20000
local sinceReport = 0

print(PREFIX .. "succession loaded")

-- Unlike correction, which only reads the setting once it has found a tree, this pass reaches
-- the settings on every bare square, so they are read on the ten minute tick instead
local enabled, pace, recoverUntouched = true, 1.0, true
local worldHours, worldDays, minDay = 0, 0, 3.0

local function refreshOptions()
    local mode = understory.successionMode()
    enabled = mode ~= understory.OFF
    recoverUntouched = mode == understory.ALL_GROUND
    pace = understory.pace()
    worldHours = getGameTime():getWorldAgeHours()
    worldDays = worldHours / 24
    minDay = understory.bounds(pace)
end

-- Placement and replacement

-- Vanilla's own grass, ferns, groundcover and bushes, which mean the square is not bare
-- ground at all. Matched by prefix, since the families run to thousands of sprites, but
-- remembered per name so the match itself happens once rather than on every object of every
-- recovering square
local VEGETATION_PREFIXES = { "e_newgrass", "f_bushes", "d_generic", "d_plants", "vegetation_" }

local vegetationByName = {}

local function isVanillaVegetation(name)
    if not name then return false end

    local known = vegetationByName[name]
    if known ~= nil then return known end

    local found = false
    for _, prefix in ipairs(VEGETATION_PREFIXES) do
        if string.find(name, prefix, 1, true) == 1 then
            found = true
            break
        end
    end

    vegetationByName[name] = found
    return found
end

-- One walk answers both questions: what the mod put here, and whether anything else is
-- growing here already
local function inspect(square)
    local ours, foreign = nil, false
    local objects = square:getObjects()
    for i = 0, objects and objects:size() - 1 or -1 do
        local object = objects:get(i)
        if object:getName() == understory.PLACED_NAME then
            ours = object
        else
            local sprite = object:getSprite()
            if isVanillaVegetation(sprite and sprite:getName()) then foreign = true end
        end
    end
    return ours, foreign
end

local function spriteNameOf(object)
    local sprite = object and object:getSprite()
    return sprite and sprite:getName() or nil
end

-- The name is what takes the square off erosion, so it goes on at construction
local function place(square, spriteName)
    if not getSprite(spriteName) then return false end

    local object = IsoObject.new(square, spriteName, understory.PLACED_NAME)
    square:AddTileObject(object)
    if isServer() then object:transmitCompleteItemToClients() end
    placed = placed + 1
    return true
end

-- Neighbours, for crowding and for what a stand should reseed as

local function survey(square, x, y)
    local cell = getCell()
    local z = square:getZ()
    local crowd, near, parents, unloaded = 0, {}, {}, 0
    local checkPlanted = propagules.plantedParentMode() ~= 1
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance

    for dx = -BIAS_RADIUS, BIAS_RADIUS do
        for dy = -BIAS_RADIUS, BIAS_RADIUS do
            if dx ~= 0 or dy ~= 0 then
                local other = cell:getGridSquare(x + dx, y + dy, z)
                if not other then unloaded = unloaded + 1 end
                local tree = other and other:getTree()
                if tree then
                    if math.abs(dx) <= propagules.CROWD_RADIUS and math.abs(dy) <= propagules.CROWD_RADIUS then
                        crowd = crowd + 1
                    end
                    if math.abs(dx) <= propagules.MIN_SPACING and math.abs(dy) <= propagules.MIN_SPACING then
                        crowd = nil
                    end
                    local tileset = sprites.identify(spriteNameOf(tree))
                    if tileset then
                        local counts = near[tileset] or { wild = 0, planted = 0 }
                        local luaObject = checkPlanted and system and system:getLuaObjectOnSquare(other)
                        if luaObject and luaObject.planted then
                            counts.planted = counts.planted + 1
                        else
                            counts.wild = counts.wild + 1
                        end
                        near[tileset] = counts
                        local list = parents[tileset] or {}
                        list[#list + 1] = other
                        parents[tileset] = list
                    end
                end
            end
            if crowd == nil then return nil, near, parents, unloaded end
        end
    end
    return crowd, near, parents, unloaded
end

-- The parent contributes only its species today. It is chosen now so that inherited timing
-- has somewhere to attach later
local function tryEstablish(square, x, y)
    local weights = propagules.zoneWeightsAt(x, y)
    if not weights then return false end

    local limit = propagules.crowdLimitAt(x, y)
    if not limit or limit <= 0 then return false end

    -- A square on a chunk edge cannot see the trees next door, and counting those as absent
    -- would let recovery crowd every boundary. It waits for a load that can see them
    local crowd, near, parents, unloaded = survey(square, x, y)
    if unloaded > UNLOADED_TOLERANCE then return false end
    if not crowd or crowd >= limit then return false end

    local rolled = propagules.rollFromWeights(propagules.biasedWeights(weights, near))
    if not rolled then return false end

    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if not system or not system:adoptEstablishedTree(square, rolled) then return false end

    established = established + 1
    if succession.verbose or established == 1 then
        local candidates = parents[rolled]
        local parent = candidates and candidates[ZombRand(#candidates) + 1]
        print(string.format("%sestablished %s at %d,%d, %d trees within %d of a limit of %d, parent %s",
            PREFIX, rolled, x, y, crowd, propagules.CROWD_RADIUS, limit,
            parent and string.format("%d,%d", parent:getX(), parent:getY()) or "none"))
    end
    return true
end

-- Each square owns one day in five to try on. Drawn from the shuffled noise rather than from
-- the coordinates directly, because anything linear here would put the day's candidates on
-- diagonals and let them claim the crowding budget in stripes
local function mayTryToday(x, y)
    return math.floor(understory.noise(x, y, 181) * ESTABLISH_EVERY_DAYS)
        == math.floor(worldDays) % ESTABLISH_EVERY_DAYS
end

-- What this square should be carrying, and putting it there if it is not. The ladder gate is
-- arithmetic and one mod data read, while isPlantableSquare walks the square's objects, so
-- nothing pays the ground test until it has something to gain by it
local function evaluate(square, x, y)
    -- One comparison rejects a square that cannot have earned anything yet, which on a young
    -- world is nearly all of them, before any of the ladder arithmetic runs
    local cleared = square:hasModData() and square:getModData()[understory.CLEARED_KEY]
    local elapsed
    if cleared then
        elapsed = worldDays - cleared / 24
    elseif not recoverUntouched then
        untouched = untouched + 1
        return
    else
        elapsed = worldDays
    end

    if elapsed < minDay then
        tooSoon = tooSoon + 1
        return
    end

    local treeReady, rung = understory.state(x, y, elapsed, pace)
    local wanted = understory.spriteFor(rung, x, y)
    local ours, foreign = inspect(square)
    local trying = treeReady and mayTryToday(x, y)

    -- Anything already growing here stops the understory, since recovery may not stack a
    -- second plant on a square and may not remove what is already on one. It does not stop a
    -- tree, which comes up through grass the same way a planted one does
    if not trying then
        if foreign then
            vegetated = vegetated + 1
            return
        end
        if ours == nil and wanted == nil then
            unchanged = unchanged + 1
            return
        end
        -- A square already carrying what it should was judged eligible when it was put there
        if ours and spriteNameOf(ours) == wanted then
            unchanged = unchanged + 1
            return
        end
    end

    if not planting.isPlantableSquare(square) then
        ineligible = ineligible + 1
        return
    end

    -- The understory goes only once the tree is actually there, so a refused try leaves the
    -- square exactly as it was rather than churning a bush off and back on
    if trying and tryEstablish(square, x, y) then
        if ours then square:transmitRemoveItemFromSquare(ours) end
        return
    end

    if foreign then
        vegetated = vegetated + 1
        return
    end

    if ours and spriteNameOf(ours) == wanted then return end
    if ours then square:transmitRemoveItemFromSquare(ours) end
    if wanted then place(square, wanted) end
end

-- Ordered by how often each test fires and what it costs
local function classify(square)
    if square:getZ() ~= 0 then
        offLevel = offLevel + 1
        return
    end

    if square:HasTree() then
        treed = treed + 1
        return
    end

    if not enabled then return end

    evaluate(square, square:getX(), square:getY())
end

local function onLoadGridsquare(square)
    if not square then return end

    squares = squares + 1
    sinceReport = sinceReport + 1
    if sinceReport >= REPORT_EVERY then
        sinceReport = 0
        succession.report()
    end

    if not succession.timing then return classify(square) end

    -- Each square is far under the millisecond timer's resolution, so most deltas are zero
    -- and the sum is an estimate of the total rather than a reading of it
    local started = getTimestampMs()
    classify(square)
    timedMs = timedMs + (getTimestampMs() - started)
    timedSquares = timedSquares + 1
end

-- Chunk load catches a square arriving. A square a player is standing next to has already
-- arrived, so the hourly tick walks those instead
function succession.sweepNearPlayers()
    if not enabled then return end

    local cell = getCell()
    if not cell then return end

    local online = getOnlinePlayers()
    local lastPlayer = isServer() and online:size() - 1 or getNumActivePlayers() - 1
    for i = 0, lastPlayer do
        local player = isServer() and online:get(i) or getSpecificPlayer(i)
        if player then
            local px, py = math.floor(player:getX()), math.floor(player:getY())
            local pz = math.floor(player:getZ())
            if pz == 0 then
                for x = px - SWEEP_RADIUS, px + SWEEP_RADIUS do
                    for y = py - SWEEP_RADIUS, py + SWEEP_RADIUS do
                        local square = cell:getGridSquare(x, y, 0)
                        if square and not square:HasTree() then evaluate(square, x, y) end
                    end
                end
            end
        end
    end
end

-- Everything the debug menu needs to see about one square, in one line each
function succession.describe(square)
    if not square then return end
    local x, y = square:getX(), square:getY()
    refreshOptions()
    local elapsed = understory.elapsedDays(square, not recoverUntouched)
    local eager, grass, cover, bush, tree = understory.boundariesFor(x, y, pace)
    local ours, foreign = inspect(square)
    local treeReady, rung = understory.state(x, y, elapsed, pace)

    print(string.format("%sworld age %.2f days, %d nights survived",
        PREFIX, worldDays, getGameTime():getNightsSurvived()))
    print(string.format("%s%d,%d eligible=%s cleared=%s elapsed=%s days wants=%s treeReady=%s",
        PREFIX, x, y, tostring(planting.isPlantableSquare(square)),
        tostring(understory.clearedAt(square)),
        elapsed and string.format("%.2f", elapsed) or "nil",
        tostring(rung or "nothing"), tostring(treeReady)))
    print(string.format("%s  carrying=%s, other growth here=%s",
        PREFIX, tostring(spriteNameOf(ours) or "nothing of ours"), tostring(foreign)))
    print(string.format("%s  eagerness=%.3f pace=%.2f grass=%.1f cover=%.1f bush=%.1f tree=%.1f tryToday=%s",
        PREFIX, eager, pace, grass, cover, bush, tree, tostring(mayTryToday(x, y))))

    local crowd, near, _, unloaded = survey(square, x, y)
    local limit = propagules.crowdLimitAt(x, y)
    print(string.format("%s  crowd=%s limit=%s density=%s unloaded=%d of 288",
        PREFIX, tostring(crowd), tostring(limit), tostring(propagules.zoneDensityAt(x, y)), unloaded))

    local weights = propagules.zoneWeightsAt(x, y)
    if not weights then
        print(PREFIX .. "  no species pool for this zone")
        return
    end
    for tileset, weight in pairs(propagules.biasedWeights(weights, near)) do
        local counts = near[tileset] or {}
        print(string.format("%s  %-24s weight %.3f from %.3f, %d wild and %d planted nearby",
            PREFIX, tileset, weight, weights[tileset] or 0, counts.wild or 0, counts.planted or 0))
    end
end

function succession.forceEstablish(square)
    if not square then return end
    local ok = tryEstablish(square, square:getX(), square:getY())
    print(PREFIX .. "forced establishment " .. (ok and "succeeded" or "refused"))
end

function succession.forceRung(square, rung)
    if not square then return end
    local x, y = square:getX(), square:getY()
    local existing = inspect(square)
    if existing then square:transmitRemoveItemFromSquare(existing) end
    if not rung then
        print(PREFIX .. "cleared the square")
        return
    end
    local wanted = understory.spriteFor(rung, x, y)
    print(string.format("%splacing %s: %s, %s", PREFIX, rung, tostring(wanted),
        place(square, wanted) and "placed" or "the game has no such sprite"))
end

succession.refresh = refreshOptions

-- The same pair of calls with nothing between them, which is what the instrument costs
function succession.calibrate()
    local runs, total = 20000, 0
    for _ = 1, runs do
        local started = getTimestampMs()
        total = total + (getTimestampMs() - started)
    end
    timerOverheadMs = total / runs
    print(string.format("%stimer overhead %.3f microseconds a square", PREFIX, timerOverheadMs * 1000))
end

function succession.report()
    print(string.format("%ssuccession: %d squares, %d off ground level, %d already treed, %d too soon, %d untouched and left alone, %d already growing, %d unchanged, %d ineligible, %d planted, %d trees established",
        PREFIX, squares, offLevel, treed, tooSoon, untouched, vegetated, unchanged, ineligible, placed, established))
    if timedSquares > 0 then
        local raw = timedMs * 1000.0 / timedSquares
        print(string.format("%ssuccession timing: %d squares sampled, %d ms, %.2f microseconds a square raw, %.2f net of the timer",
            PREFIX, timedSquares, timedMs, raw, raw - timerOverheadMs * 1000))
    end
end

-- Scything is the other clearing the mod can see. Vanilla restores the ground's own grass
-- appearance on its GrassRegrowth timer but never replaces the tufts it deleted, so those are
-- ours. Without this the square would fall back to the world clock and put them straight back
local ISScything_getGrass = ISScything.getGrass

function ISScything:getGrass(square)
    local hadGrass = square and square:checkHaveGrass()
    ISScything_getGrass(self, square)
    if hadGrass and not isClient() then understory.markCleared(square) end
end

-- Digging a plot out leaves bare ground the same way. Plowing does not need this, since the
-- plot it leaves behind is already excluded from planting and so from recovery
local ISShovelAction_complete = ISShovelAction.complete

function ISShovelAction:complete()
    local square = self.plant and self.plant:getSquare()
    local done = ISShovelAction_complete(self)
    if square and not isClient() then understory.markCleared(square) end
    return done
end

-- The sandbox is not readable this early in every case, so the defaults stand until the
-- first tick puts the real values in
pcall(refreshOptions)

Events.OnGameStart.Add(refreshOptions)
Events.LoadGridsquare.Add(onLoadGridsquare)
Events.EveryTenMinutes.Add(refreshOptions)
