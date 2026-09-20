EeltsForestryRemastered_Understory = {}

local understory = EeltsForestryRemastered_Understory

-- Renaming is what makes vanilla erosion relinquish a square, and ErosionObj carries the
-- matched name for grass and bushes as much as for trees
understory.PLACED_NAME = "Eelt_Recovering"

-- One number on the square itself, written only where the mod watched something come down,
-- so the record costs nothing on ground nobody has touched
understory.CLEARED_KEY = "Eelt_Cleared"

local PACE_OPTION = "EeltsForestryRemastered.RecoveryTimeMultiplier"
local SUCCESSION_OPTION = "EeltsForestryRemastered.VegetationSuccession"

understory.OFF, understory.CLEARED_ONLY, understory.ALL_GROUND = 1, 2, 3

understory.rungs = { "grass", "cover", "bush" }

-- Vanilla's own worldgen feature sprites, so recovered ground matches the ground beside it
understory.sprites = {
    grass = {
        "e_newgrass_1_16", "e_newgrass_1_17", "e_newgrass_1_18",
        "e_newgrass_1_19", "e_newgrass_1_20", "e_newgrass_1_21",
    },
    cover = {
        "e_newgrass_1_8", "e_newgrass_1_9", "e_newgrass_1_10",
        "e_newgrass_1_11", "e_newgrass_1_12", "e_newgrass_1_13",
        "d_generic_1_48", "d_generic_1_49", "d_generic_1_50", "d_generic_1_51",
        "d_generic_1_52", "d_generic_1_53", "d_generic_1_54", "d_generic_1_55",
        "d_generic_1_80", "d_generic_1_81", "d_generic_1_82", "d_generic_1_83",
        "d_generic_1_84", "d_generic_1_85", "d_generic_1_86", "d_generic_1_87",
    },
    bush = {
        "f_bushes_1_67", "f_bushes_1_69", "f_bushes_1_70", "f_bushes_1_72",
        "f_bushes_1_73", "f_bushes_1_75", "f_bushes_1_76", "f_bushes_1_79",
        "f_bushes_1_99", "f_bushes_1_101", "f_bushes_1_102", "f_bushes_1_104",
        "f_bushes_1_105", "f_bushes_1_107", "f_bushes_1_108", "f_bushes_1_111",
    },
}

-- Days after clearing at which the keenest square reaches each rung. The tree rung is set
-- to vanilla's own earliest wild tree, which erosion places on day 30 of a default world
local GRASS_DAY, COVER_DAY, BUSH_DAY, TREE_DAY = 3, 10, 21, 30

-- One value drives every rung, so a slow square is slow all the way up. At 2.0 the latest
-- square reaches trees on day 90, which is about where vanilla's slowest squares land
local SPREAD = 2.0

-- Three questions are asked of a square, in this order: should it carry a bush, should it
-- carry tall grass or ferns, and otherwise it carries grass. Any ground that can grow at all
-- ends up with grass on it, so these are the shares taken off the top rather than a coverage
local BUSH_SHARE, COVER_SHARE = 0.05, 0.30

-- A shuffled table rather than arithmetic. Anything linear in x and y gives equal values
-- along straight lines, which is what made the first build grow in rows
local PERM = {}
do
    for i = 0, 255 do PERM[i] = i end
    local seed = 12345
    for i = 255, 1, -1 do
        seed = (seed * 16807) % 65521
        local j = seed % (i + 1)
        PERM[i], PERM[j] = PERM[j], PERM[i]
    end
end

local function hash(x, y, salt)
    return PERM[(PERM[(x + salt) % 256] + y) % 256] / 256
end

-- Shared so that nothing else in the mod is tempted to write its own arithmetic one
understory.noise = hash

-- Two octaves: a per square value and a coarser one shared across a patch of eight, which
-- is what makes recovery clump rather than arrive evenly
function understory.eagerness(x, y)
    return hash(x, y, 0) * 0.6 + hash(math.floor(x / 8), math.floor(y / 8), 71) * 0.4
end

function understory.pace()
    local option = getSandboxOptions():getOptionByName(PACE_OPTION)
    local multiplier = option and option:getValue() or 1.0
    if multiplier <= 0 then multiplier = 1.0 end
    return multiplier
end

function understory.successionMode()
    local option = getSandboxOptions():getOptionByName(SUCCESSION_OPTION)
    return option and option:getValue() or understory.ALL_GROUND
end

