extends Resource
class_name BuffData

@export var buff_id: String
@export var target_class_id: String = ""
@export var name: String
@export var description: String
@export var duration: int = 3

@export var damage_ratio: float = 0.0
@export var prevents_action: bool = false   # 不能行動 → 暈眩
@export var is_damage_over_time: bool = false   # 持續傷害

#純數值，不寫邏輯
@export var stats_flat = {
	"hp": 0,
	"mp": 0,
	"str": 0,
	"def": 0,
	"int": 0,
	"dex": 0,
	"luk": 0
}

@export var stats_percent = {
	"hp": 0.0,
	"mp": 0.0,
	"str": 0.0,
	"def": 0.0,
	"int": 0.0,
	"dex": 0.0,
	"luk": 0.0
}
