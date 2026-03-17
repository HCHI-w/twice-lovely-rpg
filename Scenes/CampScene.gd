# CampScene.gd
extends Node2D

signal depart_pressed

# 出發按鈕
@onready var depart_button = $DepartButton

# --- 對話系統 ---
@onready var camp_layer = $CampCharacterLayer
# --- 生成隊伍角色、隨機訪客 ---
@onready var slot1 = $CampCharacterLayer/PlayerSlot1
@onready var slot2 = $CampCharacterLayer/PlayerSlot2
@onready var slot3 = $CampCharacterLayer/PlayerSlot3
@onready var visitor_slot = $CampCharacterLayer/VisitorSlot
# --- UI 調整 ---
@onready var background = $Background
@onready var label = $Label
@onready var collection_panel = $CollectionPanel

var CampCharacterScene = preload("res://Scenes/CampCharacter.tscn")

var camp_characters = []   # 存角色

var dialogue_lines = []
var dialogue_index = 0
var dialogue_active = false

# ---------------------------------------------------
func _ready():
	# 安全機制：先把按鈕停用，防止玩家在黑畫面時亂點
	depart_button.disabled = true
	# 覆蓋黑畫面
	TransitionManager.transition_instance.show()
	TransitionManager.transition_instance.rect.modulate.a = 1.0
	
	restore_party()
	apply_class_camp_buffs()
	show_collection()
	
	# 等待一幀，確保 UI 都排版好了
	await get_tree().process_frame
	
	# 淡出 1 秒
	await TransitionManager.transition_instance.fade_out(1.0)
	TransitionManager.transition_instance.hide()
	
	depart_button.disabled = false
	depart_button.pressed.connect(_on_depart_pressed)
	
	spawn_party_characters()
	spawn_random_visitor()
	# 在所有人都生成完畢後，進場自動觸發一次對話
	trigger_random_dialogue()
	
	# 連接視窗縮放
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()

# ---------------------------------------------------
# 核心：處理排版與背景縮放
func _on_window_resized():
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	# 調整背景 (Sprite2D)
	_adjust_background(window_size)
	
	# 調整字體大小與 Label 位置
	var font_size = 48 if is_portrait else 32
	label.add_theme_font_size_override("font_size", font_size)
	label.position.x = (window_size.x - label.size.x) / 2
	label.position.y = window_size.y * 0.1 # 放在頂部 10% 處
	

# 處理背景縮放 (Cover 模式)
func _adjust_background(window_size: Vector2):
	if background.texture:
		background.position = window_size / 2
		var tex_size = background.texture.get_size()
		# 這裡改為：永遠以螢幕 y 軸高度除以圖片原始高度
		# 這樣圖片的「垂直尺寸」就會剛好撐滿螢幕，且比例不變
		var scale_factor = window_size.y / tex_size.y
		
		# 如果希望在橫式時不要露出左右黑邊，可以加一個保險：
		if (tex_size.x * scale_factor) < window_size.x:
			scale_factor = window_size.x / tex_size.x
		
		background.scale = Vector2(scale_factor, scale_factor)

# 處理角色 Slot 的微調
#func _adjust_character_slots(window_size: Vector2, is_portrait: bool):
#	var center = window_size / 2
	
#	if is_portrait:
		# 直式：角色可以稍微垂直排列或縮小間距
#		slot1.position = center + Vector2(-350, 150)
#		slot2.position = center + Vector2(-400, 550)
#		slot3.position = center + Vector2(360, 550)
#		visitor_slot.position = center + Vector2(370, 150)   # 訪客
#	else:
		# 橫式：角色扇形圍繞火堆
#		slot1.position = center + Vector2(-200, 90)
#		slot2.position = center + Vector2(-150, 160)
#		slot3.position = center + Vector2(180, 160)
#		visitor_slot.position = center + Vector2(130, 30)
	
	# 同步更新已經生成出來的角色位置
#	_update_active_character_positions(is_portrait)

# 讓已經在場上的角色瞬移到新的 Slot 位置
#func _update_active_character_positions(is_portrait: bool):
#	var slots = [slot1, slot2, slot3]
	
	# 修正建議：直式給 1.8 ~ 2.0，橫式維持 1.5 左右
#	var portrait_scale = 1.9
#	var landscape_scale = 1.6
	
#	var s_val = portrait_scale if is_portrait else landscape_scale
#	var fixed_scale = Vector2(s_val, s_val)
	
