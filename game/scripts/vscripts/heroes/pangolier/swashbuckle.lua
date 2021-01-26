chc_pangolier_swashbuckle = chc_pangolier_swashbuckle or class({})
LinkLuaModifier("modifier_chc_swashbuckle_dash", "heroes/pangolier/swashbuckle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chc_swashbuckle_slashes", "heroes/pangolier/swashbuckle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chc_swashbuckle_damage_control", "heroes/pangolier/swashbuckle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chc_swashbuckle_buff", "heroes/pangolier/swashbuckle", LUA_MODIFIER_MOTION_NONE)

function chc_pangolier_swashbuckle:GetVectorTargetRange()
	return self:GetSpecialValueFor("range")
end

function chc_pangolier_swashbuckle:GetCastRange()
	return self:GetSpecialValueFor("dash_range")
end

function chc_pangolier_swashbuckle:OnVectorCastStart(vStartLocation, vDirection)
	-- Ability properties
	local caster = self:GetCaster()
	local ability = self
	local point = vStartLocation
	local sound_cast = "Hero_Pangolier.Swashbuckle.Cast"
	local modifier_movement = "modifier_chc_swashbuckle_dash"

	-- Ability specials
	local dash_range = ability:GetSpecialValueFor("dash_range")
	local range = ability:GetSpecialValueFor("range")

	--Cancel Rolling Thunder if he was rolling
	local rolling_thunder = "modifier_pangolier_gyroshell" --Vanilla
	--local rolling_thunder = "modifier_chc_pangolier_gyroshell_roll" --Imba
	if caster:HasModifier(rolling_thunder) then
		caster:RemoveModifierByName(rolling_thunder)
	end

	-- Turn Pangolier toward the point he will dash (fix targeting for when cast in range AND there are no nearby enemies after dash)
	local direction = (point - caster:GetAbsOrigin()):Normalized()

	caster:SetForwardVector(direction)

	--play animation
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)

	-- Play cast sound
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), sound_cast, caster)

	--Begin moving to target point
    local modifier = caster:AddNewModifier(caster, ability, modifier_movement, {x = point.x, y = point.y, z = point.z})
    modifier.final_direction = vDirection
end

--Dash movement modifier
modifier_chc_swashbuckle_dash = modifier_chc_swashbuckle_dash or class({})

function modifier_chc_swashbuckle_dash:OnCreated(kv)
	--Ability properties
	self.dash_particle = "particles/units/heroes/hero_pangolier/pangolier_swashbuckler_dash.vpcf"
	self.hit_sound = "Hero_Pangolier.Swashbuckle.Damage"

	--Ability specials
	self.dash_speed = self:GetAbility():GetSpecialValueFor("dash_speed")
    self.range = self:GetAbility():GetSpecialValueFor("range")
    self.talent_radius = self:GetAbility():GetSpecialValueFor("start_radius")

	if IsServer() then
		--variables
        self.time_elapsed = 0
        self.target_point = Vector(kv.x, kv.y, kv.z)

		self.distance = (self:GetCaster():GetAbsOrigin() - self.target_point):Length2D()
        self.dash_time = self.distance / self.dash_speed
        self.direction = (self.target_point - self:GetCaster():GetAbsOrigin()):Normalized()

        --Add dash particle
        local dash = ParticleManager:CreateParticle(self.dash_particle, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
        ParticleManager:SetParticleControl(dash, 0, self:GetCaster():GetAbsOrigin()) -- point 0: origin, point 2: sparkles, point 5: burned soil
        ParticleManager:SetParticleControl(dash, 2, self:GetCaster():GetAbsOrigin()) -- point 0: origin, point 2: sparkles, point 5: burned soil
        ParticleManager:SetParticleControl(dash, 5, self:GetCaster():GetAbsOrigin()) -- point 0: origin, point 2: sparkles, point 5: burned soil
        self:AddParticle(dash, false, false, -1, true, false)

        self.frametime = FrameTime()
        self:StartIntervalThink(self.frametime)
	end
end

--pangolier is stunned during the dash
function modifier_chc_swashbuckle_dash:CheckState()
	return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }
