EeltsForestryRemastered_TreeSeasons = {}

local seasons = EeltsForestryRemastered_TreeSeasons

local STAGGER_OPTION = "EeltsForestryRemastered.StaggerTreeSeasons"

-- Erosion staggers the turn with a per square magic number; this is the stable equivalent.
-- Operands stay well inside 32 bits because the game's lua overflows % past Integer.MAX_VALUE
function seasons.staggerFor(x, y)
    return ((((x or 0) % 1000) * 73 + (((y or 0) % 1000) * 179)) % 997) / 997
end

function seasons.progress()
    local ok, progress = pcall(function()
        local erosion = ErosionMain.getInstance():getSeasons()
        local days = erosion:getSeasonDays()
        if days <= 0 then return 1.0 end
        return erosion:getSeasonDay() / days
    end)
    if ok and progress then return progress end
    return 1.0
end

function seasons.staggerEnabled()
    local option = getSandboxOptions():getOptionByName(STAGGER_OPTION)
    return option == nil or option:getValue() ~= false
end

-- Read once per tick and passed down, since the bin holds a tree for every square a player
-- has walked past
function seasons.current()
    return getClimateManager():getSeasonName(), seasons.progress(), seasons.staggerEnabled()
end

-- One position through the year: the season's own slot plus how far through it we are. Built
-- this way rather than from day counts so a world with longer seasons stretches the whole cycle
local SLOT = { ["Spring"] = 0, ["Early Summer"] = 1, ["Autumn"] = 2, ["Winter"] = 3 }

function seasons.yearPosition(season, progress)
    local slot = SLOT[season]
    if not slot then return nil end
    if progress < 0 then progress = 0 elseif progress > 0.999999 then progress = 0.999999 end
    return slot + progress
end

-- Boundaries as positions in that year, with the dates they land on. The season table they
-- were tuned against is in docs/reference/b42-lua-notes.md; spring and autumn are about nine
-- weeks each while summer is twenty, so a position is not a fixed number of days
local LEAF_OUT = 0.72     -- 22 Mar to 2 Apr
local SUMMER = 1.14       -- 23 Apr to 16 May
local FIRST_COLOUR = 2.27 -- 15 Sep to 25 Sep
local DEEP_COLOUR = 2.66  -- 10 Oct to 20 Oct
local LEAVES_DOWN = 2.91  -- 26 Oct to 5 Nov, the last of it inside autumn

-- Half of this either side, so it must leave LEAVES_DOWN short of the winter boundary at 3.0
local SPREAD = 0.16

-- The boundaries this tree actually uses, for the debug readout
function seasons.boundariesFor(stagger)
    local shift = (stagger - 0.5) * SPREAD
    return LEAF_OUT + shift, SUMMER + shift, FIRST_COLOUR + shift, DEEP_COLOUR + shift, LEAVES_DOWN + shift
end

-- Colour late and drop late, so nothing looks like autumn until autumn looks like autumn in
-- Kentucky. One stagger moves every boundary together, because a tree that leafs out early
-- also turns early
function seasons.staggered(season, progress, stagger)
    local position = seasons.yearPosition(season, progress)
    if not position then return nil end

    local shift = (stagger - 0.5) * SPREAD
    if position < LEAF_OUT + shift then return nil end
    if position < SUMMER + shift then return "Spring" end
    if position < FIRST_COLOUR + shift then return "Early Summer" end
    if position < DEEP_COLOUR + shift then return "Late Summer" end
    if position < LEAVES_DOWN + shift then return "Autumn" end
    return nil
end

-- Vanilla splits summer and autumn at their midpoints, staggered per square. That is what
-- tints trees in early July and strips them halfway through autumn
function seasons.vanilla(season, progress, stagger)
    if season == "Spring" then return "Spring" end

    local split = 0.45 + stagger * 0.1
    if season == "Early Summer" then
        if progress < split then return "Early Summer" end
        return "Late Summer"
    end
    if season == "Autumn" and progress < split then return "Autumn" end
    return nil
end

function seasons.lookFor(x, y, season, progress, staggered)
    season = season or getClimateManager():getSeasonName()
    if staggered == nil then staggered = seasons.staggerEnabled() end
    progress = progress or seasons.progress()
    local stagger = seasons.staggerFor(x, y)

    if staggered then return seasons.staggered(season, progress, stagger) end
    if season ~= "Spring" and season ~= "Early Summer" and season ~= "Autumn" then return nil end
    return seasons.vanilla(season, progress, stagger)
end
