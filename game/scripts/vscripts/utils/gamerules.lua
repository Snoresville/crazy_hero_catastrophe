CHCat:SendGamemodeStatus("gamerules.lua loaded!")

function CHCat:InitGameRules()
    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetCustomGameSetupAutoLaunchDelay(5)
    GameRules:SetPreGameTime(10)
    GameRules:SetSameHeroSelectionEnabled(true)

end