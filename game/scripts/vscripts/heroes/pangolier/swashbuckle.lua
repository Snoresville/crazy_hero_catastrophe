chc_pangolier_swashbuckle = chc_pangolier_swashbuckle or class({})
LinkLuaModifier("modifier_chc_swashbuckle_dash", "heroes/pangolier/swashbuckle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chc_swashbuckle_slashes", "heroes/pangolier/swashbuckle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chc_swashbuckle_hit", "heroes/pangolier/swashbuckle", LUA_MODIFIER_MOTION_NONE)

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

function chc_pangolier_swashbuckle:PerformSlash(clearParticles, vDirection)
    if vDirection == nil then vDirection = self:GetCaster():GetForwardVector() end
    self.particles = self.particles or {}

    local caster = self:GetCaster()
    local startPos = caster:GetAbsOrigin()
    local endPos = startPos + vDirection * self:GetSpecialValueFor("range")
    local width = self:GetSpecialValueFor("start_radius")

    --play slashing particle
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pangolier/pangolier_swashbuckler.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin()) --origin of particle
    ParticleManager:SetParticleControl(particle, 1, vDirection * self:GetSpecialValueFor("range")) --direction and range of the subparticles
    table.insert(self.particles, particle)

    --plays the attack sound
    EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Pangolier.Swashbuckle", caster)
    
    local enemies = FindUnitsInLine(caster:GetTeamNumber(), startPos, endPos, nil, width, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE)

    for i = 1,#enemies do
        enemies[i]:AddNewModifier(caster, self, "modifier_chc_swashbuckle_hit", {duration = i * 0.01})
    end

    if clearParticles then
        for k,v in pairs(self.particles) do
			ParticleManager:DestroyParticle(v, false)
			ParticleManager:ReleaseParticleIndex(v)
		end
    end
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
        self.strike_count = kv.strike_count or self:GetAbility():GetSpecialValueFor("strikes")

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

function modifier_chc_swashbuckle_dash:OnIntervalThink()

	--Talent #1: Enemies in the dash path are applied a basic attack
	if self:GetCaster():GetTalentValue("special_bonus_unique_chc_pangolier") == 1 then
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
        
        self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_chc_swashbuckle_slashes", {stacks = self.strike_count})
	end
end

--attack modifier: will handle the slashes
modifier_chc_swashbuckle_slashes = modifier_chc_swashbuckle_slashes or class({})
function modifier_chc_swashbuckle_slashes:IsHidden() return true end

function modifier_chc_swashbuckle_slashes:OnCreated(kv)
    if IsServer() then
        self:SetStackCount(kv.stacks)
        self:OnIntervalThink()
    end
end

function modifier_chc_swashbuckle_slashes:DeclareFunctions()
	local declfuncs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }

	return declfuncs
end

function modifier_chc_swashbuckle_slashes:CheckState()
	local state = {
        [MODIFIER_STATE_STUNNED] = true
    }

    return state
end

function modifier_chc_swashbuckle_slashes:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_1_END
end

function modifier_chc_swashbuckle_slashes:OnIntervalThink()
	if IsServer() then
        self:GetAbility():PerformSlash(self:GetStackCount() == 1)
        self:DecrementStackCount()

        if self:GetStackCount() <= 0 then self:Destroy() end
        self:StartIntervalThink(0.1)
	end
end

--attack modifier: will handle the slashes
modifier_chc_swashbuckle_hit = modifier_chc_swashbuckle_hit or class({})
function modifier_chc_swashbuckle_hit:IsHidden() return true end
function modifier_chc_swashbuckle_hit:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_chc_swashbuckle_hit:OnRemoved()
    if IsClient() then return end

    local enemy = self:GetParent()
    self:GetCaster():PerformAttack(enemy, true, true, true, true, false, false, true)
    enemy:EmitSound("Hero_Pangolier.Swashbuckle.Damage")

    --Play blood particle on targets
    local blood_particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_blood.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(blood_particle, 0, enemy:GetAbsOrigin()) --origin of particle
    ParticleManager:SetParticleControl(blood_particle, 2, (enemy:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized() * 500) --direction and speed of the blood spills
    ParticleManager:ReleaseParticleIndex(blood_particle)
end