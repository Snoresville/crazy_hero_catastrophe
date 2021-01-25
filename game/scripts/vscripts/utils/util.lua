SendGamemodeStatus("utils.lua loaded!")

function SendGamemodeStatus(message)
    print("[CHCat] " .. message)
end

local mapSizes = LoadKeyValues("scripts/npc/mapsizes.txt")[GetMapName()]
if mapSizes == nil then
    SendGamemodeStatus("Dimensions for " .. GetMapName() .. " cannot be found!")
else
    for k,v in pairs(mapSizes) do print(k,v) end
end
