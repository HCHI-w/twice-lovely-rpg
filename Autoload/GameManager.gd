# GameManager.gd
extends Node


# 角色資料庫（所有可用角色）
var character_database: Array = []

# 保存隊伍
var party: Party = null

# ---------------------------------------------------
# 收藏品倉庫
var collection: Dictionary = {}

# ---------------------------------------------------
func add_collectible(item: CollectibleData):
	if item == null:
		return
		
	if collection.has(item.id):
		collection[item.id] += 1
	else:
		collection[item.id] = 1
		
	print("獲得收藏品:", item.display_name)

# ---------------------------------------------------
