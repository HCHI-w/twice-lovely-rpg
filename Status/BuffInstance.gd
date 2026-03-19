extends RefCounted
class_name BuffInstance

var data: BuffData
var remaining_turns: int

#幫Buff記住還剩幾回合
func _init(buff_data: BuffData, turns: int):
	data = buff_data
	remaining_turns = turns

func get_icon():
	return data.buff_icon

func tick():
	remaining_turns -= 1
	
func is_expired() -> bool:
	return remaining_turns <= 0

#Buff重設
func refresh(new_duration: int):
	remaining_turns = new_duration
