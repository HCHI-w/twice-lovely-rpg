extends BattleAction
class_name PhysicalAttackAction

func execute(attacker: Combatant, defender: Combatant) -> Array:
	var results = []
	if defender == null:
		return results
		
	var damage = DamageResolver.basic_attack(
		attacker,
		defender,
		DamageResolver.AttackType.PHYSICAL
	)
	
	results.append({
		"target": defender,
		"amount": damage["amount"],
		"is_critical": damage["is_critical"],
		"damage_type": damage["type_text"],
		"is_heal": false
	})
	
	# basic_attack 回傳傷害
	return results
