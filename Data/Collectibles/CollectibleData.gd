# 收藏品資料
extends Resource
class_name CollectibleData

@export var id: String
@export var display_name: String
@export var description: String     # 存放文字說明
@export var icon: Texture2D

@export var rarity: String = "Common"