function understory.markCleared(square)
    if not square then return end
    square:getModData()[understory.CLEARED_KEY] = getGameTime():getWorldAgeHours()
    if isServer() then square:transmitModdata() end
end

function understory.clearedAt(square)
    if not square or not square:hasModData() then return nil end
    return square:getModData()[understory.CLEARED_KEY]
end

-- Kahlua charges for every call and table lookup, and this runs on each bare square, so the
-- lookup is inlined rather than going back through clearedAt
function understory.elapsedDaysFast(square, recordedOnly, worldDays)
    local cleared = square:hasModData() and square:getModData()[understory.CLEARED_KEY]
    if cleared then return worldDays - cleared / 24 end
    if recordedOnly then return nil end
    return worldDays
end

-- A square the mod never saw cleared counts as bare since the world began, which is what
-- lets a field abandoned before the mod arrived recover at all
function understory.elapsedDays(square, recordedOnly, nowHours)
    local now = nowHours or getGameTime():getWorldAgeHours()
    return understory.elapsedDaysFast(square, recordedOnly, now / 24)
end

function understory.dueDay(rung, eager, pace)
    local base = rung == "grass" and GRASS_DAY or rung == "cover" and COVER_DAY
        or rung == "bush" and BUSH_DAY or rung == "tree" and TREE_DAY
    if not base then return nil end
    return base * (1 + (eager or 0) * SPREAD) * (pace or 1.0)
end

-- Nothing can have reached a rung before this, and everything has reached the last one after
-- it, so the pass can skip the whole calculation outside the window
function understory.bounds(pace)
    pace = pace or 1.0
    return GRASS_DAY * pace, TREE_DAY * (1 + SPREAD) * pace
end

local function ramp(value, from, to)
    if value <= from then return 0 end
    if value >= to then return 1 end
    return (value - from) / (to - from)
end

-- Whether this square may carry a tree, and which of the three it should carry under one.
-- Each layer fades in across its own window, so an area thickens rather than arriving whole
function understory.state(x, y, elapsedDays, pace)
    if not elapsedDays or elapsedDays <= 0 then return false, nil end

    local adjusted = elapsedDays / ((1 + understory.eagerness(x, y) * SPREAD) * (pace or 1.0))
    if adjusted < GRASS_DAY then return false, nil end

    -- Vanilla reads one noise value per square and gives each layer its own threshold on it,
    -- so a rich patch grows bushes where a poor one only grows grass. A patch weight averaging
    -- one keeps the shares above while moving them around, which is what makes thickets
    local patch = 0.3 + 1.4 * hash(math.floor(x / 6), math.floor(y / 6), 227)
    local bush = BUSH_SHARE * patch * ramp(adjusted, BUSH_DAY, TREE_DAY)
    local cover = bush + COVER_SHARE * patch * ramp(adjusted, COVER_DAY, BUSH_DAY)

    local rank = hash(x, y, 149)
    local carried
    if rank < bush then carried = "bush"
    elseif rank < cover then carried = "cover"
    elseif rank < ramp(adjusted, GRASS_DAY, COVER_DAY) then carried = "grass" end

    return adjusted >= TREE_DAY, carried
end

function understory.spriteFor(rung, x, y)
    local set = rung and understory.sprites[rung]
    if not set or #set == 0 then return nil end
    return set[math.floor(hash(x, y, 211) * #set) + 1]
end

function understory.boundariesFor(x, y, pace)
    local eager = understory.eagerness(x, y)
    return eager,
        understory.dueDay("grass", eager, pace),
        understory.dueDay("cover", eager, pace),
        understory.dueDay("bush", eager, pace),
        understory.dueDay("tree", eager, pace)
end

-- The map still references vegetation_groundcover_01 tiles the game no longer loads, so a
-- name being in the tile definitions is not proof it resolves
function understory.validateSprites()
    local dropped = {}
    for rung, set in pairs(understory.sprites) do
        local keep = {}
        for _, name in ipairs(set) do
            if getSprite(name) then
                keep[#keep + 1] = name
            else
                dropped[#dropped + 1] = name
            end
        end
        understory.sprites[rung] = keep
    end

    local kept = 0
    for _, set in pairs(understory.sprites) do kept = kept + #set end

    print("Eelt's Forestry Remastered: understory holds " .. kept .. " sprites"
        .. (#dropped > 0 and ", dropped " .. #dropped .. " the game does not have: "
            .. table.concat(dropped, ", ") or ""))
end

Events.OnGameStart.Add(understory.validateSprites)
