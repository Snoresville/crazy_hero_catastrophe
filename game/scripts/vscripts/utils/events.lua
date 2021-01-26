CHCat:SendGamemodeStatus("events.lua loaded!")

function CHCat:InitGameEvents()
    ListenToGameEvent("dota_player_spawned",        Dynamic_Wrap(CHCat, "OnNPCSpawned"), self)
    ListenToGameEvent("dota_player_killed", Dynamic_Wrap(CHCat, "OnHeroKilled"), self)
end

function CHCat:OnNPCSpawned(keys)
    local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)

    if hero:IsRealHero() then
        self:HandleHeroSpawn(hero)
    end
end

function CHCat:OnHeroKilled(keys)
    local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
	if hero then
		hero:SetTimeUntilRespawn(3)
	end
end