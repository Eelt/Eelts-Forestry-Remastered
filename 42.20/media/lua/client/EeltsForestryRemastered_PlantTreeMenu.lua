require "EeltsForestryRemastered_Planting"

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
local function gatherKinds(items)
    local propagules = EeltsForestryRemastered_Propagules
    local planting = EeltsForestryRemastered_Planting
    local seen, kinds = {}, {}
    for _, item in ipairs(items) do
        if propagules.isPlantable(item) then
            local kind = Eelt_PlantTreeCursor.kindOf(item)
            if not seen[kind.key] then
                seen[kind.key] = kind
                kind.item = item
                kinds[#kinds + 1] = kind
            elseif not planting.isPlantableItem(seen[kind.key].item) and planting.isPlantableItem(item) then
                seen[kind.key].item = item -- a fit berry stands for the stack ahead of a poisoned one
            end
        end
    end
    return kinds
end

local function carriedItems(inventory)
    local list, items = {}, inventory:getItems()
    for i = 0, items and items:size() - 1 or -1 do
        list[#list + 1] = items:get(i)
    end
    return list
end

local function labelFor(kind)
    local planting = EeltsForestryRemastered_Planting
    if not kind.species then
        return getText("ContextMenu_Eelt_PlantItem", kind.item:getDisplayName())
    end
    return getText("ContextMenu_Eelt_PlantSpecies",
        planting.speciesName(kind.species), kind.item:getDisplayName())
end

local function openCursor(_, playerObj, kind)
    local cursor = Eelt_PlantTreeCursor:new(playerObj, kind)
    getCell():setDrag(cursor, cursor.player)
end

local function disable(option, text)
    option.notAvailable = true
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = text
    option.toolTip = tooltip
end

local function addKindOption(menu, playerObj, kind, tool)
    local option = menu:addOption(labelFor(kind), nil, openCursor, playerObj, kind)
    if not tool then
        disable(option, getText("Tooltip_Eelt_PlantNeedsTool"))
    elseif not EeltsForestryRemastered_Planting.isPlantableItem(kind.item) then
        disable(option, getText("Tooltip_Eelt_PlantUnfit"))
    end
    return option
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test then return end

    local playerObj = getSpecificPlayer(player)
    local planting = EeltsForestryRemastered_Planting
    if not playerObj or not planting.knowsPlanting(playerObj) then return end

    local square = findSquare(worldobjects)
    if not planting.isPlantableSquare(square) then return end

    local inventory = playerObj:getInventory()
    local kinds = gatherKinds(carriedItems(inventory))
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
        addKindOption(submenu, playerObj, kind, tool)
    end
end

-- Only what the player carries; a sapling in a crate on the floor gets no option
local function onFillInventoryObjectContextMenu(player, context, items)
    local playerObj = getSpecificPlayer(player)
    local planting = EeltsForestryRemastered_Planting
    if not playerObj or not planting.knowsPlanting(playerObj) then return end

    local carried = {}
    for _, item in ipairs(ISInventoryPane.getActualItems(items)) do
        local container = item:getContainer()
        if container and container:isInCharacterInventory(playerObj) then
            carried[#carried + 1] = item
        end
    end

    local kinds = gatherKinds(carried)
    if #kinds == 0 then return end

    local tool = playerObj:getInventory():getFirstTagEvalRecurse(ItemTag.DIG_PLOW, predicateDigPlow)
    for _, kind in ipairs(kinds) do
        addKindOption(context, playerObj, kind, tool)
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