#	for i in range(min(camp_characters.size(), 3)):
#		camp_characters[i].global_position = slots[i].global_position
		# 強制設定角色的縮放，避免受到父節點或其他縮放邏輯影響
#		camp_characters[i].scale = fixed_scale
	
#	if camp_characters.size() > 3:
#		camp_characters[3].global_position = visitor_slot.global_position
#		camp_characters[3].scale = fixed_scale


#func _adjust_ui_layout(window_size: Vector2, is_portrait: bool):
	# DepartButton 置中靠下
#	depart_button.size.x = window_size.x * 0.4 if is_portrait else 200
#	depart_button.position.x = (window_size.x - depart_button.size.x) / 2
#	depart_button.position.y = window_size.y * 0.85


# ---------------------------------------------------
# 全員恢復
func restore_party():
	for member in GameManager.party.get_members():
		member.current_hp = member.get_max_hp()
		member.current_mp = member.get_max_mp()
		
		if member.current_hp <= 0:
			member.current_hp = member.get_max_hp()

	print("全員恢復完成")

# ---------------------------------------------------
# 職業專屬營地 Buff
func apply_class_camp_buffs():
	var party = GameManager.party
	
	for member in party.get_members():
		var class_data: ClassData = member.class_data
		# 如果這個職業沒有營地 Buff
		if class_data.camp_buff_ids.is_empty():
			continue
		
		for buff_id in class_data.camp_buff_ids:
			var buff = BuffRegistry.get_buff(buff_id)
			
			if buff == null:
				continue
				
			member.add_buff(buff)
			print(
				member.character_data.display_name,
				"獲得營地 Buff:",
				buff.name
			)
		# 關鍵：Buff 套用後重新補滿
		member.current_hp = member.get_max_hp()
		member.current_mp = member.get_max_mp()

# ---------------------------------------------------
# 生成隊伍角色
func spawn_party_characters():
	var slots = [slot1, slot2, slot3]
	var party = GameManager.party.get_members()
	
	for i in range(party.size()):
		var character = CampCharacterScene.instantiate()
		camp_layer.add_child(character)
		
		character.global_position = slots[i].global_position
		
		character.setup(party[i].character_data)
		camp_characters.append(character)

# 生成訪客
func spawn_random_visitor():
	var all_characters = GameManager.character_database
	var party_members = GameManager.party.get_members()
	var candidates = []
	
	for c in all_characters:
		var in_party = false
		
		for member in party_members:
			if member.character_data.id == c.id:
				in_party = true
			
		if not in_party:
			candidates.append(c)
		
	if candidates.is_empty():
		return
	
	var random_char = candidates.pick_random()
	var visitor = CampCharacterScene.instantiate()
	
	camp_layer.add_child(visitor)
	
	visitor.global_position = visitor_slot.global_position
	
	visitor.setup(random_char)
	visitor.clicked.connect(trigger_random_dialogue)
	camp_characters.append(visitor)

# 隨機觸發一個人的對話
func trigger_random_dialogue():
	# 安全檢查：如果營地裡沒人，就直接結束
	if camp_characters.is_empty():
		return
	
	# 先清除目前所有人的對話泡泡（確保畫面上只有一個泡泡）
	for c in camp_characters:
		if c.current_bubble != null:
			c.current_bubble.queue_free()
			c.current_bubble = null
	# 從陣列中隨機抽籤選出一個角色
	# pick_random() 是 Godot 4 內建的超好用功能
	var random_speaker = camp_characters.pick_random()
	
	# 取得該角色的對話資料
	var id = random_speaker.character_data.id
	var lines = DialogueRegistry.dialogues.get(id, ["..."])   # 如果找不到就用 "..." 代替
	
	# 隨機選一句話來顯示
	var random_text = lines.pick_random()
	
	# 叫那個角色把話說出來
	random_speaker.show_dialogue(random_text)


# 偵測輸入（點擊畫面）
func _input(event):
	# 如果玩家點擊了滑鼠左鍵（且是按下那一刻）
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 觸發新的隨機對話
		trigger_random_dialogue()

# ---------------------------------------------------
# 顯示收藏品
func show_collection():
	print("顯示收藏品（未實作）")

# ---------------------------------------------------
# 離開營地
func _on_depart_pressed():
	# 離開時淡入黑畫面
	await TransitionManager.transition_instance.fade_in(0.5)
	
	depart_pressed.emit()

# ---------------------------------------------------
