# CharacterSelectScene.gd
# 建立玩家隊伍
extends Node

# --- UI Panel ---
@onready var main_layout = $CharacterSelectPanel/MainLayout
@onready var character_phase_panel = $CharacterSelectPanel/MainLayout/LeftSide/PhaseContainer/CharacterPhasePanel
@onready var class_phase_panel = $CharacterSelectPanel/MainLayout/LeftSide/PhaseContainer/ClassPhasePanel
@onready var character_button_container = $CharacterSelectPanel/MainLayout/LeftSide/PhaseContainer/CharacterPhasePanel/CharacterButtonContainer
@onready var class_button_container = $CharacterSelectPanel/MainLayout/LeftSide/PhaseContainer/ClassPhasePanel/ClassButtonContainer
@onready var description_label = $CharacterSelectPanel/MainLayout/LeftSide/DescriptionPanel/MarginContainer/DescriptionLabel
@onready var warning_label = $CharacterSelectPanel/MainLayout/LeftSide/DescriptionPanel/MarginContainer/WarningLabel

# --- 狀態 ---
enum UIState {
	CHARACTER_SELECT,
	CLASS_SELECT 
	}
var current_state: UIState

# --- 可選資料 (UI) ---
var available_characters: Array[CharacterData] = []
var available_classes: Array[ClassData] = []

# --- 暫存玩家選擇 (UI) ---
var temp_selected_characters: Array[CharacterData] = []
var temp_selected_classes: Array[ClassData] = []

# --- UI Style ---
var selected_style: StyleBoxFlat

# ----------------------------------------------------------
# UI 初始化與狀態切換
func _ready():
	randomize()
	
	# 建立選取外框
	selected_style = StyleBoxFlat.new()
	selected_style.border_width_left = 3
	selected_style.border_width_right = 3
	selected_style.border_width_top = 3
	selected_style.border_width_bottom = 3
	selected_style.border_color = Color(1.0, 0.955, 0.82, 0.961)
	selected_style.bg_color = Color(0,0,0,0) # 完全透明
	
	# 角色
	available_characters = [
		preload("res://Resources/Characters/char_01.tres"),
		preload("res://Resources/Characters/char_02.tres"),
		preload("res://Resources/Characters/char_03.tres"),
		preload("res://Resources/Characters/char_04.tres"),
		preload("res://Resources/Characters/char_05.tres"),
		preload("res://Resources/Characters/char_06.tres"),
		preload("res://Resources/Characters/char_07.tres"),
		preload("res://Resources/Characters/char_08.tres"),
		preload("res://Resources/Characters/char_09.tres")
	]
	# 職業
	available_classes = [
		preload("res://Resources/Classes/bard.tres"),
		preload("res://Resources/Classes/druid.tres"),
		preload("res://Resources/Classes/knight.tres"),
		preload("res://Resources/Classes/mage.tres"),
		preload("res://Resources/Classes/martial_artist.tres"),
		preload("res://Resources/Classes/priest.tres"),
		preload("res://Resources/Classes/ranger.tres"),
		preload("res://Resources/Classes/summoner.tres"),
		preload("res://Resources/Classes/thief.tres")
	]
	
	# 為三個右側面板連接點擊事件
	for i in range(3):
		var panel = $CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel.get_node("Panel_%d" % i)
		# 確保面板可以接收滑鼠事件
		panel.mouse_filter = Control.MOUSE_FILTER_STOP 
		# 連接 gui_input 信號，並傳入它是第幾個面板 (i)
		panel.gui_input.connect(_on_info_panel_gui_input.bind(i))
	
	# 生成角色按鈕
	current_state = UIState.CHARACTER_SELECT
	create_character_buttons()
	switch_state(UIState.CHARACTER_SELECT)
	
	# 連接視窗改變信號
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()   # 初始化
	
	# 把所有角色存進去 GameManager
	GameManager.character_database = available_characters

# ----------------------------------------------------------
# 畫面尺寸
func _on_window_resized():
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	# 針對直式進行細節微調
	if is_portrait:
		_apply_portrait_layout(window_size)
	else:
		_apply_landscape_layout(window_size)
		
	# 動態調整按鈕高度
	_adjust_button_height(is_portrait)

