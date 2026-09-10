require "TimedActions/ISBaseTimedAction"
require "EeltsForestryRemastered_Planting"

Eelt_PlantTreeAction = ISBaseTimedAction:derive("Eelt_PlantTreeAction")

function Eelt_PlantTreeAction:isValid()
    local planting = EeltsForestryRemastered_Planting
    if not planting.isPlantableSquare(self.gridSquare) then return false end
    if not self.character:getInventory():containsID(self.propagule:getID()) then return false end
    return planting.isPlantableItem(self.propagule)
end

function Eelt_PlantTreeAction:waitToStart()
    self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    return self.character:isTurning() or self.character:shouldBeTurning()
end

function Eelt_PlantTreeAction:update()
    self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    self.tool:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.DiggingSpade)
end

function Eelt_PlantTreeAction:start()
    if isClient() then
        self.tool = self.character:getInventory():getItemById(self.tool:getID())
        self.propagule = self.character:getInventory():getItemById(self.propagule:getID())
    end

    self.tool:setJobType(getText("ContextMenu_Eelt_PlantTree"))
    self.tool:setJobDelta(0.0)
    self.sound = self.character:playSound("DigFurrowWithShovel")
    addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)

    self:setActionAnim(BuildingHelper.getShovelAnim(self.tool))
    self:setOverrideHandModels(self.tool:getStaticModel(), nil)
end

function Eelt_PlantTreeAction:stop()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
    self.tool:setJobDelta(0.0)
end

function Eelt_PlantTreeAction:perform()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
    self.tool:setJobDelta(0.0)

    local planting = EeltsForestryRemastered_Planting
    local square = self.gridSquare

    -- Rolled here rather than at menu time, so an unmarked propagule reads the square it lands on
    local species = EeltsForestryRemastered_Propagules.speciesFor(self.propagule, square:getX(), square:getY())
    self.character:getInventory():Remove(self.propagule)

    if species then
        local args = { x = square:getX(), y = square:getY(), z = square:getZ(), species = species }
        if isClient() then
            sendClientCommand(self.character, planting.MODULE, planting.PLANT_COMMAND, args)
        else
            EeltsForestryRemastered_TreePlanting.plantTree(square, species)
        end
    end

    ISBaseTimedAction.perform(self)
end

function Eelt_PlantTreeAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 200
end

function Eelt_PlantTreeAction:new(character, gridSquare, propagule, tool)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.gridSquare = gridSquare
    o.propagule = propagule
    o.tool = tool
    o.maxTime = o:getDuration()
    o.caloriesModifier = 5
    return o
end
