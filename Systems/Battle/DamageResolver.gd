extends Node
class_name DamageResolver

enum AttackType {
	PHYSICAL, # STR vs DEF
	MAGIC,    # INT vs INT
	TRUE
}

const DAMAGE_VARIANCE := 0.1   # 10% 浮動

static func basic_attack(attacker: Combatant, defender: Combatant, attack_type) -> Dictionary:
	var damage = 0
	
	match attack_type:
		AttackType.PHYSICAL:
			damage = max(1, attacker.get_physical_attack() - defender.get_def())
		AttackType.MAGIC:
			damage = max(1, attacker.get_magic_attack() - defender.get_int())
				
	var is_critical := check_critical(attacker)
	if is_critical:
		var crit_multiplier := 2.0 + attacker.get_luk() * 0.25
		damage *= crit_multiplier
		
	# 浮動在暴擊之後
	damage = apply_variance(damage)
	damage = max(1, damage)
	
	defender.take_damage(damage)
	
	print(
		attacker.get_display_name(),
		" 攻擊 ",
		defender.get_display_name(),
		" 造成 ",
		damage,
		" 傷害 (",
		"CRITICAL " if is_critical else "",
		"PHYSICAL" if attack_type == AttackType.PHYSICAL else "MAGIC",
		")"
	)
	
	return {
		"amount": damage,
		"is_critical": is_critical,
		"type_text": AttackType.keys()[attack_type]
	}
	
# 傷害浮動
static func apply_variance(base_damage: float) -> int:
	var variance := randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
	return int(base_damage * variance)

# 暴擊的數學模型
static func check_critical(attacker: Combatant) -> bool:
	var luk: int = attacker.get_luk()
	var crit_rate: float = luk * 1.0   # 百分比
	var roll: float = randf() * 100.0
	return roll < crit_rate

static func calculate_skill_damage(
	attacker: Combatant,
	_defender: Combatant,
	skill: SkillData
) -> Dictionary:
	
	var base = skill.power
	match skill.attack_type:
		AttackType.PHYSICAL:
			base += attacker.get_str()
		AttackType.MAGIC:
			base += attacker.get_int()
		AttackType.TRUE:
			pass   # 直接使用 base
			
	var is_critical = check_critical(attacker)
	
	var final_damage = base
	if is_critical:
		final_damage *= skill.crit_multiplier
		
	final_damage = apply_variance(final_damage)
	final_damage = max(1, int(final_damage))
		
	return {
		"damage": final_damage,
		"is_critical": is_critical,
		"type_text": AttackType.keys()[skill.attack_type]
	}