# 針對直式進行細節微調
func _apply_portrait_layout(_window_size: Vector2):
	# --- 處理 LeftSide ---
	var left_side = $CharacterSelectPanel/MainLayout/LeftSide
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_side.size_flags_vertical = Control.SIZE_EXPAND_FILL   # 讓它在垂直方向也能撐開
	left_side.size_flags_stretch_ratio = 1.0   # 左右兩邊分配比例設為 1:1
	
	# --- 處理 RightSide ---
	var right_side = $CharacterSelectPanel/MainLayout/RightSide
	right_side.size_flags_stretch_ratio = 1.0
	
	# --- 處理內部的 CharacterInfoPanel ---
	# 在直式中，將三個角色面板橫向排列 (HBox) 節省垂直空間
	$CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel.vertical = false
	
	# --- 自動切換 GridContainer 為 3 列 ---
	_set_grid_columns(3)
	
	# 按鈕尺寸
	character_button_container.columns = 3   # 直式維持 3 列

# 針對橫式進行細節微調
func _apply_landscape_layout(_window_size: Vector2):
	# 橫式：回復比例
	$CharacterSelectPanel/MainLayout/LeftSide.size_flags_stretch_ratio = 2.0   # 選擇區大一點
	
	$CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel.vertical = true
	
	# --- 自動切換 GridContainer 為 1 列 ---
	_set_grid_columns(2)
	
	character_button_container.columns = 3


# 統一處理 Grid 列數的輔助函式
func _set_grid_columns(cols: int):
	for i in range(3):
		var grid = get_node_or_null("CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel/Panel_%d/MarginContainer/GridContainer" % i)
		if grid and grid is GridContainer:
			grid.columns = cols

#  動態調整按鈕高度 - 角色 & 職業
func _adjust_button_height(is_portrait: bool):
	# 這裡設定理想的高度數值
	# 假設直式希望高一點點 (例如 160)，橫式希望更高 (例如 200)
	var target_height = 280 if is_portrait else 180
	
	# 處理角色按鈕
	for btn in character_button_container.get_children():
		if btn is Button:
			# 維持原始 X，只改 Y
			btn.custom_minimum_size.y = target_height
	
	# 處理職業按鈕 (同樣適用)
	for btn in class_button_container.get_children():
		if btn is Button:
			btn.custom_minimum_size.y = target_height
	
	# --- 處理右側數值面板 ---
	for i in range(3):
		var container_path = "CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel/Panel_%d/MarginContainer/GridContainer/" % i
		var _container_node = get_node_or_null(container_path)
	
	# --- 處理右側動作按鈕 (Confirm 系列) ---
	var _action_panel = $CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel

# Button 文字大小
func _get_button_font_size() -> int:
	var size = get_viewport().size
	return 40 if size.y > size.x else 26

# 選取順序文字大小
func _get_order_label_font_size() -> int:
	var size = get_viewport().size
	return 34 if size.y > size.x else 18


# ----------------------------------------------------------
# 處理右側面板的輸入事件
func _on_info_panel_gui_input(event: InputEvent, index: int):
	# 只有在「選擇職業」階段，且點擊的是滑鼠左鍵時才觸發
	if current_state == UIState.CLASS_SELECT and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_remove_class_at_index(index)

# 移除特定位置職業的邏輯
func _remove_class_at_index(index: int):
	# 檢查這個位置是否有選過職業
	# 比喻：如果你想拿掉第二個人的帽子，得先確定第二個人真的有戴帽子
	if index < temp_selected_classes.size():
		print("移除位置 ", index, " 的職業：", temp_selected_classes[index].display_name)
		temp_selected_classes.remove_at(index)
		
		# 移除後，後面的職業會自動往前補位
		# 重新整理所有面板與按鈕顏色
		refresh_after_class_change()
	else:
		print("這個位置還沒有職業可以移除")

# ----------------------------------------------------------
# 狀態切換函式
func switch_state(new_state: UIState) -> void:
	if new_state == current_state:
		return
		
	var previous_state = current_state
	current_state = new_state
	
	# 淡出舊 Panel
	match previous_state:
		UIState.CHARACTER_SELECT:
			await fade_out(character_phase_panel)
		UIState.CLASS_SELECT:
			await fade_out(class_phase_panel)
	# 再進入新狀態 + 淡入
	match current_state:
		UIState.CHARACTER_SELECT:
			_enter_character_state()
			await fade_in(character_phase_panel)
		UIState.CLASS_SELECT:
			_enter_class_state()
			await fade_in(class_phase_panel)

