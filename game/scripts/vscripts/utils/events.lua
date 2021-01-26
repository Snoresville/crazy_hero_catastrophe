CHCat:SendGamemodeStatus("events.lua loaded!")

function CHCat:InitGameEvents()
    ListenToGameEvent("npc_spawned",        Dynamic_Wrap(CHCat, "OnNPCSpawned"), self)
    ListenToGameEvent("dota_player_killed", Dynamic_Wrap(CHCat, "OnHeroKilled"), self)
end

function CHCat:OnNPCSpawned(keys)
    local npc = EntIndexToHScript(keys.entindex)

    if npc:IsRealHero() then
        self:HandleHeroSpawn(npc)
    end
end

function CHCat:OnHeroKilled(keys)
    local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
	if hero then
		hero:SetTimeUntilRespawn(3)
	end
end