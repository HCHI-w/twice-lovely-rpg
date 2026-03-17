# CollectibleDB.gd
extends Node
class_name CollectibleDB

const LIST = [
	preload("res://Data/Collectibles/bread_common.tres"),
	preload("res://Data/Collectibles/bread_rare.tres"),
	preload("res://Data/Collectibles/chocolate_common.tres"),
	preload("res://Data/Collectibles/chocolate_rare.tres"),
	preload("res://Data/Collectibles/fried_chicken_common.tres"),
	preload("res://Data/Collectibles/fried_chicken_rare.tres"),
	preload("res://Data/Collectibles/gummy_bear_common.tres"),
	preload("res://Data/Collectibles/gummy_bear_rare.tres"),
	preload("res://Data/Collectibles/jokbal_common.tres"),
	preload("res://Data/Collectibles/jokbal_rare.tres"),
	preload("res://Data/Collectibles/ketchup_common.tres"),
	preload("res://Data/Collectibles/ketchup_rare.tres"),
	preload("res://Data/Collectibles/spicy_beef_common.tres"),
	preload("res://Data/Collectibles/spicy_beef_rare.tres"),
	preload("res://Data/Collectibles/yogurt_common.tres"),
	preload("res://Data/Collectibles/yogurt_rare.tres")
]


func _ready() -> void:
	pass # Replace with function body.