func _enter_character_state():
	character_phase_panel.visible = true
	class_phase_panel.visible = false
	# 更新確認按鈕狀態
	_update_confirm_button()

func _enter_class_state():
	character_phase_panel.visible = false
	class_phase_panel.visible = true
	
	create_class_buttons()
	_update_confirm_class_button()
	
	# --- 生成按鈕後 手動呼叫一次縮放更新 ---
	var _current_size = get_viewport().get_visible_rect().size
	_on_window_resized()

# ----------------------------------------------------------
# 角色與職業按鈕生成/選擇
# 生成角色按鈕
func create_character_buttons():
	for i in range(available_characters.size()):
		var char_data = available_characters[i]
		var btn = Button.new()
		
		# --- 選取順序標記 ---
		var order_label = Label.new()
		order_label.name = "OrderLabel"
		order_label.text = ""
		
		# --- 不要固定 size，設定最小高度並讓寬度自適應 ---
		order_label.custom_minimum_size = Vector2(26, 26) 
		order_label.autowrap_mode = TextServer.AUTOWRAP_OFF   # 確保不換行
		order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		order_label.add_theme_font_size_override("font_size", _get_order_label_font_size())
		order_label.add_theme_color_override("font_color", Color.WHITE)
		
		# 圓形背景，調整 StyleBox 的邊距 (Content Margin)
		var badge = StyleBoxFlat.new()
		badge.bg_color = Color(0.75, 0.443, 0.545, 1.0)
		# 圓角設定為高度的一半 (如果是 26 則設 13)
		badge.set_corner_radius_all(13) 
		# 增加左右內邊距，這樣文字變多時才不會貼到邊緣
		badge.content_margin_left = 8
		badge.content_margin_right = 8
		badge.content_margin_top = 2
		badge.content_margin_bottom = 2
		
		order_label.add_theme_stylebox_override("normal", badge)
		order_label.visible = false
		
		# 讓 Label 根據內容自動擴充大小
		order_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		
		btn.add_child(order_label)
		
		# --- 設定按鈕外觀 ---
		# 設定按鈕最小的大小 例如設定寬 120 像素，高 160 像素 (依照術圖比例調整)
		btn.custom_minimum_size = Vector2(120, 120)
		# --- 顯示文字 ---
		btn.text = char_data.display_name
		# 將資源中的圖示交給按鈕的 icon 屬性
		btn.icon = char_data.character_icon
		
		# 設定圖示顯示方式
		btn.expand_icon = true   # 讓圖示自動縮放適應按鈕大小
		# 「上方圖示、下方文字」
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# 排版設定
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Hover 顯示基礎能力
		btn.mouse_entered.connect(func():
			_show_character_description(char_data)
			# 預覽在 Panel_%d
			var preview_index = temp_selected_characters.size()
			# 檢查是否還有空位可以預覽
			if not temp_selected_characters.has(char_data) and preview_index < 3:
				# 找出預覽目標面板
				var p_node = $CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel.get_node("Panel_%d" % preview_index)
				p_node.show() # 先強迫它顯示，防止被 refresh 關掉
				preview_character_info(char_data, null, preview_index)
			
			# 如果是已經選中的角色，滑鼠移上去也要更新一次描述
			var index = temp_selected_characters.find(char_data)
			if index != -1:
				preview_character_info(char_data, null, index)
		)
		# 滑鼠離開自動還原
		btn.mouse_exited.connect(func():
			description_label.clear()
			refresh_all_panels()
		)
		# 點擊選擇角色
		btn.pressed.connect(func():
			_on_character_selected(char_data)
		)
		character_button_container.add_child(btn)
		
		btn.add_theme_font_size_override("font_size", _get_button_font_size())

