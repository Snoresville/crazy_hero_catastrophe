CHCat:SendGamemodeStatus("gamerules.lua loaded!")

function CHCat:InitGameRules()
    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetCustomGameSetupAutoLaunchDelay(5)
    GameRules:SetPreGameTime(10)
    GameRules:SetSameHeroSelectionEnabled(true)


    local gamemode = GameRules:GetGameModeEntity()
    
    gamemode:SetBuybackEnabled(false)
    gamemode:SetMaximumAttackSpeed(2000)
end