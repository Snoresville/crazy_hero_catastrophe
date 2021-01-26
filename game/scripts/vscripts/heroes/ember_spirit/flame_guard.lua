chc_ember_spirit_flame_guard = chc_ember_spirit_flame_guard or class ({})
LinkLuaModifier("modifier_chc_flame_guard_aura", "heroes/ember_spirit/flame_guard", LUA_MODIFIER_MOTION_NONE)

function chc_ember_spirit_flame_guard:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		caster:StartGesture(ACT_DOTA_CAST_ABILITY_3)

		-- Caster version
		caster:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")
		caster:EmitSound("Hero_EmberSpirit.FlameGuard.Loop")
		caster:RemoveModifierByName("modifier_chc_flame_guard_aura")
		caster:AddNewModifier(caster, self, "modifier_chc_flame_guard_aura", {duration = self:GetSpecialValueFor("duration")})
	end
end

-- Flame Guard fire aura
modifier_chc_flame_guard_aura = modifier_chc_flame_guard_aura or class ({})

function modifier_chc_flame_guard_aura:IsDebuff() return false end
function modifier_chc_flame_guard_aura:IsHidden() return false end
function modifier_chc_flame_guard_aura:IsPurgable() return true end

function modifier_chc_flame_guard_aura:GetEffectName()
	return "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf"
end

function modifier_chc_flame_guard_aura:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_chc_flame_guard_aura:OnCreated(keys)
	if IsServer() then
		self.tick_interval = self:GetAbility():GetSpecialValueFor("tick_interval")
		self.damage = self:GetAbility():GetSpecialValueFor("damage") * self.tick_interval
		self.effect_radius = self:GetAbility():GetSpecialValueFor("radius")
		self.remaining_health = self:GetAbility():GetSpecialValueFor("absorb_amount")
		self:StartIntervalThink(self.tick_interval)
	end
end

function modifier_chc_flame_guard_aura:OnDestroy()
	if IsServer() then
		self:GetParent():StopSound("Hero_EmberSpirit.FlameGuard.Loop")
	end
end

function modifier_chc_flame_guard_aura:OnIntervalThink()
	if IsServer() then
		if self.remaining_health <= 0 then
			self:GetParent():RemoveModifierByName("modifier_chc_flame_guard_aura")
		else
			local nearby_enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.effect_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, enemy in pairs(nearby_enemies) do
				ApplyDamage({victim = enemy, attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL})
			end
		end
	end
end

function modifier_chc_flame_guard_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
	}
end

function modifier_chc_flame_guard_aura:GetModifierIncomingSpellDamageConstant(keys)
	if IsServer() then
		if keys.damage_type == DAMAGE_TYPE_MAGICAL then
			local damage = keys.original_damage
			local current_block = self.remaining_health

			self.remaining_health = self.remaining_health - damage

			if self.remaining_health <= 0 then self:Destroy() end

			return current_block
		end
	end
end

function modifier_chc_flame_guard_aura:OnAttackLanded(kv)
	if kv.attacker == self:GetParent() then
		self:IncrementStackCount()
	end
end

function modifier_chc_flame_guard_aura:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("buff_movement_speed") * self:GetStackCount()
end

function modifier_chc_flame_guard_aura:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("buff_attack_speed") * self:GetStackCount()
end

function modifier_chc_flame_guard_aura:GetModifierIgnoreMovespeedLimit()
	return self:GetParent():GetTalentValue("special_bonus_unique_chc_ember_spirit_4")
end