# 生成職業按鈕
func create_class_buttons():
	# 清空按鈕
	for child in class_button_container.get_children():
		child.queue_free()
	
	for class_data in available_classes:
		var btn = Button.new()
		
		# --- 選取順序標記 ---
		var order_label = Label.new()
		order_label.name = "OrderLabel"
		order_label.text = ""
		
		# --- 不要固定 size，設定最小高度並讓寬度自適應 ---
		order_label.custom_minimum_size = Vector2(26, 26) 
		order_label.autowrap_mode = TextServer.AUTOWRAP_OFF   # 確保不換行
		order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		order_label.add_theme_font_size_override("font_size", _get_order_label_font_size())
		order_label.add_theme_color_override("font_color", Color.WHITE)
		
		# 圓形背景，調整 StyleBox 的邊距 (Content Margin)
		var badge = StyleBoxFlat.new()
		badge.bg_color = Color(0.75, 0.443, 0.545, 1.0)
		# 圓角設定為高度的一半 (如果是 26 則設 13)
		badge.set_corner_radius_all(13) 
		# 增加左右內邊距，這樣文字變多時才不會貼到邊緣
		badge.content_margin_left = 8
		badge.content_margin_right = 8
		badge.content_margin_top = 2
		badge.content_margin_bottom = 2
		
		order_label.add_theme_stylebox_override("normal", badge)
		order_label.visible = false
		
		# 讓 Label 根據內容自動擴充大小
		order_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		
		btn.add_child(order_label)
		
		# --- 設定按鈕外觀 ---
		# 設定按鈕最小的大小 例如設定寬 120 像素，高 160 像素 (依照圖比例調整)
		btn.custom_minimum_size = Vector2(120, 120)
		# --- 顯示文字 ---
		btn.text = class_data.display_name
		
		# 排版設定
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Hover 顯示最終能力
		btn.mouse_entered.connect(func():
			_show_class_description(class_data)
			
			var index = temp_selected_classes.size()
			if index < temp_selected_characters.size():
				# 確保面板是顯示狀態，才進行預覽
				var target_panel = $CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel.get_node("Panel_%d" % index)
				target_panel.show()
				
				preview_character_info(
					temp_selected_characters[index],
					class_data,
					index
				)
			)
		# 滑鼠離開自動還原
		btn.mouse_exited.connect(func():
			refresh_all_panels()
		)
		# 點擊選擇職業
		btn.pressed.connect(func():
			_on_class_selected(class_data)
		)
		class_button_container.add_child(btn)
		# 立即套用當前的縮放大小，避免它變回預設的小字
		var _current_size = get_viewport().get_visible_rect().size
		
		btn.add_theme_font_size_override("font_size", _get_button_font_size())
		
		# 等待一幀 確保所有按鈕都在場景樹裡了
		await get_tree().process_frame
		# 再次強迫執行排列邏輯
		_on_window_resized()

# 選擇事件處理
# 按鈕按下後的事件 - 角色
func _on_character_selected(char_data: CharacterData):
	# 選擇 → 取消
	if temp_selected_characters.has(char_data):
		temp_selected_characters.erase(char_data)
		refresh_all_panels()
		
		_update_character_button_colors()
		_update_confirm_button()
		return
	# 超過 3 個不能選
	if temp_selected_characters.size() >= 3:
		show_warning("最多只能選取 3 個角色")
		return
	# 選擇角色
	var _slot_index = temp_selected_characters.size()
	temp_selected_characters.append(char_data)
	print("選擇角色：", char_data.display_name)
	refresh_all_panels()
	
	_update_character_button_colors()
	_update_confirm_button()

# 按鈕按下後的事件 - 職業
func _on_class_selected(class_data: ClassData):
	# --- 檢查是否還能增加 ---
	# 確認隊伍還有沒有空位坐人
	if temp_selected_classes.size() >= temp_selected_characters.size():
		show_warning("職業數量不能超過角色數量")
		return

	# --- 直接增加職業，不檢查是否重複 ---
	# 現在不管你有沒有選過這個職業，都會往清單後面排隊
	temp_selected_classes.append(class_data)
	
	# --- 重新整理介面 ---
	refresh_after_class_change()
	print("目前職業組合：", temp_selected_classes)

# ----------------------------------------------------------
# 封裝一個重新整理的流程
func refresh_after_class_change():
	refresh_all_panels()
	_update_class_button_colors()
	_update_confirm_class_button()

