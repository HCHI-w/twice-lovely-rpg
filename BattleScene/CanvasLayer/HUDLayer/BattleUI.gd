# BattleUI.gd
extends Control


@onready var enemy_status_container = %EnemyStatus

var battle_manager: BattleManager
var player_items = []   # 存 {combatant, ui}
var enemy_items = []    # 存 EnemyStatusItem 節點

# ---------------------------------------------------
func setup(manager: BattleManager):
	battle_manager = manager
	# 清空舊UI
	for child in $PlayerStatus.get_children():
		child.queue_free()
	# EnemyStatus
	for child in enemy_status_container.get_children():
		child.queue_free()
		
	player_items.clear()
	enemy_items.clear()
	# 動態建立每個角色UI
	for ally in battle_manager.allies:
		var item_scene = preload("res://Scenes/PlayerStatusItem.tscn")
		var item = item_scene.instantiate()
		
		$PlayerStatus.add_child(item)
		item.setup(ally)
		
		player_items.append({
			"combatant": ally,
			"ui": item
		})
		
	# 建立敵人 UI
	for enemy in battle_manager.enemies:
		var item_scene = preload("res://Scenes/EnemyStatusItem.tscn")
		var item = item_scene.instantiate()
		
		enemy_status_container.add_child(item)
		item.setup(enemy)
		enemy_items.append(item)
	
	if not battle_manager.stats_changed.is_connected(_on_stats_changed):
		battle_manager.stats_changed.connect(_on_stats_changed)
		
	if not battle_manager.damage_dealt.is_connected(_on_damage_dealt):
		battle_manager.damage_dealt.connect(_on_damage_dealt)
	
	# 玩家/敵人狀態的字體縮放
	for entry in player_items:
		var ui = entry["ui"]
		ui.update_stats()
		# 縮放 Label
		var window_size = get_viewport().get_visible_rect().size
		var name_label = ui.get_node_or_null("MainGrid/NameLabel")
		if name_label:
			scale_label_font(name_label, 20, window_size)
		
		var hp_label = ui.get_node_or_null("MainGrid/HPLabel")
		if hp_label:
			scale_label_font(hp_label, 18, window_size)
		
		var mp_label = ui.get_node_or_null("MainGrid/MPLabel")
		if mp_label:
			scale_label_font(mp_label, 18, window_size)
	
	for ui in enemy_items:
		ui.update_stats()
		var window_size = get_viewport().get_visible_rect().size
		var name_label = ui.get_node_or_null("MainGrid/NameLabel")
		if name_label:
			scale_label_font(name_label, 20, window_size)
		
		var hp_label = ui.get_node_or_null("MainGrid/HPLabel")
		if hp_label:
			scale_label_font(hp_label, 18, window_size)
		
		var mp_label = ui.get_node_or_null("MainGrid/MPLabel")
		if mp_label:
			scale_label_font(mp_label, 18, window_size)

# ---------------------------------------------------
# 更新血條和數值
func _on_stats_changed():
	update_ui()

func update_ui():
	for entry in player_items:
		var ui = entry["ui"]
		ui.update_stats()
		_apply_font_to_ui(ui)
	
	for ui in enemy_items:
		ui.update_stats()


func _apply_font_to_ui(ui):
	var window_size = get_viewport().get_visible_rect().size
	
	var name_label = ui.get_node_or_null("MainGrid/NameLabel")
	if name_label:
		scale_label_font(name_label, 20, window_size)
	
	var hp_label = ui.get_node_or_null("MainGrid/HPLabel")
	if hp_label:
		scale_label_font(hp_label, 18, window_size)
	
	var mp_label = ui.get_node_or_null("MainGrid/MPLabel")
	if mp_label:
		scale_label_font(mp_label, 18, window_size)


# ---------------------------------------------------
# 顯示傷害或補血數字
func _on_damage_dealt(target, amount, is_critical, _damage_type):
	if target == null:
		return

	# 找到對應的 UI
	var ui_node = null
	if target.is_enemy():
		for ui in enemy_items:
			if ui.combatant == target:
				ui_node = ui
				break
	else:
		for entry in player_items:
			if entry["combatant"] == target:
				ui_node = entry["ui"]
				break

	if ui_node == null:
		print("No UI found for target:", target.get_display_name())
		return

	# 生成傷害數字動畫
	var dmg_scene = preload("res://Scenes/DamageNumber.tscn")
	var dmg = dmg_scene.instantiate()
	add_child(dmg)

	if target.node_ref:
		var screen_pos = target.node_ref.get_global_transform_with_canvas().origin
		dmg.position = screen_pos + Vector2(0, -80)
	else:
		dmg.position = get_viewport_rect().size / 2

	dmg.show_damage(amount, is_critical, _damage_type)

	# 同步更新血條與數值
	ui_node.update_stats()

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
