# CollectiblesScene.gd
# 收藏圖鑑
extends Control

@onready var grid = $MarginContainer/Panel/PanelContainer/GridContainer
@onready var info_overlay = $MarginContainer/Panel/InfoOverlay           # 新增遮罩層
@onready var info_panel = $MarginContainer/Panel/InfoOverlay/InfoPanel   # 視窗主體
@onready var icon = $MarginContainer/Panel/InfoOverlay/InfoPanel/VBoxContainer/Icon
@onready var name_label = $MarginContainer/Panel/InfoOverlay/InfoPanel/VBoxContainer/Name
@onready var desc_label = $MarginContainer/Panel/InfoOverlay/InfoPanel/VBoxContainer/Description
@onready var collection_label = $MarginContainer/Panel/CollectionLabel
@onready var back_button = $BackButton

var all_collectibles := []

# ---------------------------------------------------
func _ready():
	load_collectibles()
	build_grid()
	update_collection_rate()
	
	back_button.pressed.connect(_on_BackButton_pressed)
	
	# 初始狀態：隱藏彈窗
	info_overlay.visible = false
	# --- 點擊任何地方關閉彈窗 ---
	info_overlay.gui_input.connect(_on_overlay_gui_input)
	
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()   # 初始化排版


# ---------------------------------------------------
func _on_window_resized():
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	var margin_value = 40 if is_portrait else 20
	$MarginContainer.add_theme_constant_override("margin_left", margin_value)
	$MarginContainer.add_theme_constant_override("margin_right", margin_value)
	
	# --- 調整 InfoPanel 彈窗尺寸 ---
	if is_portrait:
		info_panel.custom_minimum_size = Vector2(window_size.x * 0.4, window_size.y * 0.5)
	else:
		info_panel.custom_minimum_size = Vector2(window_size.x * 0.5, window_size.y * 0.6)
	
	# 重設 pivot_offset 以確保動畫中心正確
	info_panel.pivot_offset = info_panel.custom_minimum_size / 2
	
	# --- 調整 GridContainer 欄位數與間距 ---
	if is_portrait:
		grid.columns = 4   # 直式改為 3 欄，圖標會變大
		grid.add_theme_constant_override("h_separation", 20) # 水平間距
		grid.add_theme_constant_override("v_separation", 20) # 垂直間距
	else:
		grid.columns = 8   # 橫式 6~8 欄
		grid.add_theme_constant_override("h_separation", 15)
		grid.add_theme_constant_override("v_separation", 15)
	
	# --- 動態限制 GridContainer 內所有按鈕的大小 ---
	# 定義想要的尺寸
	var target_btn_size: Vector2
	if is_portrait:
		# 直式：假設你希望按鈕大一點，例如 180x180
		target_btn_size = Vector2(240, 240)
	else:
		# 橫式：按鈕小一點，例如 120x120
		target_btn_size = Vector2(140, 140)
	
	# 遍歷目前 Grid 裡所有的按鈕並套用
	for child in grid.get_children():
		if child is TextureButton:
			child.custom_minimum_size = target_btn_size
	
	# --- 動態字體調整 ---
	var base_font_size = 32 if is_portrait else 24
	_update_ui_fonts(base_font_size)
	
	# --- BackButton 位置固定 ---
	_adjust_back_button_layout(is_portrait, window_size)


