extends CampAction
class_name CampBuffAction

@export var buff_id: String
@export var required_class: String = ""

func can_use(party) -> bool:
	if required_class == "":
		return true
	return party.has_class(required_class)

func execute(party):
	var buff = BuffRegistry.get_buff(buff_id)
	if buff == null:
		return
		
	var applied := false
	for member in party.members:
		if member.add_buff(buff):
			applied = true
			
	if not applied:
		print("No one benefited from buff:", buff_id)

#回營地回滿 MP
func rest_all_party(party: Array[Combatant]):
	for c in party:
		c.restore_mp()
