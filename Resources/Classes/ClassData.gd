extends Resource
class_name ClassData

@export var class_id: String = ""
@export var display_name: String = ""

#數值修正 (倍率)
@export var hp_multiplier: float = 1.0
@export var mp_multiplier: float = 1.0
@export var str_multiplier: float = 1.0
@export var def_multiplier: float = 1.0
@export var int_multiplier: float = 1.0
@export var dex_multiplier: float = 1.0
@export var luk_multiplier: float = 1.0

@export_multiline var description: String

@export var skill_list: Array[SkillData] = []

#綁定 Buff
@export var camp_buff_ids: Array[String] = []