# ----------------------------------------------------------
# 能力面板更新 / 預覽
# 預覽專用 - 角色或職業的能力
func preview_character_info(char_data: CharacterData, class_data: ClassData, panel_index: int):
	var base_values = {
		"hp": char_data.base_hp,
		"mp": char_data.base_mp,
		"str_": char_data.base_str,
		"def_": char_data.base_def,
		"int_": char_data.base_int,
		"dex": char_data.base_dex,
		"luk": char_data.base_luk
	}
	
	# 呼叫更新時，我們要稍微修改一下傳入的 char_name
	var final_name = char_data.display_name
	var hp = char_data.base_hp
	var mp = char_data.base_mp
	var str_ = char_data.base_str
	var def_ = char_data.base_def
	var int_ = char_data.base_int
	var dex = char_data.base_dex
	var luk = char_data.base_luk
	
	if class_data != null:
		final_name += " [ " + class_data.display_name + " ]"
		hp = int(hp * class_data.hp_multiplier)
		mp = int(mp * class_data.mp_multiplier)
		str_ = int(str_ * class_data.str_multiplier)
		def_ = int(def_ * class_data.def_multiplier)
		int_ = int(int_ * class_data.int_multiplier)
		dex = int(dex * class_data.dex_multiplier)
		luk = int(luk * class_data.luk_multiplier)
		
	update_panel_with_values(
		char_data.character_icon,
		final_name,
		hp,
		mp,
		str_,
		def_,
		int_,
		dex,
		luk,
		panel_index,
		base_values
	)

# 預覽專用 - 計算角色或職業的能力
func update_panel_with_values(
	char_icon: Texture2D,
	char_name: String,
	hp: int,
	mp: int,
	str_: int,
	def_: int,
	int_: int,
	dex: int,
	luk: int,
	index: int,
	base_values = null
) -> void:
	var panel = $CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel.get_node("Panel_%d" % index)
	
	# --- 組合名字與職業 ---
	var display_text = "角色：" + char_name
	# 檢查 temp_selected_classes 裡面有沒有對應這個 index 的職業
	if index < temp_selected_classes.size():
		var class_namedata = temp_selected_classes[index].display_name
		display_text += " [color=yellow][ " + class_namedata + " ][/color]"   # 職業加上顏色
	
	panel.get_node("MarginContainer/GridContainer/NameLabel_%d" % index).bbcode_enabled = true
	panel.get_node("MarginContainer/GridContainer/NameLabel_%d" % index).text = display_text
	
	# --- Icon 圖 ---
	var icon_node = panel.get_node("MarginContainer/GridContainer/Icon_%d" % index)
	if char_icon:   # 檢查資源裡有沒有圖，避免報錯
		icon_node.texture = char_icon
	
	# 先決定基準值
	var base_hp = base_values["hp"] if base_values != null else null
	var base_mp = base_values["mp"] if base_values != null else null
	var base_str = base_values["str_"] if base_values != null else null
	var base_def = base_values["def_"] if base_values != null else null
	var base_int = base_values["int_"] if base_values != null else null
	var base_dex = base_values["dex"] if base_values != null else null
	var base_luk = base_values["luk"] if base_values != null else null
	# 更新 + 顏色判定
	_animate_stat_change(panel.get_node("MarginContainer/GridContainer/HPLabel_%d" % index), "HP", base_hp, hp)
	_animate_stat_change(panel.get_node("MarginContainer/GridContainer/MPLabel_%d" % index), "MP", base_mp, mp)
	_animate_stat_change(panel.get_node("MarginContainer/GridContainer/STRLabel_%d" % index), "STR", base_str, str_)
	_animate_stat_change(panel.get_node("MarginContainer/GridContainer/DEFLabel_%d" % index), "DEF", base_def, def_)
	_animate_stat_change(panel.get_node("MarginContainer/GridContainer/INTLabel_%d" % index), "INT", base_int, int_)
	_animate_stat_change(panel.get_node("MarginContainer/GridContainer/DEXLabel_%d" % index), "DEX", base_dex, dex)
	_animate_stat_change(panel.get_node("MarginContainer/GridContainer/LUKLabel_%d" % index), "LUK", base_luk, luk)
	
# ----------------------------------------------------------
# 顯示說明欄 - 角色
func _show_character_description(char_data: CharacterData):
	var text = char_data.description
	
	description_label.clear()
	description_label.append_text(text)

