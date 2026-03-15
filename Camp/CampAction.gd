extends Resource
class_name CampAction

@export var action_name: String
@export var description: String

func can_use(_party) -> bool:
	return true

func execute(_party):
	pass
