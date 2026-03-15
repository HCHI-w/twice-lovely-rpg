extends RefCounted
class_name Enemy

var data: EnemyData
var current_hp: int
var current_mp: int
var is_alive: bool = true

func _init(d: EnemyData):
	data = d
	current_hp = d.base_hp
	current_mp = d.base_mp
	
func get_hp() -> int: return data.base_hp
func get_mp() -> int: return data.base_mp
func get_str() -> int: return data.base_str
func get_def() -> int: return data.base_def
func get_int() -> int: return data.base_int
func get_dex() -> int: return data.base_dex
func get_luk() -> int: return data.base_luk

# 攻擊力語意（對齊 PartyMember）
func get_physical_attack() -> int:
	return data.base_str * 2

func get_magic_attack() -> int:
	return data.base_int * 2