# 顯示說明欄 - 職業
func _show_class_description(class_data: ClassData):
	var text = class_data.description
	
	description_label.clear()
	description_label.append_text(text + "[color=gray]  (點擊右側角色面板可移除職業)[/color]")

# 顯示人數限制
func show_warning(text: String):
	warning_label.text = text
	warning_label.visible = true
	
	await get_tree().create_timer(1.5).timeout
	
	warning_label.visible = false

# ----------------------------------------------------------
# 確認/返回按鈕管理
# 確認按鈕 - 角色
func _on_confirm_button_pressed() -> void:
	print("角色選擇完成，開始選擇職業")
	
	switch_state(UIState.CLASS_SELECT)
	# 隱藏確認按鈕
	$CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel/ConfirmButton.visible = false
	# 顯示職業相關按鈕
	$CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel/ConfirmClassButton.visible = true
	$CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel/BackToCharacterButton.visible = true

# 確認按鈕啟用 / 停用
func _update_confirm_button():
	var btn = $CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel/ConfirmButton
	
	if temp_selected_characters.size() == 3:
		btn.disabled = false
	else:
		btn.disabled = true

# 確認按鈕 - 職業
func _on_confirm_class_button_pressed() -> void:
	finalize_party()

func _update_confirm_class_button():
	var btn = $CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel/ConfirmClassButton
	
	if temp_selected_classes.size() == 3:
		btn.disabled = false
	else:
		btn.disabled = true

# 返回選擇角色按鈕
func _on_back_to_character_button_pressed() -> void:
	# 清空職業選擇
	temp_selected_classes.clear()
	# 重新生成角色按鈕
	switch_state(UIState.CHARACTER_SELECT)
	# 顯示角色確認按鈕
	$CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel/ConfirmButton.visible = true
	# 隱藏職業按鈕
	$CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel/ConfirmClassButton.visible = false
	$CharacterSelectPanel/MainLayout/RightSide/ActionButtonPanel/BackToCharacterButton.visible = false
	# 重設確認按鈕狀態
	_update_confirm_button()
	# 刷新數值
	refresh_all_panels()

# ----------------------------------------------------------
# 淡入淡出與動畫工具
# Panel 淡入（0.2 秒）
func fade_in(panel: Control, duration := 0.2):
	panel.visible = true
	panel.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 等一幀讓 Layout 計算完成
	await get_tree().process_frame
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, duration)
	
	await tween.finished
	panel.mouse_filter = Control.MOUSE_FILTER_PASS   # 淡入完成後可以操作
	
# Panel 淡出（0.2 秒）
func fade_out(panel: Control, duration := 0.2):
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, duration)
	
	await tween.finished
	panel.visible = false

# 動畫函式
func _animate_stat_change(
	label: RichTextLabel,
	stat_name: String,
	base_value,
	target_value,
	duration := 0.25
):
	
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF # 關鍵：直式 2 列時防止它亂換行
	
	# 如果沒有基準值 → 直接顯示
	if base_value == null:
		_set_label_with_color(label, stat_name, null, target_value)
		return
	
	var tween = create_tween()
	tween.tween_method(
		func(value):
			label.text = "%s: %d" % [stat_name, int(value)], # 使用 .text 更輕量
		base_value,
		target_value,
		duration
	)
	
	await tween.finished
	# 動畫完成後顯示完整差值版本
	_set_label_with_color(label, stat_name, base_value, target_value)

# ----------------------------------------------------------
# 刷新面板
# 刷新全部 Panel
func refresh_all_panels():
	for i in range(3):
		var panel = get_node("CharacterSelectPanel/MainLayout/RightSide/CharacterInfoPanel/Panel_" + str(i))
		# 如果這個位置有「正式選中」的角色
		if i < temp_selected_characters.size():
			var char_data = temp_selected_characters[i]
			var class_data = null
			if i < temp_selected_classes.size():
				class_data = temp_selected_classes[i]
			# 顯示正式資料
			update_panel_with_values(
				char_data.character_icon,
				char_data.display_name,
				int(char_data.base_hp * (class_data.hp_multiplier if class_data else 1)),
				int(char_data.base_mp * (class_data.mp_multiplier if class_data else 1)),
				int(char_data.base_str * (class_data.str_multiplier if class_data else 1)),
				int(char_data.base_def * (class_data.def_multiplier if class_data else 1)),
				int(char_data.base_int * (class_data.int_multiplier if class_data else 1)),
				int(char_data.base_dex * (class_data.dex_multiplier if class_data else 1)),
				int(char_data.base_luk * (class_data.luk_multiplier if class_data else 1)),
				i
			)
			panel.show()
		else:
			# 如果沒選角色滑鼠離開後，藏起來
			panel.hide()
			
	_update_class_button_colors()

