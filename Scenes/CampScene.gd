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

# 存放從 JSON 讀進來的對話
var group_data = {}
var current_group_sequence = []   # 存放當前觸發的劇本清單
var sequence_index = 0            # 紀錄演到第幾句

# ---------------------------------------------------
func _ready():
	# 載入 JSON 文檔
	load_group_dialogue_json()
	# 安全機制：先把按鈕停用，防止玩家在黑畫面時亂點
	depart_button.disabled = true
	
	# 連接視窗縮放
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()
	
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
	
	# 在所有人都生成完畢後，進場自動觸發一次對話 (自動判斷要用組合對話還是個人對話)
	trigger_random_dialogue()
	

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
		
		# 如果希望在橫式時不要露出左右黑邊
		if (tex_size.x * scale_factor) < window_size.x:
			scale_factor = window_size.x / tex_size.x
		
		background.scale = Vector2(scale_factor, scale_factor)


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


# ---------------------------------------------------
# --- 核心功能：讀取 JSON ---
func load_group_dialogue_json():
	var file_path = "res://CampDialogue/group_dialogues.json"   # 確保路徑正確
	if not FileAccess.file_exists(file_path):
		print("找不到對話 JSON 檔案")
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	
	# 將文字轉成 Godot 的 Dictionary (字典)
	var json_data = JSON.parse_string(content)
	if json_data != null:
		group_data = json_data
		print("成功載入組合對話庫")


# --- 核心功能：產生組合 Key ---
func get_current_group_key() -> String:
	var ids = []
	for c in camp_characters:
		# 收集目前在場所有人的 ID
		ids.append(c.character_data.id.to_lower())
	
	ids.sort()   # 排序：確保不管順序如何，結果都是 A_B_C_D
	return "_".join(ids)


# --- 修改後的對話觸發邏輯 ---
func trigger_random_dialogue():
	# 安全檢查：如果營地裡沒人，就直接結束
	if camp_characters.is_empty():
		return
	
	# 先清除目前所有人的對話泡泡（確保畫面上只有一個泡泡）
	for c in camp_characters:
		if c.current_bubble != null:
			c.current_bubble.queue_free()
			c.current_bubble = null
	
	# 如果目前「劇本」還沒演完，就繼續演下一句
	if sequence_index < current_group_sequence.size():
		play_next_in_sequence()
		return
	
	# 如果劇本演完了（或還沒開始），檢查有沒有新的組合劇本
	var group_key = get_current_group_key()
	print("當前營地組合 Key: ", group_key)   # 確認組合
	
	# --- 尋找所有匹配的劇本 (包含 v2, v3...) ---
	var matched_scripts = []
	
	# 遍歷 JSON 字典裡所有的 Key
	for k in group_data.keys():
		# 如果 Key 完全相同，或者是該 Key 加上了 "_v" 開頭的後綴
		# 例如 "mina_momo_nayeon_tzuyu" 會匹配到 "mina_momo_nayeon_tzuyu" 和 "mina_momo_nayeon_tzuyu_v2"
		if k == group_key or k.begins_with(group_key + "_v"):
			matched_scripts.append(group_data[k])
	
	# 如果有找到任何匹配的劇本
	if matched_scripts.size() > 0:
		print("成功匹配到組合劇本，數量：", matched_scripts.size())
		# 隨機從匹配清單中挑選一個劇本
		current_group_sequence = matched_scripts.pick_random()
		sequence_index = 0
		play_next_in_sequence()
	else:
		print("找不到匹配劇本，執行個人隨機對話 (Key: ", group_key, ")")
		# 沒劇本就退回原本的「個人隨機對話」
		current_group_sequence = [] # 清空劇本
		sequence_index = 0
		play_random_individual_dialogue()

		# 執行原本的單人說話邏輯
#		random_speaker.show_dialogue(lines.pick_random())


# 執行劇本中的下一行
func play_next_in_sequence():
	if sequence_index >= current_group_sequence.size():
		sequence_index = 0   # 播完了就重頭循環，或是可以設為停止
	
	var line_data = current_group_sequence[sequence_index]
	var target_id = line_data["id"]   # 取得 JSON 裡的 slot 編號
	var text = line_data["text"]      # 取得內容
	
	# 在場上所有角色中尋找 ID 匹配的人
	var speaker_found = false
	for c in camp_characters:
		if c.character_data.id.to_lower() == target_id.to_lower():
			c.show_dialogue(text)
			speaker_found = true
			break # 找到就停止循環
	
	# 如果 JSON 寫錯名字，或是該角色不在場，就印出錯誤方便除錯
	if not speaker_found:
		print("除錯：找不到 ID 為 ", target_id, " 的發言者。請檢查 JSON 拼字。")
	
	# 準備下一句
	sequence_index += 1


func play_random_individual_dialogue():
	var random_speaker = camp_characters.pick_random()
	var id = random_speaker.character_data.id
	var lines = DialogueRegistry.dialogues.get(id, ["..."])
	random_speaker.show_dialogue(lines.pick_random())


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
