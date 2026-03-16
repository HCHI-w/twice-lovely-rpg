# TitleScreen.gd
extends Control


# 偵測調整畫面尺寸
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var logo_rect: TextureRect = $SafeArea/MainVBox/LogoRect
@onready var char_grid: GridContainer = $SafeArea/MainVBox/CharacterGrid
@onready var menu_buttons_container = $SafeArea/MainVBox/MenuButtons
@onready var memo_label = $SafeArea/MainVBox/MenuButtons/MemoLabel


@onready var start_button = $SafeArea/MainVBox/MenuButtons/StartButton
@onready var collectibles_button = $SafeArea/MainVBox/MenuButtons/CollectiblesButton


# ---------------------------------------------------
func _ready() -> void:
	CollectibleManager.load_data()
	
	# 監聽視窗大小改變的信號，這就像是「偵測器」，只要大小一變它就會「傳遞變化訊號」
	get_tree().root.size_changed.connect(_rearrange_ui)
	# 遊戲開始時先執行一次排列
	_rearrange_ui()
	
	# 初始完全透明
	modulate.a = 0.0
	# 開始淡入動畫
	_fade(Color(modulate.r, modulate.g, modulate.b, 0.0), Color(modulate.r, modulate.g, modulate.b, 1.0), 0.5)
	# 連接按鈕
	start_button.pressed.connect(_on_start_pressed)
	collectibles_button.pressed.connect(_on_collectibles_pressed)

# 調整畫面尺寸
func _rearrange_ui() -> void:
	# 獲取現在視窗的實際尺寸
	var window_size = get_viewport_rect().size
	
	# 兩個尺寸變數
	var icon_size: Vector2
	var grid_columns: int
	
	# 判斷是「直式」還是「橫式」
	if window_size.y > window_size.x:
		# --- 直式畫面 ---
		# Logo 高度可以稍微縮小，騰出空間給角色
		logo_rect.custom_minimum_size.y = 300
		
		# 將角色變成 3x3  2x5 或其它排列
		grid_columns = 3
		icon_size = Vector2(102, 136)   # 手機版：圖示變大 (假設原本是 80)
		# 調整容器的間距，讓它在窄螢幕看起來不擁擠
		main_vbox.add_theme_constant_override("separation", 20)
		print("手機模式：圖示放大為 102, 136")
	else:
		# --- 橫式畫面 ---
		# Logo 可以放大
		logo_rect.custom_minimum_size.y = 350
		
		# 回復成標準的排列
		grid_columns = 9
		icon_size = Vector2(60, 80)   # 電腦版：圖示縮小排成一列
		# 橫式畫面可以讓間距大一點
		main_vbox.add_theme_constant_override("separation", 50)
		print("目前是橫式，圖示為 60, 80")
		
	# 設定 Grid 列數
	char_grid.columns = grid_columns
	
	# 使用迴圈 (for loop) 遍歷 Grid 下面的所有子節點
	for icon in char_grid.get_children():
		# 檢查這個子節點是不是我們想要的類型 (預防萬一裡面有別的東西)
		if icon is TextureRect:
			# 修改每個圖示的最小尺寸
			icon.custom_minimum_size = icon_size
			
			# 找到裡面的動畫節點 (名稱叫什麼就寫什麼，我的名稱沒改AnimatedSprite2D)
			# 使用 get_node_or_null 是為了防止有些圖示還沒裝動畫而當機
			var anim = icon.get_node_or_null("AnimatedSprite2D")
			
			if anim:
				# 生活化比喻：相框變大了，裡面的照片也要跟著放大
				# 如果原本 80x80 時 scale 是 1.0，那 180x180 時就是 180/80 = 2.25 倍
				var scale_factor = icon_size.x / 60.0 
				anim.scale = Vector2(scale_factor, scale_factor)
				
				# 重要：確保動畫保持在新的相框中心
				anim.position = icon_size / 2
	
	# 在迴圈中處理按鈕
	for btn in menu_buttons_container.get_children():
		if btn is Button:
			if window_size.y > window_size.x:
				# 手機版：字體放大，按鈕變高好點擊
				btn.add_theme_font_size_override("font_size", 26)
				btn.custom_minimum_size.y = 80
			else:
				# 電腦版：字體正常
				btn.add_theme_font_size_override("font_size", 20)
				btn.custom_minimum_size.y = 50
	
	# 文字標籤的調整
	# 在直式判斷中
	if window_size.y > window_size.x:
		memo_label.add_theme_font_size_override("font_size", 26)
	else:
		memo_label.add_theme_font_size_override("font_size", 20)
	
	# 強制刷新佈局
	char_grid.queue_sort()
	main_vbox.queue_sort()

# ---------------------------------------------------
# 依畫面方向載入 Scene
func load_character_select_scene():
	var size = DisplayServer.window_get_size()
	
	if size.y > size.x:
		print("載入直式角色選擇")
		get_tree().change_scene_to_file(
			"res://Scenes/CharacterSelectScene_Portrait.tscn"
		)
	else:
		print("載入橫式角色選擇")
		get_tree().change_scene_to_file(
			"res://Scenes/CharacterSelectScene_Landscape.tscn"
		)

# ---------------------------------------------------
# 點擊開始按鈕
func _on_start_pressed() -> void:
	print("點擊開始遊戲")
	# 淡出後換場景
	_fade(Color(modulate.r, modulate.g, modulate.b, 1.0), Color(modulate.r, modulate.g, modulate.b, 0.0), 0.5, Callable(self, "_go_to_character_select"))

func _go_to_character_select() -> void:
#	get_tree().change_scene_to_file("res://Scenes/CharacterSelectScene.tscn")
	load_character_select_scene()

# 物品圖鑑按鈕
func _on_collectibles_pressed():
	get_tree().change_scene_to_file("res://Scenes/CollectiblesScene.tscn")


# ---------------------------------------------------
# 通用淡入 / 淡出 Tween 函式
# color_from: 起始顏色
# color_to: 結束顏色
# duration: 時間 (秒)
# on_finished: 可選回調
func _fade(color_from: Color, color_to: Color, duration: float = 0.2, on_finished = null) -> void:
	# 動畫期間禁止互動
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 先設定起始顏色
	modulate = color_from

	var tween = create_tween()
	tween.tween_property(self, "modulate", color_to, duration)
	# 動畫完成後
	if on_finished != null:
		tween.finished.connect(on_finished)
	else:
		tween.finished.connect(func():
			mouse_filter = Control.MOUSE_FILTER_PASS
		)

# ---------------------------------------------------
