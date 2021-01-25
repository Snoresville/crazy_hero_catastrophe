if CHCat == nil then
	_G.CHCat = class({})
end

CHCat.required_modules = {
	"utils/gamerules",
	"utils/util",
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
	print( "[CHCat] Addon has been initialised!" )

	print( "[CHCat] Finding Modules..." )
	for _,module in pairs(self.required_modules) do
		require(module)
	end
end