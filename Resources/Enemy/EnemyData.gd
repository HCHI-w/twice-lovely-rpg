extends Resource
class_name EnemyData

@export var enemy_id: String
@export var name: String

@export var base_hp: int = 500
@export var base_mp: int = 50
@export var base_str: int = 30
@export var base_def: int = 30
@export var base_int: int = 30
@export var base_dex: int = 30
@export var base_luk: int = 30

@export var skill_list: Array[SkillData] = []

@export var battle_texture: Texture2D

# 收藏品掉落
@export var drop_common: CollectibleData
@export var drop_rare: CollectibleData