end

function modifier_chc_swashbuckle_dash:IsHidden() return true end
function modifier_chc_swashbuckle_dash:IsPurgable() return false end
function modifier_chc_swashbuckle_dash:IsDebuff() return false end
function modifier_chc_swashbuckle_dash:IgnoreTenacity() return true end
function modifier_chc_swashbuckle_dash:IsMotionController() return true end
function modifier_chc_swashbuckle_dash:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end

function modifier_chc_swashbuckle_dash:OnIntervalThink()

	--Talent #1: Enemies in the dash path are applied a basic attack
	if self:GetCaster():GetTalentValue("special_bonus_imba_pangolier_1") then
		self.enemies_hit = self.enemies_hit or {}
		local direction = self:GetCaster():GetForwardVector()
		local caster_loc = self:GetCaster():GetAbsOrigin()
		local target_loc = caster_loc + direction * self.talent_radius

		--Check for enemies in front of pangolier
		local enemies = FindUnitsInLine(self:GetCaster():GetTeamNumber(),
			caster_loc,
			target_loc,
			nil,
			self.talent_radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)

		for _,enemy in pairs(enemies) do
			--Do nothing if the target was hit already
			local already_hit = false
			for k,v in pairs(self.enemies_hit) do

				if v == enemy then
					already_hit = true
					break
				end
			end

			if not already_hit then
				--Play damage sound effect
				EmitSoundOn(self.hit_sound, enemy)

				--can't hit Ethereal enemies
				if not enemy:IsAttackImmune() then
					--Apply the basic attack
					self:GetCaster():PerformAttack(enemy, true, true, true, true, false, false, true)

					table.insert(self.enemies_hit, enemy) --Mark the target as hit
				end
			end

		end
	end

	-- Horizontal motion
	self:HorizontalMotion(self:GetParent(), self.frametime)
end

function modifier_chc_swashbuckle_dash:HorizontalMotion(me, dt)
	if IsServer() then
		-- Check if we're still dashing
		self.time_elapsed = self.time_elapsed + dt
		if self.time_elapsed < self.dash_time then

			-- Go forward
            local new_location = self:GetCaster():GetAbsOrigin() + self.direction * self.dash_speed * dt
            new_location.z = GetGroundHeight(new_location, self:GetCaster())
			self:GetCaster():SetAbsOrigin(new_location)
		else
			self:Destroy()
		end
	end
end

function modifier_chc_swashbuckle_dash:OnRemoved()
	if IsServer() then
        FindClearSpaceForUnit(self:GetCaster(), self:GetCaster():GetAbsOrigin(), true)
        
        --plays the slash animation
        self:GetCaster():SetForwardVector(self.final_direction)
        self:GetCaster():StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
        
        --[[
		--Pangolier finished the dash: look for enemies in range starting from the nearest
		local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(),
			self:GetCaster():GetAbsOrigin(),
			nil,
			self.range,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
			FIND_CLOSEST,
			false)

		--Check if there is an enemy hero in range. In case there is, he will be targeted, otherwise the nearest enemy unit is targeted
		local target_unit = nil
		local target_direction = nil
		if #enemies > 0 then --In case there is no target in range, Pangolier will attack in front of him
			for _,enemy in pairs(enemies) do
				target_unit = target_unit or enemy	--track the nearest unit
				if enemy:IsRealHero() then
					target_unit = enemy
					break
				end
		end
		--Turn Pangolier towards the target
		target_direction = (target_unit:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized()
		self:GetCaster():SetForwardVector(target_direction)
		end

		

		--Add the attack modifier on Pangolier that will handle the slashes

		local attack_modifier_handler = self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), self.attack_modifier, {})

		--pass the target
        attack_modifier_handler.target = target_unit
        ]]
	end
end