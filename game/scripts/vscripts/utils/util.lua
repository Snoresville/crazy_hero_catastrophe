CHCat:SendGamemodeStatus("utils.lua loaded!")

-- Map Dimensions
local mapSizes = LoadKeyValues("scripts/npc/mapsizes.txt")[GetMapName()]
if mapSizes == nil then
    CHCat:SendGamemodeStatus("Dimensions for " .. GetMapName() .. " cannot be found!")
else
    --for k,v in pairs(mapSizes) do print(k,v) end
    CHCat.map_x = mapSizes["x"]
    CHCat.map_y = mapSizes["y"]
end

-- Spawning
function CHCat:HandleHeroSpawn(hHero)
    local spawnpoint = RandomVector(RandomFloat(0.1, 1))
    spawnpoint.x = spawnpoint.x * self.map_x
    spawnpoint.y = spawnpoint.y * self.map_y
    spawnpoint.z = GetGroundHeight(spawnpoint, hero)

    FindClearSpaceForUnit(hHero, spawnpoint, true)
end

-- Find Talent Value
function CDOTA_BaseNPC:GetTalentValue(sTalentName)
    local talent = self:FindAbilityByName(sTalentName)
    if talent and talent:GetLevel() > 0 then
        return talent:GetSpecialValueFor("value")
    end
    return 0
end