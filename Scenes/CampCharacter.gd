extends CharacterBody2D
class_name CampCharacter


signal clicked(character_data)

var character_data
# 對話氣泡
var bubble_scene = preload("res://Scenes/DialogueBubble.tscn")
var current_bubble = null

# 拿到新的動畫節點
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

# 營地角色統一尺寸
#const CAMP_CHARACTER_SCALE := 0.85

# ---------------------------------------------------
func _ready():
	# 確保 Area2D 可以偵測點擊，並連接內建訊號
	area_2d.input_event.connect(_on_area_2d_input_event)

# ---------------------------------------------------
# 由 CampScene 呼叫此函式
func setup(data):
	character_data = data
	
	# 檢查這個角色資料有沒有設定動畫資源
	if data != null and data.camp_animations != null:
		# 換上該角色的底片（SpriteFrames）
		anim.sprite_frames = data.camp_animations
		
		# 獲取所有動作名稱 (這回傳的是 PackedStringArray)
		var raw_actions = anim.sprite_frames.get_animation_names()
		
		# 【修復關鍵】將 PackedStringArray 轉換成普通的 Array
		var available_actions = Array(raw_actions) 
		
		if available_actions.size() > 0:
			# 現在可以使用 pick_random() 了！
			var random_action = available_actions.pick_random()
			
			# 安全檢查：確保隨機選到的名字不是空的
			if random_action != "":
				anim.play(random_action)
				print("角色 ", data.display_name, " 正在播放動畫：", random_action)
		else:
			print("錯誤：", data.display_name, " 的 SpriteFrames 裡沒有任何動畫名稱！")
	else:
		# 如果沒設定動畫，列印警告
		var d_name = data.display_name if data else "未知角色"
		print("警告：角色 ", d_name, " 沒有設定營地動畫資源！")

# 當點擊角色範圍時觸發
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()   # 回報給 CampScene

# ---------------------------------------------------
# 新增對話氣泡
func show_dialogue(text):
	if current_bubble:
		current_bubble.queue_free()
		
	current_bubble = bubble_scene.instantiate()
	$BubbleAnchor.add_child(current_bubble)
	
	# --- 反向縮放實作開始 ---
	# 取得角色當前的縮放倍率 (例如 1.9)
	var char_scale = self.scale.x
	# 避免除以 0 的錯誤
	if char_scale != 0:
		# 將氣泡的縮放設為倒數，抵消掉角色的放大效果
		var inverse_s = 0.8 / char_scale
		current_bubble.scale = Vector2(inverse_s, inverse_s)
	# --- 反向縮放實作結束 ---
	
	current_bubble.set_text(text)

# ---------------------------------------------------
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		clicked.emit(character_data)

# ---------------------------------------------------
