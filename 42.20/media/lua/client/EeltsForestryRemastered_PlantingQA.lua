if not isDebugEnabled() or isClient() then return end

require "EeltsForestryRemastered_Planting"

local PREFIX = "Eelt's Forestry Remastered: QA "
local CHECKPOINT = "Eelt_QATreeCheckpoint"
local snapshots = {}

local function enabled()
    return isDebugEnabled() and not isClient()
end

local function report(message)
    print(PREFIX .. message)
end

local function squareKey(square)
    return square:getX() .. ":" .. square:getY() .. ":" .. square:getZ()
end

local function snapshot(square)
    local items = {}
    local objects = square:getWorldObjects()
    for i = 0, objects and objects:size() - 1 or -1 do
        local item = objects:get(i):getItem()
        if item then items[item:getID()] = item:getFullType() end
    end
    return items
end

local function rememberDrops(square)
    if not enabled() then return end
    snapshots[squareKey(square)] = snapshot(square)
    report("drop snapshot at " .. squareKey(square))
end

local function inspectDrops(square)
    if not enabled() then return end
    local before = snapshots[squareKey(square)]
    local counts = {}
    local objects = square:getWorldObjects()
    for i = 0, objects and objects:size() - 1 or -1 do
        local item = objects:get(i):getItem()
        if item then
            local prior = before and before[item:getID()] ~= nil
            local kind = item:getFullType()
            if not prior then counts[kind] = (counts[kind] or 0) + 1 end
            if EeltsForestryRemastered_Propagules.isPlantable(item) then
                report(string.format("item=%s id=%s prior=%s species=%s", kind,
                    tostring(item:getID()), tostring(prior),
                    tostring(EeltsForestryRemastered_Propagules.getSpecies(item))))
            end
        end
    end
    report("drops at " .. squareKey(square) .. " baseline=" .. tostring(before ~= nil))
    for kind, count in pairs(counts) do report(kind .. "=" .. count) end
end

local function giveKit(player)
    if not enabled() then return end
    local inventory = player:getInventory()
    for _, kind in ipairs({ "Base.Axe", "Base.Shovel", "Base.Sapling", "Base.Pinecone", "Base.HollyBerry" }) do
        inventory:AddItem(kind)
    end
    local berry = inventory:AddItem("Base.HollyBerry")
    berry:setPoisonPower(10)
    report("added QA tools and propagules, including one poisoned berry; tape knowledge unchanged")
end

local function spawnTree(square, tileset)
    if not enabled() or not EeltsForestryRemastered_Planting.isPlantableSquare(square) then return end
    local name = EeltsForestryRemastered_TreeGrowthSprites.getBase(tileset, 6)
    local tree = IsoTree.new(square, getSprite(name))
    square:AddTileObject(tree)
    triggerEvent("OnObjectAdded", tree)
    square:RecalcAllWithNeighbours(true)
    square:AddWorldInventoryItem("Base.Sapling", 0, 0, 0)
    rememberDrops(square)
    report("wild fixture=" .. tileset .. " stage=6 logs=" .. tree:getLogYield()
        .. "; one pre-existing unstamped sapling included")
end

local function inspectTree(square, player, save)
    if not enabled() then return end
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    local object = system and system:getLuaObjectOnSquare(square)
    if not object then report("no adopted tree at " .. squareKey(square)); return end
    report(string.format("tree=%s species=%s stage=%s planted=%s enteredHour=%s mode=%s",
        squareKey(square), tostring(object.tileset), tostring(object.stage),
        tostring(object.planted), tostring(object.enteredHour), tostring(system:getMode())))
    if save then
        player:getModData()[CHECKPOINT] = {
            x = square:getX(), y = square:getY(), z = square:getZ(),
            tileset = object.tileset, stage = object.stage, planted = object.planted,
            enteredHour = object.enteredHour,
        }
        report("checkpoint saved on character; save and reload before comparing")
    end
end

local function compareCheckpoint(player)
    if not enabled() then return end
    local old = player:getModData()[CHECKPOINT]
    if not old then report("no checkpoint recorded"); return end
    local square = getCell():getGridSquare(old.x, old.y, old.z)
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    local object = system and square and system:getLuaObjectOnSquare(square)
    if not object then report("checkpoint tree missing or unloaded"); return end
    local same = object.tileset == old.tileset and object.stage == old.stage
        and object.planted == old.planted and object.enteredHour == old.enteredHour
    report("checkpoint matches=" .. tostring(same))
    inspectTree(square, player, false)
end

local function ageTree(square)
    if not enabled() then return end
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    local object = system and system:getLuaObjectOnSquare(square)
    if not object then report("no adopted tree to age"); return end
    local before = object.stage
    object.enteredHour = getGameTime():getWorldAgeHours() - system:getHoursPerStage() - 1
    Eelt_STreeGrowthSystem.everyHour()
    report("elapsed-time tick stage=" .. before .. " -> " .. object.stage
        .. " planted=" .. tostring(object.planted) .. " mode=" .. system:getMode())
end

local function addMenu(playerNumber, context, worldobjects, test)
    if test or not enabled() then return end
    local player = getSpecificPlayer(playerNumber)
    local square = worldobjects[1] and worldobjects[1]:getSquare()
    if not player or not square then return end
    local option = context:addOption("Forestry QA (debug, single player)", nil, nil)
    local menu = ISContextMenu:getNew(context)
    context:addSubMenu(option, menu)
    menu:addOption("Add QA tools and propagules", player, giveKit)
    menu:addOption("Snapshot ground items before chopping", square, rememberDrops)
    menu:addOption("Report new drops and species", square, inspectDrops)
    menu:addOption("Inspect tree and save checkpoint", square, inspectTree, player, true)
    menu:addOption("Compare saved tree checkpoint", player, compareCheckpoint)
    menu:addOption("Age this tree one interval and run growth tick", square, ageTree)
    for _, tileset in ipairs({ "e_virginiapine_1", "e_canadianhemlock_1", "e_americanholly_1", "e_redmaple_1" }) do
        menu:addOption("Place stage 6 " .. EeltsForestryRemastered_Planting.speciesName(tileset),
            square, spawnTree, tileset)
    end
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)
