# WindowManager.gd
# 自動偵測平台並決定是否鎖定視窗大小
extends Node


# 定義設計基準與最大限制
const MAX_LANDSCAPE = Vector2(1280, 720)
const MAX_PORTRAIT = Vector2(720, 1280)

# ---------------------------------------------------
func _ready() -> void:
	# 監聽視窗變化
	get_tree().root.size_changed.connect(_on_window_resized)
	
	# 初始執行一次限制邏輯
	_apply_window_constraints()


func _on_window_resized() -> void:
	_apply_window_constraints()


func _apply_window_constraints() -> void:
	var current_size = DisplayServer.window_get_size()
	var is_portrait = current_size.y > current_size.x
	
	# 針對 PC 平台 的視窗大小限制
	var platform = OS.get_name()
	if platform == "Windows" or platform == "macOS" or platform == "FreeBSD" or platform == "NetBSD" or platform == "OpenBSD" or platform == "BSD":
		_limit_pc_window(current_size, is_portrait)
	
	# 針對手機平台 (Android, iOS) 的 Safe Area 處理
	# 手機端通常無法改變視窗大小，但我們可以確保內容不會超出太多
	elif platform == "Android" or platform == "iOS":
		_handle_mobile_constraints()


# ---------------------------------------------------
# PC 視窗限制邏輯
func _limit_pc_window(current_size: Vector2, is_portrait: bool) -> void:
	var target_max = MAX_PORTRAIT if is_portrait else MAX_LANDSCAPE
	
	# 如果玩家把視窗拉得比最大限制還大，就強制縮回
	if current_size.x > target_max.x or current_size.y > target_max.y:
		# 這裡使用螢幕比例計算，避免變形
		var scale = min(target_max.x / current_size.x, target_max.y / current_size.y)
		var new_size = current_size * scale
		
		# 為了避免無窮迴圈，只有在差距明顯時才強制設定
		if current_size.distance_to(new_size) > 10:
			DisplayServer.window_set_size(new_size)
			# 讓視窗置中 (可選)
			# var screen_size = DisplayServer.screen_get_size()
			# DisplayServer.window_set_position((screen_size / 2) - (new_size / 2))


# 手機端限制 (用來確保 UI 不會跑掉)
func _handle_mobile_constraints() -> void:
	# 手機端主要依賴 Project Settings 裡的 Stretch Mode = canvas_items
	# 這裡可以加入一些全域的縮放補償邏輯
	pass

# ---------------------------------------------------
