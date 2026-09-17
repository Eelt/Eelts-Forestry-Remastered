if isClient() then return end

require "EeltsForestryRemastered_Propagules"
require "EeltsForestryRemastered_TreeGrowthSprites"

-- Vanilla erosion picks a tree's species from soil noise and never reads the forage zone.
-- It decides a square once and renaming a tree takes that square off it for good, so one
-- pass over each square is enough to own it
EeltsForestryRemastered_ErosionBoundary = {}

local boundary = EeltsForestryRemastered_ErosionBoundary

local PREFIX = "Eelt's Forestry Remastered: "
local CORRECT_OPTION = "EeltsForestryRemastered.CorrectForestComposition"

local sprites = EeltsForestryRemastered_TreeGrowthSprites
local propagules = EeltsForestryRemastered_Propagules

boundary.verbose = false

-- Upvalues rather than fields on the table, since these are touched on every square
local squares, settled, corrected, unzoned = 0, 0, 0, 0
local REPORT_EVERY = 20000
local sinceReport = 0

print(PREFIX .. "erosion boundary loaded")

local function isEnabled()
    local option = getSandboxOptions():getOptionByName(CORRECT_OPTION)
    return option == nil or option:getValue() ~= false
end

local function correct(square, tree)
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if not system then return end

    -- The name is the fast path, this is the record. A save that kept one but not the other
    -- lands here, and finding the object is what stops the square being rerolled
    if system:getLuaObjectOnSquare(square) then return end

    local x, y = square:getX(), square:getY()
    local weights = propagules.zoneWeightsAt(x, y)
    if not weights then
        unzoned = unzoned + 1
        return
    end

    local sprite = tree:getSprite()
    local tileset, stage = sprites.identify(sprite and sprite:getName())
    if not tileset then return end

    local rolled = propagules.rollFromWeights(weights)
    if not rolled then return end
    if not system:adoptCorrectedTree(square, tree, rolled, stage) then return end

    corrected = corrected + 1

    -- The first one proves the pass reaches a tree at all, the rest are a running total
    if boundary.verbose or corrected == 1 then
        print(string.format("%scorrected %d,%d stage %d from %s to %s", PREFIX, x, y, stage, tileset, rolled))
    end
end

-- Ordered by how often each test fires and what it costs. The setting is read only on the
-- rare path, since reading it per square would cost more than the tree test it would gate
local function onLoadGridsquare(square)
    if not square then return end

    squares = squares + 1
    sinceReport = sinceReport + 1
    if sinceReport >= REPORT_EVERY then
        sinceReport = 0
        boundary.report()
    end

    local tree = square:getTree()
    if not tree then return end

    if tree:getName() == sprites.ADOPTED_NAME then
        settled = settled + 1
        return
    end

    if not isEnabled() then return end

    correct(square, tree)
end

function boundary.report()
    print(string.format("%sboundary: %d squares, %d already settled, %d corrected, %d left alone for want of a local pool",
        PREFIX, squares, settled, corrected, unzoned))
end

Events.LoadGridsquare.Add(onLoadGridsquare)
