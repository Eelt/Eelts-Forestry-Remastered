if isClient() then return end

require "EeltsForestryRemastered_Planting"
require "EeltsForestryRemastered_Propagules"
require "EeltsForestryRemastered_Understory"
require "EeltsForestryRemastered_TreeGrowthSprites"
require "EeltsForestryRemastered_TreeSeasons"
require "TimedActions/ISScything"
require "TimedActions/ISRemoveBush"
require "TimedActions/ISRemoveGrass"
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
local seasons = EeltsForestryRemastered_TreeSeasons

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
local repaired = 0
local timedSquares, timedMs = 0, 0
local REPORT_EVERY = 20000
local sinceReport = 0

print(PREFIX .. "succession loaded")

-- Unlike correction, which only reads the setting once it has found a tree, this pass reaches
-- the settings on every bare square, so they are read on the ten minute tick instead
local enabled, pace, recoverUntouched = true, 1.0, true
local worldHours, worldDays, minDay = 0, 0, 3.0
local seasonName, seasonProgress, staggerOn = nil, 1.0, true

local function refreshOptions()
    local mode = understory.successionMode()
    enabled = mode ~= understory.OFF
    recoverUntouched = mode == understory.ALL_GROUND
    pace = understory.pace()
    worldHours = getGameTime():getWorldAgeHours()
    worldDays = worldHours / 24
    minDay = understory.bounds(pace)
    seasonName, seasonProgress, staggerOn = seasons.current()
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

-- Bushes

-- Every bush of ours in loaded ground, for the hourly refresh. Never saved; a reload refills it
-- as each bush comes back through a chunk load
local loadedBushes = {}

local function bushKey(x, y)
    return x * 100000 + y
end

local function parentName(instance)
    local parent = instance and instance:getParentSprite()
    return parent and parent:getName()
end

