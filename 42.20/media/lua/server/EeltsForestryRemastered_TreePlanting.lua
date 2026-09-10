if isClient() then return end

require "EeltsForestryRemastered_Planting"
require "EeltsForestryRemastered_TreeGrowthSprites"

EeltsForestryRemastered_TreePlanting = {}

local server = EeltsForestryRemastered_TreePlanting

local MAX_PLANT_DISTANCE = 3

local function isKnownSpecies(tileset)
    return EeltsForestryRemastered_TreeGrowthSprites.getBase(tileset, 0) ~= nil
end

function server.plantTree(square, tileset)
    local planting = EeltsForestryRemastered_Planting
    if not planting.isPlantableSquare(square) or not isKnownSpecies(tileset) then return nil end

    local sprite = getSprite(EeltsForestryRemastered_TreeGrowthSprites.getBase(tileset, 0))
    if not sprite then return nil end

    local tree = IsoTree.new(square, sprite)
    square:AddTileObject(tree)
    if isServer() then tree:transmitCompleteItemToClients() end
    triggerEvent("OnObjectAdded", tree)

    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if system then system:adoptPlantedTree(square, tree, tileset) end

    square:RecalcAllWithNeighbours(true)
    return tree
end

-- The client picks the species when the propagule carries none, and the square can change
-- while the action runs, so neither is taken on trust
local function onClientCommand(module, command, player, args)
    local planting = EeltsForestryRemastered_Planting
    if module ~= planting.MODULE or command ~= planting.PLANT_COMMAND then return end
    if not player or not args then return end
    if not planting.knowsPlanting(player) then return end

    local square = getCell():getGridSquare(args.x, args.y, args.z)
    if not square or square:DistToProper(player:getCurrentSquare()) > MAX_PLANT_DISTANCE then return end

    server.plantTree(square, args.species)
end

Events.OnClientCommand.Add(onClientCommand)
