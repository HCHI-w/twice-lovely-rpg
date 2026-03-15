# TurnOrderUI.gd
# 行動順序列表
extends PanelContainer

@onready var list_container: VBoxContainer = $VBoxContainer

var battle_manager: BattleManager

# ---------------------------------------------------
func setup(manager: BattleManager):
	battle_manager = manager
	
	# 當回合開始更新
	battle_manager.turn_started.connect(_on_turn_started)
	refresh()

# ---------------------------------------------------
func refresh():
	# 清空舊列表
	for child in list_container.get_children():
		child.queue_free()
	
	var queue = battle_manager.turn_queue
	var index = battle_manager.turn_index - 1
	
	# 重新生成
	for i in range(queue.size()):
		var combatant = queue[i]
		var label = Label.new()
		
		if i == index:
			label.text = "▶ " + combatant.get_display_name()
		else:
			label.text = combatant.get_display_name()
		
		# 字體自動縮放
		var window_size = get_viewport().get_visible_rect().size
		scale_label_font(label, 18, window_size)
		
		list_container.add_child(label)

# ---------------------------------------------------
func _on_turn_started(_current):
	refresh()

# ---------------------------------------------------
# 縮放 Label 字體
func scale_label_font(label_control: Control, base_size: int, window_size: Vector2):
	# 判斷目前是直式還是橫式
	var is_portrait = window_size.y > window_size.x
	
	var scale_factor: float
	if is_portrait:
		# 直式：以寬度為基準，但給予更高的倍率（例如基準寬度設小一點，讓字體顯大）
		scale_factor = window_size.x / 720.0 
	else:
		# 橫式：以 1920 為基準
		scale_factor = window_size.x / 1920.0
	
	var final_size = int(base_size * scale_factor)
	
	# 直式模式下，強制提升最小字體大小，避免手機看不清楚
	var min_font = 24 if is_portrait else 20
	var max_font = 28 if is_portrait else 28
	
	final_size = clamp(final_size, min_font, max_font)
	# Label 與 Button 都可以用這個方法
	label_control.add_theme_font_size_override("font_size", final_size)
	
# ---------------------------------------------------
