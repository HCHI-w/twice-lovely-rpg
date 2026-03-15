# CollectibleManager.gd
# 收藏品管理器
extends Node


var collected := {}   # Dictionary  { id : true }
var new_items := {}   # 記錄 NEW

const SAVE_PATH := "user://collectibles.save"

# ---------------------------------------------------
# 存檔資料
#func _ready():
#	load_data()

# 新增收藏
func add_collectible(data: CollectibleData):
	if collected.has(data.id):
		return
	
	collected[data.id] = true
	new_items[data.id] = true
	save()

# 是否已收集
func has_collectible(id: String) -> bool:
	return collected.has(id)

# 記錄 NEW
func is_new(id:String) -> bool:
	return new_items.has(id)

# 總數量
func clear_new(id:String):
	new_items.erase(id)

func total_collected() -> int:
	return collected.size()

# 存檔
func save():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(collected)

# 讀檔
func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	collected = file.get_var()
