extends CampAction
class_name RestAction

@export var heal_percent := 0.3

func execute(party):
	for member in party.members:
		var max_hp = member.get_max_hp()
		member.current_hp = min(
			member.current_hp + int(max_hp * heal_percent),
			max_hp
		)
