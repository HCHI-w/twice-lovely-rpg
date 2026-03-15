extends Node
class_name Camp

signal camp_entered
signal camp_exited

func enter_camp(party):
	emit_signal("camp_entered", party)
	
func exit_camp():
	emit_signal("camp_exited")
