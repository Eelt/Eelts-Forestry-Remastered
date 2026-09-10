require "TimedActions/ISChopTreeAction"
require "EeltsForestryRemastered_Propagules"
require "EeltsForestryRemastered_TreeGrowthSprites"

local HEMLOCK_TILESET = "e_canadianhemlock_1"
local CONE_DROP_OPTION = "EeltsForestryRemastered.FixConiferConeDrops"

-- Read the option rather than SandboxVars, which the in game sandbox editor does not refresh
local function isEnabled()
    local option = getSandboxOptions():getOptionByName(CONE_DROP_OPTION)
    return option == nil or option:getValue() ~= false
end

local function coneCount(logYield)
    local roll = math.min(6 - logYield, 4)
    local cones = 0
    for _ = 1, logYield - 1 do
        if roll <= 0 or ZombRand(roll) == 0 then -- a non positive bound always rolls true in the vanilla drop
            cones = cones + 1
        end
    end
    return cones
end

local function speciesOf(tree)
    local sprite = tree:getSprite()
    local tileset = EeltsForestryRemastered_TreeGrowthSprites.identify(sprite and sprite:getName())
    return tileset
end

local function isHemlock(tileset)
    return tileset == HEMLOCK_TILESET
end

-- Vanilla builds its drops inside dropWood, so the only way to tell them from items
-- already lying there is to know what was on the square beforehand
local function itemIdsOn(square)
    local seen = {}
    local objects = square:getWorldObjects()
    for i = 0, objects and objects:size() - 1 or -1 do
        local item = objects:get(i):getItem()
        if item then seen[item:getID()] = true end
    end
    return seen
end

local function stampNewDrops(square, before, tileset)
    local propagules = EeltsForestryRemastered_Propagules
    local objects = square:getWorldObjects()
    for i = 0, objects and objects:size() - 1 or -1 do
        local item = objects:get(i):getItem()
        if item and not before[item:getID()] and propagules.isPlantable(item) then
            propagules.stamp(item, tileset)
        end
    end
end

local ISChopTreeAction_animEvent = ISChopTreeAction.animEvent

function ISChopTreeAction:animEvent(event, parameter)
    local square, logYield, tree, tileset, before

    -- The tree is reset and pooled the moment it topples, so read everything first
    if event == "ChopTree" and not isClient() and self.tree then
        tree = self.tree
        tileset = speciesOf(tree)
        square = tree:getSquare()
        logYield = tree:getLogYield()
        if square then before = itemIdsOn(square) end
    end

    ISChopTreeAction_animEvent(self, event, parameter)

    if not (tree and square and before and tree:getObjectIndex() == -1) then return end

    if tileset then stampNewDrops(square, before, tileset) end

    if isHemlock(tileset) and logYield > 2 and isEnabled() then
        for _ = 1, coneCount(logYield) do
            local cone = square:AddWorldInventoryItem("Base.Pinecone", 0, 0, 0)
            EeltsForestryRemastered_Propagules.stamp(cone, tileset)
        end
    end
end
