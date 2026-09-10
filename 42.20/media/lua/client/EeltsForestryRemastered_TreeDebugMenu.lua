require "EeltsForestryRemastered_Planting"

local PREFIX = "Eelt's Forestry Remastered: "

local function describe(tree)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local sprite = tree:getSprite()
    local spriteName = sprite and sprite:getName() or "nil"
    local tileset, stage
    if sprites then tileset, stage = sprites.identify(spriteName) end

    local attached = tree:getAttachedAnimSprite()
    local overlay = "none"
    if attached and attached:size() > 0 then
        local first = attached:get(0)
        overlay = first and first:getName() or "unnamed"
    end

    print(string.format("%sname=%s sprite=%s overlay=%s season=%s species=%s stage=%s size=%d logs=%d",
        PREFIX, tostring(tree:getName()), spriteName, overlay,
        tostring(getClimateManager():getSeasonName()), tostring(tileset), tostring(stage),
        tree:getSize(), tree:getLogYield()))

    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    local square = tree:getSquare()
    local luaObject = system and square and system:getLuaObjectOnSquare(square)
    if not luaObject then return end

    local ok, seasonDay, seasonDays = pcall(function()
        local seasons = ErosionMain.getInstance():getSeasons()
        return seasons:getSeasonDay(), seasons:getSeasonDays()
    end)
    print(string.format("%s  displaySeason=%s stored=%s seasonDay=%s seasonDays=%s readable=%s",
        PREFIX, tostring(luaObject:displaySeason()), tostring(luaObject.overlaySeason),
        tostring(seasonDay), tostring(seasonDays), tostring(ok)))
    print(PREFIX .. "  " .. luaObject:debugSeason())
end

local function adoptOrGrow(tree)
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if not system then
        print(PREFIX .. "growth system not loaded")
        return
    end

    local square = tree:getSquare()
    if not square then return end

    local luaObject = system:getLuaObjectOnSquare(square)
    if luaObject then
        luaObject:grow()
    else
        system:adoptTree(square, tree)
        luaObject = system:getLuaObjectOnSquare(square)
    end

    if luaObject then
        print(string.format("%sstage=%s overlaySeason=%s planted=%s", PREFIX,
            tostring(luaObject.stage), tostring(luaObject.overlaySeason), tostring(luaObject.planted)))
    end
    describe(tree)
end

-- Month is 0 based, matching the erosion demo debug controls
local function skipMonth(tree)
    local gameTime = GameTime.getInstance()
    gameTime:setMonth(gameTime:getMonth() + 1)
    if gameTime:getMonth() >= 12 then
        gameTime:setMonth(0)
        gameTime:setYear(gameTime:getYear() + 1)
    end

    local lastDay = gameTime:daysInMonth(gameTime:getYear(), gameTime:getMonth()) - 1
    if gameTime:getDay() > lastDay then gameTime:setDay(lastDay) end

    -- ErosionMain only recomputes the season on its own timer, so nudge it directly
    pcall(function()
        ErosionMain.getInstance():getSeasons():setDay(gameTime:getDay(), gameTime:getMonth(), gameTime:getYear())
    end)

    -- The overlay normally waits for the hourly tick, which a date jump does not trigger
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if system then system:refreshAllOverlays() end

    print(string.format("%syear=%d month=%d day=%d season=%s adopted=%d", PREFIX,
        gameTime:getYear(), gameTime:getMonth(), gameTime:getDay(),
        tostring(getClimateManager():getSeasonName()),
        system and system.system:getObjectCount() or -1))
    describe(tree)
end

-- Adoption and growth ride Events.EveryHours, which a date jump never triggers
local function forceTick(tree)
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if not system then
        print(PREFIX .. "growth system not loaded")
        return
    end

    local before = system.system:getObjectCount()
    Eelt_STreeGrowthSystem.everyHour()
    print(string.format("%sforced tick, adopted %d -> %d", PREFIX,
        before, system.system:getObjectCount()))
    describe(tree)
end

-- A tree is not in worldobjects, only the ground blend is, so reach it through the square
local function findTree(worldobjects)
    for i = 1, worldobjects and #worldobjects or 0 do
        local square = worldobjects[i] and worldobjects[i]:getSquare()
        local tree = square and square:getTree()
        if tree then return tree end
    end
    return nil
end

local function isDebugAllowed(player)
    if isClient() then
        local playerObj = getSpecificPlayer(player)
        return playerObj and playerObj:getRole():hasCapability(Capability.UseDebugContextMenu)
    end
    return isDebugEnabled()
end

local function findSquare(worldobjects)
    for i = 1, worldobjects and #worldobjects or 0 do
        local square = worldobjects[i] and worldobjects[i]:getSquare()
        if square then return square end
    end
    return nil
end

local function describePropagules(worldobjects, playerObj)
    local propagules = EeltsForestryRemastered_Propagules
    local found = 0
    local items = playerObj:getInventory():getItems()
    for i = 0, items and items:size() - 1 or -1 do
        local item = items:get(i)
        if propagules.isPlantable(item) then
            found = found + 1
            local poison = instanceof(item, "Food") and item:getPoisonPower() or 0
            print(string.format("%s%s species=%s poison=%d", PREFIX, item:getFullType(),
                tostring(propagules.getSpecies(item)), poison))
        end
    end
    if found == 0 then print(PREFIX .. "no propagules carried") end
end

local function plantSpecies(worldobjects, playerObj, square, tileset)
    if EeltsForestryRemastered_TreePlanting then
        EeltsForestryRemastered_TreePlanting.plantTree(square, tileset)
        return
    end

    local planting = EeltsForestryRemastered_Planting
    sendClientCommand(playerObj, planting.MODULE, planting.PLANT_COMMAND,
        { x = square:getX(), y = square:getY(), z = square:getZ(), species = tileset })
end

local function addTreeOptions(context, tree)
    local option = context:addOption("Eelt's Forestry Remastered Debuggers", tree, nil)
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, submenu)

    submenu:addOption("Adopt or grow one stage", tree, adoptOrGrow)
    submenu:addOption("Inspect this tree", tree, describe)
    submenu:addOption("Skip one month", tree, skipMonth)
    submenu:addOption("Force a growth tick", tree, forceTick)
end

local function addPlantingOptions(context, worldobjects, playerObj, square)
    local option = context:addOption("Eelt's Forestry Remastered Planting", nil, nil)
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, submenu)

    submenu:addOption("Inspect held propagules", worldobjects, describePropagules, playerObj)

    local speciesOption = submenu:addOption("Plant a species here", nil, nil)
    local speciesMenu = ISContextMenu:getNew(submenu)
    submenu:addSubMenu(speciesOption, speciesMenu)

    for _, tileset in ipairs(EeltsForestryRemastered_TreeGrowthSprites.species) do
        speciesMenu:addOption(EeltsForestryRemastered_Planting.speciesName(tileset),
            worldobjects, plantSpecies, playerObj, square, tileset)
    end
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test or not isDebugAllowed(player) then return end

    local tree = findTree(worldobjects)
    if tree then addTreeOptions(context, tree) end

    local square = findSquare(worldobjects)
    local playerObj = getSpecificPlayer(player)
    if square and playerObj then addPlantingOptions(context, worldobjects, playerObj, square) end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