-- Compared by name first, so an unchanged bush costs a few lookups and sends nothing
local function applyBushLook(object, entry, x, y)
    local wanted = {}
    for _, name in ipairs(understory.bushOverlays(entry, x, y, seasonName, seasonProgress, staggerOn)) do
        if getSprite(name) then wanted[#wanted + 1] = name end
    end

    local attached = object:getAttachedAnimSprite()
    local count = attached and attached:size() or 0
    if count == #wanted then
        local same = true
        for i = 1, count do
            if parentName(attached:get(i - 1)) ~= wanted[i] then
                same = false
                break
            end
        end
        if same then return false end
    end

    if attached then
        attached:clear()
    else
        object:setAttachedAnimSprite(ArrayList.new())
        attached = object:getAttachedAnimSprite()
    end
    for _, name in ipairs(wanted) do
        attached:add(getSprite(name):newInstance())
    end
    return true
end

-- The hash decides the entry, and a base that no longer agrees is left for evaluate to replace
local function bushEntryOn(object, x, y)
    local entry = understory.bushFor(x, y)
    if entry and spriteNameOf(object) == understory.bushBase(entry) then return entry end
    return nil
end

-- Repairs a bush the first build placed, brings its look up to date, and remembers it
local function tend(square, object, x, y)
    local name = spriteNameOf(object)
    if not understory.isBushSprite(name) then return end

    local entry = understory.oldBushEntry(name)
    local rebuilt = entry ~= nil
    if rebuilt then
        object:setSprite(getSprite(understory.bushBase(entry)))
        repaired = repaired + 1
    else
        entry = bushEntryOn(object, x, y)
        if not entry then return end
    end

    local changed = applyBushLook(object, entry, x, y) or rebuilt
    loadedBushes[bushKey(x, y)] = true
    if changed and isServer() then object:transmitUpdatedSpriteToClients() end
    if rebuilt then square:RecalcAllWithNeighbours(true) end
end

-- For the exits that never reach inspect. A bare square holds only its floor
local function findOurs(square, x, y)
    local objects = square:getObjects()
    if objects:size() < 2 then return end
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if object:getName() == understory.PLACED_NAME then
            tend(square, object, x, y)
            return
        end
    end
end

-- The name is what takes the square off erosion, so it goes on at construction. A bush gets its
-- overlays before it is added, so the item sent to clients already carries them
local function place(square, spriteName)
    if not getSprite(spriteName) then return false end

    local object = IsoObject.new(square, spriteName, understory.PLACED_NAME)
    if understory.isBushSprite(spriteName) then
        local x, y = square:getX(), square:getY()
        local entry = understory.bushFor(x, y)
        if entry then
            applyBushLook(object, entry, x, y)
            loadedBushes[bushKey(x, y)] = true
        end
    end
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
        findOurs(square, x, y)
        return
    else
        elapsed = worldDays
    end

    if elapsed < minDay then
        tooSoon = tooSoon + 1
        findOurs(square, x, y)
        return
    end

    local treeReady, rung = understory.state(x, y, elapsed, pace)
    local wanted = understory.spriteFor(rung, x, y)
    local ours, foreign = inspect(square)
    if ours then tend(square, ours, x, y) end
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

    if not enabled then return findOurs(square, square:getX(), square:getY()) end

    evaluate(square, square:getX(), square:getY())
end

-- Squares arrive before OnGameStart, and the read at load time saw a world that was not there yet
local ready = false

local function onLoadGridsquare(square)
    if not square then return end

    if not ready then
        ready = true
        refreshOptions()
        understory.validateSprites()
        print(string.format("%sfirst square read the world at day %.2f", PREFIX, worldDays))
    end

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
succession.SWEEP_RADIUS = SWEEP_RADIUS

-- One square of the sweep; the hourly job calls this a column at a time
function succession.sweepSquare(x, y)
    local square = getCell():getGridSquare(x, y, 0)
    if square and not square:HasTree() then
        if enabled then evaluate(square, x, y) else findOurs(square, x, y) end
    end
end

function succession.sweepNearPlayers()
    if not getCell() then return end

    local online = getOnlinePlayers()
    local lastPlayer = isServer() and online:size() - 1 or getNumActivePlayers() - 1
    for i = 0, lastPlayer do
        local player = isServer() and online:get(i) or getSpecificPlayer(i)
        if player and math.floor(player:getZ()) == 0 then
            local px, py = math.floor(player:getX()), math.floor(player:getY())
            for x = px - SWEEP_RADIUS, px + SWEEP_RADIUS do
                for y = py - SWEEP_RADIUS, py + SWEEP_RADIUS do succession.sweepSquare(x, y) end
            end
        end
    end
end

-- A copy, so a bush dropped by refreshBush never changes the table while it is being walked
function succession.loadedBushKeys()
    local keys = {}
    for key in pairs(loadedBushes) do keys[#keys + 1] = key end
    return keys
end

function succession.refreshBush(key)
    local x, y = math.floor(key / 100000), key % 100000
    local square = getCell():getGridSquare(x, y, 0)
    local ours = square and inspect(square)
    local entry = ours and bushEntryOn(ours, x, y)
    if not entry then
        loadedBushes[key] = nil
        return
    end
    if applyBushLook(ours, entry, x, y) and isServer() then ours:transmitUpdatedSpriteToClients() end
end

-- Seasons turn on loaded ground too, so every bush seen since it loaded is brought up to date
function succession.refreshBushes()
    if not getCell() then return end
    refreshOptions()
    for _, key in ipairs(succession.loadedBushKeys()) do succession.refreshBush(key) end
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

    local entry = understory.bushFor(x, y)
    if ours and entry and understory.isBushSprite(spriteNameOf(ours)) then
        local carries = {}
        local attached = ours:getAttachedAnimSprite()
        for i = 0, attached and attached:size() - 1 or -1 do
            carries[#carries + 1] = tostring(parentName(attached:get(i)))
        end
        local wants = understory.bushOverlays(entry, x, y, seasonName, seasonProgress, staggerOn)
        local shift = seasons.shiftFor(x, y)
        print(string.format("%s  bush entry %d size %d look=%s staggered=%s carries=%s wants=%s",
            PREFIX, entry.index, entry.size,
            tostring(seasons.lookFor(x, y, seasonName, seasonProgress, staggerOn)), tostring(staggerOn),
            #carries > 0 and table.concat(carries, "+") or "none",
            #wants > 0 and table.concat(wants, "+") or "none"))
        print(string.format("%s  window %.3f to %.3f, year position %s, inside=%s, tracked=%s",
            PREFIX, entry.from + shift, entry.to + shift,
            tostring(seasons.yearPosition(seasonName, seasonProgress)),
            tostring(seasons.inWindow(x, y, entry.from, entry.to, seasonName, seasonProgress)),
            tostring(loadedBushes[bushKey(x, y)] == true)))
    end

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
    local tracked = 0
    for _ in pairs(loadedBushes) do tracked = tracked + 1 end
    print(string.format("%sbushes: %d repaired from the first build, %d tracked in loaded ground",
        PREFIX, repaired, tracked))
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

-- Pulling a bush or grass by hand is a clearing too, or recovery would put it straight back.
-- A wall vine is not ground vegetation
local ISRemoveBush_complete = ISRemoveBush.complete

function ISRemoveBush:complete()
    local square = self.square
    local done = ISRemoveBush_complete(self)
    if square and not self.wallVine and not isClient() then understory.markCleared(square) end
    return done
end

local ISRemoveGrass_complete = ISRemoveGrass.complete

function ISRemoveGrass:complete()
    local square = self.square
    local done = ISRemoveGrass_complete(self)
    if square and not isClient() then understory.markCleared(square) end
    return done
end

-- The sandbox is not readable this early in every case, so the defaults stand until the
-- first tick puts the real values in
pcall(refreshOptions)

Events.OnGameStart.Add(refreshOptions)
Events.LoadGridsquare.Add(onLoadGridsquare)
Events.EveryTenMinutes.Add(refreshOptions)
