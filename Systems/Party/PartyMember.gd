extends RefCounted
class_name PartyMember

var character_data: CharacterData
var class_data: ClassData

var level: int = 1
var current_hp: int
var current_mp: int

# Buff 系統
var active_buffs: Array[BuffData] = []

#長期狀態
var fatigue: int = 0
var stress: int = 0

# ---------------------------------------------------
func _init(c_data: CharacterData, c_class: ClassData):
	character_data = c_data
	class_data = c_class
	current_hp = get_max_hp()
	current_mp = get_max_mp()

# ---------------------------------------------------
func get_max_hp() -> int:
	var base = int(character_data.base_hp * class_data.hp_multiplier)
	
	for buff in active_buffs:
		base += buff.stats_flat.hp
	
	return base
	
func get_max_mp() -> int:
	var base = int(character_data.base_mp * class_data.mp_multiplier)
	
	for buff in active_buffs:
		base += buff.stats_flat.mp
	
	return base
	
func get_final_str() -> int:
	var base = int(character_data.base_str * class_data.str_multiplier)
	
	for buff in active_buffs:
		base += buff.stats_flat.str
	
	return base
	
func get_final_def() -> int:
	var base = int(character_data.base_def * class_data.def_multiplier)
	
	for buff in active_buffs:
		base += buff.stats_flat.def
	
	return base
	
func get_final_int() -> int:
	var base = int(character_data.base_int * class_data.int_multiplier)
	
	for buff in active_buffs:
		base += buff.stats_flat.int
	
	return base
	
func get_final_dex() -> int:
	var base = int(character_data.base_dex * class_data.dex_multiplier)
	
	for buff in active_buffs:
		base += buff.stats_flat.dex
	
	return base
	
func get_final_luk() -> int:
	var base = int(character_data.base_luk * class_data.luk_multiplier)
	
	for buff in active_buffs:
		base += buff.stats_flat.luk
	
	return base

# ---------------------------------------------------
func init_runtime_status():
	current_hp = get_max_hp()
	fatigue = 0

func heal(amount: int):
	current_hp = min(current_hp + amount, get_max_hp())

# ---------------------------------------------------
func get_physical_attack() -> int:
	var base = get_final_str()
	return base * 2

func get_magic_attack() -> int:
	var base = get_final_int()
	return base * 2

# ---------------------------------------------------
# 營地 Buff
func add_buff(buff: BuffData):
	active_buffs.append(buff)

func clear_buffs():
	active_buffs.clear()

# ---------------------------------------------------
