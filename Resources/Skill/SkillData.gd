extends Resource
class_name SkillData

enum EffectType {
	DAMAGE = 0,
	HEAL = 1,
	REVIVE = 2,
	BUFF = 3
}

@export var attack_type: int = DamageResolver.AttackType.PHYSICAL
@export var effect_type: int = EffectType.DAMAGE

@export var skill_name: String
@export var mp_cost: int = 0
@export var power: int = 0
@export var target_type: String = "single_enemy"   # 單體或全體
@export var crit_multiplier: float = 1.5
@export var revive_percent: float = 0.3

@export_range(0, 1) var effect_chance: float = 1.0  # 預設 100% 成功

@export_multiline var description: String

#Buff 專用
@export var buff_data: BuffData
@export var buff_turns: int = 0
