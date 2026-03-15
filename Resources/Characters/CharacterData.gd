extends Resource
class_name CharacterData

@export var id: String
@export var display_name: String

@export var base_hp: int = 100
@export var base_mp: int = 20
@export var base_str: int = 10
@export var base_def: int = 10
@export var base_int: int = 10
@export var base_dex: int = 10
@export var base_luk: int = 10
@export var battle_texture: Texture2D
@export var character_icon: Texture2D

@export_multiline var description: String

# 讓每個角色資料都能掛載自己的「底片捲」
@export var camp_animations: SpriteFrames

# ---------------------------------------------------
func get_physical_attack() -> int:
	return base_str * 2

func get_magic_attack() -> int:
	return base_int * 2
