# ResultScene.gd
extends Node2D
class_name ResultScene


@export var display_time: float = 3.0

# 信號：告訴 BattleScene 結算完成，可以進入營地
signal finished

@onready var color_rect = $Control/ColorRect
@onready var drop_panel = $Control/DropPanel
@onready var walk_container = $Control/WalkContainer
@onready var win_label = $Control/DropPanel/WINLabel
@onready var drop_label = $Control/DropPanel/DropLabel
@onready var drop_list = $Control/DropPanel/DropList
@onready var continue_button = $Control/DropPanel/Button


# 當前這場掉落物品
var drops: Array = []
# 新增旗標 確保 結算畫面只進入一次
var finished_triggered: bool = false

# 增加一個變數來控制「是否允許點擊」
var can_skip: bool = false


# ---------------------------------------------------
func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	set_process_input(true)
	
	# 連接視窗縮放信號
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()   # 初始化排版

# ---------------------------------------------------
# 核心：處理直橫式切換與字體
func _on_window_resized():
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	# 調整背景全螢幕
	color_rect.size = window_size
	
	# 調整 DropPanel (主要的文字與掉落物區)
	# 讓它寬度隨螢幕縮放，並置中
	drop_panel.size.x = window_size.x * 0.95
	drop_panel.position.x = (window_size.x - drop_panel.size.x) / 2
	drop_panel.position.y = window_size.y * 0.40
	
	# 調整 WalkContainer (角色跑步區)
	# 讓它在直式時水平排列，並位於畫面中下段
	walk_container.size.x = window_size.x
	walk_container.position.x = 0
	walk_container.position.y = window_size.y * 0.6   # 放在 60% 高度處
	
	if is_portrait:
		# 直式：掉落清單如果太多，可以考慮改成 Grid 或讓它自動換行
		drop_list.alignment = BoxContainer.ALIGNMENT_CENTER
		_update_fonts(46, 36) # 直式字體加大 (標題, 內文)
	else:
		# 橫式
		drop_list.alignment = BoxContainer.ALIGNMENT_CENTER
		_update_fonts(28, 20)

# 輔助：統一更新字體大小
func _update_fonts(title_size: int, normal_size: int):
	# 增加安全檢查，避免節點為空時噴錯
	if win_label: win_label.add_theme_font_size_override("font_size", title_size + 30)   # WIN 大一點
	if drop_label: drop_label.add_theme_font_size_override("font_size", normal_size)
	if continue_button: continue_button.add_theme_font_size_override("font_size", normal_size + 2)   # 讓按鈕字體大一點
	
	# 更新掉落清單裡的物品名稱
	for item_vbox in drop_list.get_children():
		for child in item_vbox.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size", normal_size - 2)

# ---------------------------------------------------
func setup(drops_in: Array):
	# 旗標重置
	finished_triggered = false
	can_skip = false   # 剛開始不允許跳過
	
	# 在顯示資料前，先讓轉場系統把畫面「遮住」
	# 用「立即變黑」方式，避免穿幫
	TransitionManager.transition_instance.show()
	TransitionManager.transition_instance.rect.modulate.a = 1.0
	
	# 準備資料
	drops = drops_in
	_show_drops()
	_play_walk_animations()
	
	# 資料準備好後，呼叫轉場系統的「淡出」
	# 等待黑幕慢慢消失
	await TransitionManager.transition_instance.fade_out(1.0)  # 給它 1 秒
	TransitionManager.transition_instance.hide()
	
#	await get_tree().create_timer(0.5).timeout # 額外給 0.5 秒
	can_skip = true                            # 拔掉插銷，現在可以點擊了！
	print("結算畫面現在可以點擊跳過了")

# ---------------------------------------------------
# 顯示掉落物品
func _show_drops():
	# 清掉舊物件
	for child in drop_list.get_children():
		child.queue_free()
	
	if drops.is_empty():
		drop_label.text = "本場戰鬥沒有掉落物品"
	else:
		drop_label.text = "本場戰鬥獲得的收藏品："
		for drop in drops:
			var item_vbox = VBoxContainer.new()
			item_vbox.alignment = BoxContainer.ALIGNMENT_CENTER   # 置中
			
			# 物品圖片
			var icon_rect = TextureRect.new()
			icon_rect.texture = drop.icon
			# 設定圖片縮放模式，避免變形
			icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			# 給圖片一個最小尺寸，不然在容器裡可能會縮成 0
			icon_rect.custom_minimum_size = Vector2(80, 80)   # 直式建議大一點
			
			# 物品名稱
			var label = Label.new()
			label.text = drop.display_name
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			item_vbox.add_child(icon_rect)
			item_vbox.add_child(label)
			# 加上物品名稱提示
			drop_list.add_child(item_vbox)
	
	# 等待一幀讓節點完全就緒
	await get_tree().process_frame
	# 跑完後立即更新一次字體
	_on_window_resized()

# ---------------------------------------------------
# 播放角色跑步動畫（假設已經有動畫設定在 PlayerX 節點）
func _play_walk_animations():
	for player in walk_container.get_children():
		# 使用安全檢查，避免沒找到 AnimationPlayer 導致當機
		var anim_player = player.get_node_or_null("AnimationPlayer")
		if anim_player and anim_player.has_animation("Run"):
			anim_player.play("Run")
	
	print("播放行走動畫（未實作）")

# ---------------------------------------------------
# 點擊按鈕或畫面任意位置進入營地
func _on_continue_pressed():
	# 如果已經結束了，或者「還不能跳過」，就直接退回，不執行任何動作
	if finished_triggered or not can_skip:
		return
	
	finished_triggered = true
	emit_signal("finished")

# ---------------------------------------------------
func _input(event):
	if finished_triggered or not can_skip:
		return
	
	if event is InputEventMouseButton and event.pressed:
		finished_triggered = true
		emit_signal("finished")

# ---------------------------------------------------