# 輔助函式：統一更新所有文字字體
func _update_ui_fonts(base_size: int):
	# 圖鑑進度文字
	collection_label.add_theme_font_size_override("font_size", base_size)
	# 返回按鈕文字
	back_button.add_theme_font_size_override("font_size", base_size)
	# 彈窗內的文字
	name_label.add_theme_font_size_override("font_size", base_size + 2)   # 名字大一點
	desc_label.add_theme_font_size_override("normal_font_size", base_size - 1)   # 描述小一點
	
	# 動態調整 Icon 顯示大小
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	var icon_display_size = 240 if is_portrait else 160
	icon.custom_minimum_size = Vector2(icon_display_size, icon_display_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


# 輔助函式：處理返回按鈕排版
func _adjust_back_button_layout(is_portrait: bool, window_size: Vector2):
	if is_portrait:
		# 直式：固定在螢幕中下方 (橫向置中，底部往上偏移 10% 高度)
		back_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		back_button.position.y = window_size.y * 0.85 
		# 修正置中偏移
		back_button.position.x = (window_size.x - back_button.size.x) / 2
	else:
		# 橫式：放回角落或原本的位置 (例如左下或左上)
		back_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		back_button.position = Vector2(40, window_size.y - 80)


# 輔助函式：Icon 圖片變大
func _adjust_info_icon():
	# 強制設定尺寸
	icon.custom_minimum_size = Vector2(200, 200)
	
	# 設定縮放模式
	# EXPAND_IGNORE_SIZE 允許圖片大於或小於原始紋理
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# 設定拉伸模式，保持比例並置中
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 確保它在 VBoxContainer 中不會被別人擠壓
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


# ---------------------------------------------------
# 處理遮罩點擊事件
func _on_overlay_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			close_info()


# ---------------------------------------------------
# 自動掃描 collectibles 資料夾
func load_collectibles():
	var dir = DirAccess.open("res://Data/Collectibles")
	
	if dir == null:
		push_error("Collectibles folder not found")
		return
	
	dir.list_dir_begin()
	var file = dir.get_next()
	
	while file != "":
		if file.ends_with(".tres"):
			all_collectibles.append(load("res://Data/Collectibles/" + file))
		file = dir.get_next()
	
	dir.list_dir_end()
	

# ---------------------------------------------------
# 建立圖鑑
func build_grid():
	for c in grid.get_children():
		c.queue_free()
	
	for data in all_collectibles:
		var button = TextureButton.new()
		
		# 這裡先給一個基礎大小，Resize 時會被上面的函式覆蓋
		button.custom_minimum_size = Vector2(120, 120)
		
		# 保持圖片比例且不失真
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED   # 改用這個更保險
		
		# 設定 Size Flags，讓 GridContainer 好排版
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		if CollectibleManager.has_collectible(data.id):
			button.texture_normal = data.icon
		else:
			button.texture_normal = preload("res://Data/Collectibles/unknown.png")
		
		# NEW 標記
		if CollectibleManager.is_new(data.id):
			var label = Label.new()
			label.text = "NEW"
			label.modulate = Color.RED
			label.position = Vector2(4,4)
			button.add_child(label)
		
		button.pressed.connect(_on_item_pressed.bind(data))
		grid.add_child(button)
	
	# 建立完後，確保它們的大小符合當前視窗狀態
	_on_window_resized()

# ---------------------------------------------------
# 點擊圖鑑 顯示彈窗
func _on_item_pressed(data: CollectibleData):
	# 設定 icon 的屬性
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED   # 確保圖片不變形
	
	# 更新資料
	if not CollectibleManager.has_collectible(data.id):
		name_label.text = "???"
		desc_label.text = "尚未取得"
		icon.texture = preload("res://Data/Collectibles/unknown.png")   # 顯示問號圖
	else:
		icon.texture = data.icon
		name_label.text = data.display_name
		desc_label.text = data.description
		
		# 只有當它是新物品時，才需要重繪網格以移除 NEW 標籤
		if CollectibleManager.is_new(data.id):
			CollectibleManager.clear_new(data.id)
			build_grid()   # 這裡會觸發上面新增的 _on_window_resized()
	
	# 彈出動畫
	open_info()

# 彈出動畫
func open_info():
	info_overlay.visible = true
	info_overlay.modulate.a = 0
	
	# 簡單的彈出動畫
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(info_overlay, "modulate:a", 1.0, 0.2)
	# 讓 InfoPanel 從縮小狀態變大
	info_panel.scale = Vector2(0.8, 0.8)
	info_panel.pivot_offset = info_panel.size / 2 # 確保從中心縮放
	tween.tween_property(info_panel, "scale", Vector2(1.0, 1.0), 0.3)

func close_info():
	var tween = create_tween()
	await tween.tween_property(info_overlay, "modulate:a", 0.0, 0.15).finished
	info_overlay.visible = false

# ---------------------------------------------------
# 收集率
func update_collection_rate():
	var owned = CollectibleManager.total_collected()
	var total = all_collectibles.size()
	
	collection_label.text = "掉落物品： %d / %d" % [owned, total]

# ---------------------------------------------------
# 返回按鈕
func _on_BackButton_pressed():
	print("返回 Title")
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")

# ---------------------------------------------------
