require "TimedActions/ISChopTreeAction"

local HEMLOCK_TILESET = "e_canadianhemlock"
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

local function isHemlock(tree)
    local sprite = tree:getSprite()
    local name = sprite and sprite:getName()
    return name ~= nil and luautils.stringStarts(name, HEMLOCK_TILESET)
end

local ISChopTreeAction_animEvent = ISChopTreeAction.animEvent

function ISChopTreeAction:animEvent(event, parameter)
    local square, logYield, tree

    -- The tree is reset and pooled the moment it topples, so read everything first
    if event == "ChopTree" and not isClient() and self.tree and isHemlock(self.tree) then
        tree = self.tree
        square = tree:getSquare()
        logYield = tree:getLogYield()
    end

    ISChopTreeAction_animEvent(self, event, parameter)

    if tree and square and logYield > 2 and tree:getObjectIndex() == -1 and isEnabled() then
        for _ = 1, coneCount(logYield) do
            square:AddWorldInventoryItem("Base.Pinecone", 0, 0, 0)
        end
    end
end
