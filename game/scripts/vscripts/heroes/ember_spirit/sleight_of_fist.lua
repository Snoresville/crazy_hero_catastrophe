-- Sleight of Fist ability
chc_ember_spirit_sleight_of_fist = chc_ember_spirit_sleight_of_fist or class ({})
LinkLuaModifier("modifier_chc_sleight_of_fist_marker", "heroes/ember_spirit/sleight_of_fist", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chc_sleight_of_fist_caster", "heroes/ember_spirit/sleight_of_fist", LUA_MODIFIER_MOTION_NONE)

function chc_ember_spirit_sleight_of_fist:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

-- This should realistically never be called, but you never know with script errors...
function chc_ember_spirit_sleight_of_fist:OnOwnerDied()
	if not self:IsActivated() then
		self:SetActivated(true)
	end
end

function chc_ember_spirit_sleight_of_fist:CollectTargets(vLocation)
    local caster = self:GetCaster()
    local effect_radius = self:GetSpecialValueFor("radius")
    local attack_interval = self:GetSpecialValueFor("attack_interval") * caster:GetAttacksPerSecond()
    self.targets = self.targets or {}

    -- Play primary cast sound/particle
    caster:EmitSound("Hero_EmberSpirit.SleightOfFist.Cast")
    local cast_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleight_of_fist_cast.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(cast_pfx, 0, vLocation)
    ParticleManager:SetParticleControl(cast_pfx, 1, Vector(effect_radius, 1, 1))
    ParticleManager:ReleaseParticleIndex(cast_pfx)
        
    -- Mark targets to hit
    local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), target_loc, nil, effect_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
    for _, enemy in pairs(nearby_enemies) do
        self.targets[#self.targets + 1] = enemy:GetEntityIndex()
        enemy:AddNewModifier(caster, self, "modifier_chc_sleight_of_fist_marker", {duration = (#sleight_targets - 1) * attack_interval})
    end
end

function chc_ember_spirit_sleight_of_fist:OnSpellStart()
    if IsClient() then return end
    
    local caster = self:GetCaster()
    local target_loc = self:GetCursorPosition()
    local attack_count = self:GetSpecialValueFor("attacks_per_target")

    for i = 1,attack_count do
        self:CollectTargets(target_loc)
    end

    if self.targets >= 1 and not caster:HasModifier("modifier_chc_sleight_of_fist_caster") then
        caster:AddNewModifier(caster, self, "modifier_chc_sleight_of_fist_caster", {})
    end
end

-- Sleight of Fist target marker
modifier_chc_sleight_of_fist_marker = modifier_chc_sleight_of_fist_marker or class ({})

function modifier_chc_sleight_of_fist_marker:IsDebuff() return true end
function modifier_chc_sleight_of_fist_marker:IsHidden() return true end
function modifier_chc_sleight_of_fist_marker:IsPurgable() return false end

function modifier_chc_sleight_of_fist_marker:GetEffectName()
	return "particles/units/heroes/hero_ember_spirit/ember_spirit_sleight_of_fist_targetted_marker.vpcf"
end

function modifier_chc_sleight_of_fist_marker:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

-- Sleight of Fist caster modifier
modifier_chc_sleight_of_fist_caster = modifier_chc_sleight_of_fist_caster or class ({})

function modifier_chc_sleight_of_fist_caster:IsPurgable() return false end
function modifier_chc_sleight_of_fist_caster:OnCreated()
	if IsServer() then
		-- The particles will properly attach if PATTACH_CUSTOMORIGIN is used instead of PATTACH_WORLDORIGIN, but there is a whole other subset of issues concerning invisible particles if the caster goes invisible or out of sight so this may be the lesser of two evils for now...
        self.starting_position = self:GetParent():GetAbsOrigin()
        self.attack_interval = self:GetAbility():GetSpecialValueFor("attack_interval") * self:GetCaster():GetAttacksPerSecond()
        self.sleight_caster_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleight_of_fist_caster.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
		ParticleManager:SetParticleControl(self.sleight_caster_particle, 0, self.starting_position)
		ParticleManager:SetParticleControlForward(self.sleight_caster_particle, 1, self:GetCaster():GetForwardVector())
		
		self:GetParent():AddNoDraw()
        self:GetAbility():SetActivated(false)
        self:OnIntervalThink()
	end
end

function modifier_chc_sleight_of_fist_caster:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.sleight_caster_particle, false)
		ParticleManager:ReleaseParticleIndex(self.sleight_caster_particle)
	
		self:GetParent():RemoveNoDraw()
		self:GetAbility():SetActivated(true)
	end
end

function modifier_chc_sleight_of_fist_caster:CheckState()
	if IsServer() then
		local state = {
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_ATTACK_IMMUNE] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true,
			--[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_UNSELECTABLE] = true,
			[MODIFIER_STATE_DISARMED] = true
		}

		return state
	end
end

function modifier_chc_sleight_of_fist_caster:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE
	}

	return funcs
end

function modifier_chc_sleight_of_fist_caster:GetModifierPreAttack_BonusDamage(keys)
	if keys.target and keys.target:IsHero() then
		return self:GetAbility():GetSpecialValueFor("bonus_damage")
	end
end

function modifier_chc_sleight_of_fist_caster:GetModifierIgnoreCastAngle()
	return 1
end

function modifier_chc_sleight_of_fist_caster:OnIntervalThink()
    if #sleight_targets <= 0 then
        self:Destroy()
    end

    local current_target
    for i = 1, #self:GetAbility().targets do
        local target = self:GetAbility().targets[1]
        if target and not target:IsNull() and target:IsAlive() and not target:IsInvisible() and not target:IsAttackImmune() then
            current_target = target
        else
            table.remove(self:GetAbility().targets, 1)
        end
    end

    if current_target then
        local previous_position = self:GetParent():GetAbsOrigin()
        local original_direction = (current_target:GetAbsOrigin() - previous_position):Normalized()

        -- Particles and sound
        caster:EmitSound("Hero_EmberSpirit.SleightOfFist.Damage")
        local slash_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, current_target)
        ParticleManager:SetParticleControl(slash_pfx, 0, current_target:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(slash_pfx)

        local trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(trail_pfx, 0, current_target:GetAbsOrigin())
        ParticleManager:SetParticleControl(trail_pfx, 1, previous_position)
        ParticleManager:ReleaseParticleIndex(trail_pfx)

        -- Perform the attack
        caster:SetAbsOrigin(current_target:GetAbsOrigin() + original_direction * 50)
        caster:PerformAttack(current_target, true, true, true, false, false, false, false)
    end

    self:StartIntervalThink(-1)
    self:StartIntervalThink(self.attack_interval)
end

function modifier_chc_sleight_of_fist_caster:OnRemoved()
    self:GetParent():RemoveNoDraw()
    self:GetAbility():SetActivated(true)
    FindClearSpaceForUnit(self:GetParent(), self.starting_position, true)
end