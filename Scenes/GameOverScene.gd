# GameOverScene.gd
extends Node2D


@onready var control = $Control
@onready var color_rect = $Control/ColorRect
@onready var main_container = $Control/MainContainer
@onready var game_over_label = $Control/MainContainer/GameOverLabel

# ---------------------------------------------------
func _ready():
	# 初始淡入動畫
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	
	# 連接視窗縮放
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()

# 解析度適配邏輯
func _on_window_resized():
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	# 背景鋪滿
	color_rect.size = window_size
	
	# MainContainer 置中
	# 寬度佔螢幕 90%，高度自動計算
	main_container.size.x = window_size.x * 0.9
	main_container.position.x = (window_size.x - main_container.size.x) / 2
	
	# 垂直置中：螢幕高度的一半減去容器高度的一半
	# 注意：VBoxContainer 的高度會隨內容變化，所以用 size.y 即可
	main_container.position.y = (window_size.y - main_container.size.y) / 2
	
	# 字體動態縮放
	if is_portrait:
		_update_ui_style(48, is_portrait) # 直式大字體
	else:
		_update_ui_style(36, is_portrait) # 橫式普通字體

func _update_ui_style(font_size: int, _is_portrait: bool):
	# 設定 Game Over 標題字體
	game_over_label.add_theme_font_size_override("font_size", font_size + 30)

# ---------------------------------------------------
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			_go_to_title()


func _go_to_title():
	print("返回主畫面")
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")

# ---------------------------------------------------