# ----------------------------------------------------------
# 數值顏色調整
func _set_label_with_color(label: RichTextLabel, stat_name: String, base_value, current_value):
	# 每次進來先清空
	label.clear()
	# 加上這行確保它不會因為寬度過窄而縮成一條線
	label.custom_minimum_size.x = 80 if get_viewport().size.y > get_viewport().size.x else 120
	
	if base_value == null:
		label.append_text("%s: %d" % [stat_name, current_value])
		return
	
	var difference = current_value - base_value
	
	# 主數值 永遠白色
	label.append_text("%s: %d" % [stat_name, current_value])
	
	if difference == 0:
		return
	
	# 如果有差值，直接計算好字串一次補上去
	# 這裡可以使用 [i] (斜體) 或稍微調淡顏色來做出區隔，而不必鎖死字體大小
	if difference > 0:
		label.append_text(" [color=green]( +%d )[/color]" % difference)   # 綠色 ↑
	elif difference < 0:
		label.append_text(" [color=red]( %d )[/color]" % difference)   # 紅色 ↓

# 按鈕變色系統 - 角色
func _update_character_button_colors():
	for btn in character_button_container.get_children():
		if not (btn is Button):
			continue
		
		var char_name = btn.text
		var order_label: Label = btn.get_node("OrderLabel")
		var index = -1
		
		for i in range(temp_selected_characters.size()):
			if temp_selected_characters[i].display_name == char_name:
				index = i
				break
		
		if index != -1:
			# 有被選
			btn.add_theme_stylebox_override("normal", selected_style)
			
			order_label.text = str(index + 1)
			order_label.visible = true
		else:
			# 沒選
			btn.remove_theme_stylebox_override("normal")
			order_label.visible = false

# 按鈕變色系統 - 職業
func _update_class_button_colors():
	# 先重設所有按鈕狀態
	for btn in class_button_container.get_children():
		if not (btn is Button): continue
		btn.remove_theme_stylebox_override("normal")
		var order_label: Label = btn.get_node("OrderLabel")
		order_label.text = ""
		order_label.visible = false
		
	# 遍歷「已選擇」的清單，把數字填回去按鈕
	for i in range(temp_selected_classes.size()):
		var selected_data = temp_selected_classes[i]
		
		# 在 UI 找出對應這個資料的按鈕
		for btn in class_button_container.get_children():
			# 這裡建議用資源路徑或資料本身比對，比用名稱安全
			# 假設我們在 create_class_buttons 時有把 data 存進 btn 的 meta
			# 或者直接比對按鈕文字
			if btn.text == selected_data.display_name:
				var order_label: Label = btn.get_node("OrderLabel")
				
				# 如果 label 已經有數字了，代表重複選取，用 "." 隔開
				if order_label.text == "":
					order_label.text = str(i + 1)
				else:
					order_label.text += "·" + str(i + 1)
				
				btn.add_theme_stylebox_override("normal", selected_style)
				order_label.visible = true
				# 注意：這裡「不要」break，因為同一個職業可能出現在清單多個位置
				
				# --- 強迫 Label 重新計算尺寸 更新Label Size ---
				order_label.reset_size()

# ----------------------------------------------------------
# 使用 PartyBuilder 建立正式隊伍
func finalize_party():
	var builder := PartyBuilder.new()
	for i in range(3):
		builder.add_selection(temp_selected_characters[i], temp_selected_classes[i])
	
	GameManager.party = builder.build_party()
	# 切換到過場動畫
	TransitionManager.change_scene("res://Scenes/BattleScene.tscn", "準備開始冒險...", true)

# ----------------------------------------------------------
