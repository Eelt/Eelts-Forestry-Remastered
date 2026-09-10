require "EeltsForestryRemastered_Planting"
require "TimedActions/EeltsForestryRemastered_PlantTreeAction"

local function predicateDigPlow(item)
    return not item:isBroken() and item:hasTag(ItemTag.DIG_PLOW)
end

-- A tree is not in worldobjects, only the ground blend is, so reach it through the square
local function findSquare(worldobjects)
    for i = 1, worldobjects and #worldobjects or 0 do
        local square = worldobjects[i] and worldobjects[i]:getSquare()
        if square then return square end
    end
    return nil
end

-- One entry per distinct propagule, so a stack of stamped saplings is not eleven menu lines
local function gatherPropagules(inventory)
    local propagules = EeltsForestryRemastered_Propagules
    local seen, kinds = {}, {}
    local items = inventory:getItems()
    for i = 0, items and items:size() - 1 or -1 do
        local item = items:get(i)
        if propagules.isPlantable(item) then
            local species = propagules.getSpecies(item)
            local key = item:getFullType() .. "|" .. tostring(species)
            if not seen[key] then
                seen[key] = true
                kinds[#kinds + 1] = { item = item, species = species }
            end
        end
    end
    return kinds
end

local function labelFor(kind)
    local planting = EeltsForestryRemastered_Planting
    if not kind.species then
        return getText("ContextMenu_Eelt_PlantItem", kind.item:getDisplayName())
    end
    return getText("ContextMenu_Eelt_PlantSpecies",
        planting.speciesName(kind.species), kind.item:getDisplayName())
end

local function plant(worldobjects, playerObj, square, propagule, tool)
    if not luautils.walkAdj(playerObj, square, true) then return end
    ISTimedActionQueue.add(Eelt_PlantTreeAction:new(playerObj, square, propagule, tool))
end

local function disable(option, text)
    option.notAvailable = true
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = text
    option.toolTip = tooltip
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test then return end

    local playerObj = getSpecificPlayer(player)
    local planting = EeltsForestryRemastered_Planting
    if not playerObj or not planting.knowsPlanting(playerObj) then return end

    local square = findSquare(worldobjects)
    if not planting.isPlantableSquare(square) then return end

    local inventory = playerObj:getInventory()
    local kinds = gatherPropagules(inventory)
    if #kinds == 0 then return end

    local tool = inventory:getFirstTagEvalRecurse(ItemTag.DIG_PLOW, predicateDigPlow)
    if not tool then
        local option = context:addOption(getText("ContextMenu_Eelt_PlantTree"), nil, nil)
        disable(option, getText("Tooltip_Eelt_PlantNeedsTool"))
        return
    end

    local parent = context:addOption(getText("ContextMenu_Eelt_PlantTree"), nil, nil)
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(parent, submenu)

    for _, kind in ipairs(kinds) do
        local option = submenu:addOption(labelFor(kind), worldobjects, plant, playerObj, square, kind.item, tool)
        if not planting.isPlantableItem(kind.item) then
            disable(option, getText("Tooltip_Eelt_PlantUnfit"))
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
