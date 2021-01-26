CHCat:SendGamemodeStatus("gamerules.lua loaded!")

function CHCat:InitGameRules()
    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetCustomGameSetupAutoLaunchDelay(5)
    GameRules:SetPreGameTime(5)
    GameRules:SetSameHeroSelectionEnabled(true)
    
end