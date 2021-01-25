CHCat:SendGamemodeStatus("events.lua loaded!")

function CHCat:InitGameEvents()
    ListenToGameEvent("npc_spawned",    Dynamic_Wrap(CHCat, "OnNPCSpawned"), self)
end

function CHCat:OnNPCSpawned(keys)
    local npc = EntIndexToHScript(keys.entindex)

    if npc:IsRealHero() then
        self:HandleHeroSpawn(npc)
    end
end