extends RefCounted
class_name BattleAction

var is_essential: bool = false
var damage_type: String = "PHYSICAL"   # 或 "MAGIC"

func execute(_attacker: Combatant, _defender: Combatant) -> Array:
	return []
