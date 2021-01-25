if CHCat == nil then
	_G.CHCat = class({})
end
function CHCat:SendGamemodeStatus(message)
    print("[CHCat] " .. message)
end

CHCat.required_modules = {
	"utils/gamerules",
	"utils/util",
	"utils/events",
}

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate
function Activate()
	GameRules.GameMode = CHCat()
	GameRules.GameMode:InitGameMode()
end

function CHCat:InitGameMode()
	CHCat:SendGamemodeStatus("Addon has been initialised!" )

	CHCat:SendGamemodeStatus("Finding Modules..." )
	for _,module in pairs(self.required_modules) do
		require(module)
	end

	if IsServer() then
		self:InitGameRules()
		self:InitGameEvents()
	end
end