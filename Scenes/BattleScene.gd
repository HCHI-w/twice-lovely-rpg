# BattleScene.gd
# 控制關卡流程
extends Node2D

# ---------------------------------------------------
# 在 BattleScene.gd 頂部先取得 CanvasLayer 的引用
@onready var canvas_layer = $BattleRoot/CanvasLayer
@onready var battle_root = $BattleRoot
@onready var battle_manager = $BattleRoot/BattleManager
@onready var player_container = $BattleRoot/PlayerContainer
# 取得新的底層大容器引用
@onready var main_bottom_ui = $BattleRoot/CanvasLayer/MainBottomUI
@onready var action_panel = $BattleRoot/CanvasLayer/MainBottomUI/ActionPanel
@onready var skill_name_label = $BattleRoot/CanvasLayer/MainBottomUI/ActionPanel/DescriptionVBox/SkillNameLabel
@onready var skill_desc_label = $BattleRoot/CanvasLayer/MainBottomUI/ActionPanel/DescriptionVBox/SkillDescriptionLabel
@onready var turn_label = $BattleRoot/CanvasLayer/MainBottomUI/BattleUI/TurnLabel
@onready var turn_order_ui = $BattleRoot/CanvasLayer/TurnOrderPanel
@onready var player_slots = [
	$BattleRoot/PlayerContainer/PlayerSlot1,
	$BattleRoot/PlayerContainer/PlayerSlot2,
	$BattleRoot/PlayerContainer/PlayerSlot3
]

# 切換場景用
var result_scene: ResultScene
var camp_scene: Node

# 原始敵人池（固定）
var enemy_pool: Array[EnemyData] = []
# 本輪可用敵人池（會被消耗）
var available_enemies: Array[EnemyData] = []
# 記住當前關卡的 EnemyData
var current_enemy_data: EnemyData
var last_drops: Array = []
# 關卡計數
var current_stage: int = 1
const MAX_STAGE: int = 5

# ---------------------------------------------------
func _ready():
	GameFlowManager.state_changed.connect(_on_state_changed)
	
	# 載入敵人
	enemy_pool = [
		preload("res://Resources/Enemy/bread.tres"),
		preload("res://Resources/Enemy/chocolate.tres"),
		preload("res://Resources/Enemy/fried_chicken.tres"),
		preload("res://Resources/Enemy/gummy_bear.tres"),
		preload("res://Resources/Enemy/jokbal.tres"),
		preload("res://Resources/Enemy/ketchup.tres"),
		preload("res://Resources/Enemy/spicy_beef.tres"),
		preload("res://Resources/Enemy/yogurt.tres")
	]
	
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.targets_updated.connect(_on_targets_updated)
	battle_manager.player_turn_started.connect(_on_player_turn_started)
	battle_manager.battle_finished.connect(_on_battle_finished)
	action_panel.attack_pressed.connect(_on_attack_pressed)
	action_panel.skill_pressed.connect(_on_skill_pressed)
	battle_manager.damage_dealt.connect(_on_damage_dealt)
	turn_order_ui.setup(battle_manager)
	
	# 連接視窗大小改變的信號，這樣縮放視窗時會自動觸發
	get_tree().root.size_changed.connect(_on_window_resized)
	
	# 初始化執行一次
	_on_window_resized()
	
	connect_slot_clicks()
	start_battle()

# ---------------------------------------------------
# 自動調整佈局的邏輯
# ---------------------------------------------------
# on_window_resized
func _on_window_resized():
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	update_background(window_size)
	update_character_positions(window_size, is_portrait)
	update_ui_layout(window_size, is_portrait)
	turn_order_ui.refresh()

# 背景
func update_background(window_size):
	$BattleRoot/ColorRect.size = window_size

# 玩家敵人位置
func update_character_positions(window_size, is_portrait):
	if is_portrait:
		$BattleRoot/EnemyContainer.global_position = Vector2(
			window_size.x * 0.3,
			window_size.y * 0.15
		)
	
		player_container.global_position = Vector2(
			window_size.x * 0,
			window_size.y * 0.46
		)
	else:
		$BattleRoot/EnemyContainer.global_position = Vector2(
			window_size.x * 0.58,
			window_size.y * 0.15
		)
		
		player_container.global_position = Vector2(
			window_size.x * 0.05,
			window_size.y * 0.5
		)

# UI
func update_ui_layout(_window_size, is_portrait):
	if is_portrait:
		main_bottom_ui.vertical = true
	else:
		main_bottom_ui.vertical = false
	
#	scale_label_font(skill_name_label, 20, window_size)
#	scale_label_font(skill_desc_label, 40, window_size)


# ---------------------------------------------------
# 縮放 Label 字體
#func scale_label_font(label_control: Control, base_size: int, window_size: Vector2):
	# 判斷目前是直式還是橫式
#	var is_portrait = window_size.y > window_size.x
	
#	var scale_factor: float
#	if is_portrait:
		# 直式：以寬度為基準，但給予更高的倍率（例如基準寬度設小一點，讓字體顯大）
#		scale_factor = window_size.x / 720.0 
#	else:
		# 橫式：以 1920 為基準
#		scale_factor = window_size.x / 1920.0
	
#	var final_size = int(base_size * scale_factor)
	
	# 直式模式下，強制提升最小字體大小，避免手機看不清楚
#	var min_font = 38 if is_portrait else 36
#	var max_font = 42 if is_portrait else 40
	
#	final_size = clamp(final_size, min_font, max_font)
	# Label 與 Button 都可以用這個方法
#	label_control.add_theme_font_size_override("font_size", final_size)

# ---------------------------------------------------
# 切換場景
func _on_state_changed(new_state):
	match new_state:
		GameFlowManager.GameState.BATTLE:
			_show_battle()
		GameFlowManager.GameState.RESULT:
			_show_result()
		GameFlowManager.GameState.CAMP:
			_show_camp()

# 戰鬥畫面
func _show_battle():
	battle_root.show()
	canvas_layer.show()   # 確保戰鬥 UI 顯示出來
	
	if result_scene:
		result_scene.queue_free()
		result_scene = null
	if camp_scene:
		camp_scene.queue_free()
		camp_scene = null
		
	# 如果不是第一關，就開始下一關
	if current_stage > 1:
		_start_stage(current_stage)

# 結算畫面
func _show_result():
	battle_root.hide()
	canvas_layer.hide()   # 一直找很久的問題點，CanvasLayer 層級太高，要把它藏起來
	
	var scene = preload("res://Scenes/ResultScene.tscn")
	result_scene = scene.instantiate()
	add_child(result_scene)   # 將結算畫面加進來
	
	result_scene.setup(last_drops)
	result_scene.finished.connect(_on_result_finished)

# 結算完成 → 進入營地
func _on_result_finished():
	# 玩家在結算畫面點擊了「繼續」
	current_stage += 1
	
	if current_stage > MAX_STAGE:
		print("=== 最終關卡結算完成，回到主畫面 ===")
		# 避免畫面直接被切掉
	#	await TransitionManager.show_stage_title(0.5)   # 或是顯示「冒險達成」
		# 轉場效果回主畫面
		TransitionManager.change_scene("res://Scenes/TitleScreen.tscn", "冒險結束！", false)
	else:
		print("=== 準備進入營地休息 ===")
		GameFlowManager.go_to_camp()

# 顯示營地
func _show_camp():
	if result_scene:
		result_scene.queue_free()
		result_scene = null
	
	var scene = load(get_camp_scene_path())
	camp_scene = scene.instantiate()
	
	# 加到場景樹根節點，而不是 BattleScene
	get_tree().root.add_child(camp_scene)
	
	camp_scene.depart_pressed.connect(_on_depart_pressed)

# 切換場景 CampScene
func get_camp_scene_path():
	var size = get_viewport().get_visible_rect().size
	return "res://Scenes/CampScene_Portrait.tscn" if size.y > size.x \
		else "res://Scenes/CampScene_Landscape.tscn"

# 離開營地
func _on_depart_pressed():
	GameFlowManager.go_to_battle()

# ---------------------------------------------------
func connect_slot_clicks():
	for slot in player_slots:
		slot.slot_clicked.connect(_on_slot_clicked.bind(slot))


func _on_slot_clicked(_viewport, _event, _shape_idx, slot):
	if battle_manager.state != BattleManager.BattleState.TARGET_SELECT:
		return
	
	var combatant = get_combatant_from_slot(slot)
	if combatant == null:
		return
	
	battle_manager.receive_target(combatant)


func get_combatant_from_slot(slot):
	for c in battle_manager.allies:
		if c.node_ref == slot:
			return c
	
	for c in battle_manager.enemies:
		if c.node_ref == slot:
			return c
	
	return null

func _on_targets_updated(_targets):
	print("進入目標選擇模式")
	
# ---------------------------------------------------
# 高亮系統
func _on_turn_started(combatant):
	_update_turn_indicator(combatant)

func _update_turn_indicator(combatant):
	# 清除所有高亮
	_clear_all_highlights()
	
	# 顯示名字
	turn_label.text = "現在行動：%s" % combatant.get_display_name()
	
	# 角色高亮
#	if combatant.node_ref:
#		var sprite = combatant.node_ref.get_node("Sprite2D")
#		sprite.modulate = Color(1, 1, 0.8)  # 偏黃高亮

# 清除高亮
func _clear_all_highlights():
	for c in battle_manager.allies:
		if c.node_ref:
			c.node_ref.get_node("TextureRect").modulate = Color(1,1,1)
	
	for c in battle_manager.enemies:
		if c.node_ref:
			c.node_ref.get_node("TextureRect").modulate = Color(1,1,1)

# ---------------------------------------------------
func start_battle():
	current_stage = 1
	
	# 每次新遊戲重置可用敵人池
	available_enemies = enemy_pool.duplicate()
	available_enemies.shuffle()   # 隨機排序一次
	# 呼叫關卡
	_start_stage(current_stage)

func _start_stage(stage: int):
	print("=== 開始第 %d 關 ===" % stage)
	
	# 敵人資料
	if available_enemies.is_empty():
		push_error("沒有可用敵人了！")
		return
	
	current_enemy_data = available_enemies.pop_front()
	battle_manager.setup(GameManager.party.get_members(), current_enemy_data)
	bind_combatant_nodes()   # 敵人貼圖
	
	$BattleRoot/CanvasLayer/MainBottomUI/BattleUI.setup(battle_manager)
	
	# 只連一次信號
	if not battle_manager.stats_changed.is_connected($BattleRoot/CanvasLayer/MainBottomUI/BattleUI._on_stats_changed):
		battle_manager.stats_changed.connect($BattleRoot/CanvasLayer/MainBottomUI/BattleUI._on_stats_changed)
	if not battle_manager.damage_dealt.is_connected($BattleRoot/CanvasLayer/MainBottomUI/BattleUI._on_damage_dealt):
		battle_manager.damage_dealt.connect($BattleRoot/CanvasLayer/MainBottomUI/BattleUI._on_damage_dealt)
	
	# 確保資料都換好，把黑幕拿掉
	await TransitionManager.show_stage_title(stage)
	
	# 開始戰鬥
	battle_manager.start_battle()
	$BattleRoot/CanvasLayer/MainBottomUI/BattleUI.update_ui()
	
# ---------------------------------------------------
func bind_combatant_nodes():
	# 綁定玩家
	for i in range(player_slots.size()):
		var node = player_slots[i]
		
		if i < battle_manager.allies.size():
			var combatant = battle_manager.allies[i]
			combatant.node_ref = node
			
			var texture_rect = node.get_node("TextureRect")
			texture_rect.texture = combatant.battle_texture
			texture_rect.visible = true
		
	# 綁定敵人
	for i in range(battle_manager.enemies.size()):
		var combatant = battle_manager.enemies[i]
		var node = $BattleRoot/EnemyContainer/EnemySlot
		
		var texture_rect: TextureRect
		
		if node is TextureRect:
			texture_rect = node
		else:
			texture_rect = node.get_node("TextureRect")
			
		texture_rect.texture = combatant.battle_texture


# ---------------------------------------------------
func _on_player_turn_started():
	var skills = battle_manager.current_combatant.get_available_skills()
	
	if skills.size() > 0:
		action_panel.set_skill(skills[0])   # 先測試第一招
	else:
		action_panel.set_skill(null)
	
	action_panel.show()

# ---------------------------------------------------
func _on_attack_pressed():
	print("Attack button pressed")
	$BattleRoot/CanvasLayer/MainBottomUI/ActionPanel.hide()
	battle_manager.player_chose_attack()
	
func _on_skill_pressed(skill_data: SkillData):
	print("Skill button pressed")
	$BattleRoot/CanvasLayer/MainBottomUI/ActionPanel.hide()
	battle_manager.player_chose_skill(skill_data)

# ---------------------------------------------------
# 顯示傷害數字
func _on_damage_dealt(target, amount, is_critical, damage_type):
	if target.node_ref == null:
		return
	
	var damage_number = DamageNumber.new()

	target.node_ref.add_child(damage_number)
	
	damage_number.position = Vector2(0, -40)
	damage_number.show_damage(amount, is_critical, damage_type)

# ---------------------------------------------------
func _on_battle_finished(victory: bool):
	if victory:
		await get_tree().create_timer(0.9).timeout
		# 不論哪一關，只要贏了就先生成掉落物
		_generate_drops()
		
		# 進入結算畫面 (ResultScene)
		# 讓結算畫面顯示剛才生成的 last_drops
		GameFlowManager.go_to_result()
		
	else:
		print("Game Over")
		_show_game_over()

# ---------------------------------------------------
# 收藏品掉落
func _generate_drops():
	last_drops.clear()
	
	if current_enemy_data == null:
		return
	
	# 掉落機率
	var roll = randf()
	var drop: CollectibleData
	
	if roll <= 0.7:
		drop = current_enemy_data.drop_common
	else:
		drop = current_enemy_data.drop_rare
	
	if drop != null:
		last_drops.append(drop)
		CollectibleManager.add_collectible(drop)
		print("獲得收藏品:", drop.display_name)

# ---------------------------------------------------
# 回營地動畫
func go_back_to_camp() -> void:
	print("播放回營地動畫")
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	print("角色回到營地")
	
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween2.finished

# ---------------------------------------------------
# Game Over
func _show_game_over():
	battle_root.hide()
	canvas_layer.hide()
	
	var scene = preload("res://Scenes/GameOverScene.tscn")
	var game_over = scene.instantiate()
	
	add_child(game_over)

# ---------------------------------------------------
func _exit_tree():
	if battle_manager:
		if battle_manager.player_turn_started.is_connected(_on_player_turn_started):
			battle_manager.player_turn_started.disconnect(_on_player_turn_started)
			
		if battle_manager.targets_updated.is_connected(_on_targets_updated):
			battle_manager.targets_updated.disconnect(_on_targets_updated)
			
		if battle_manager.battle_finished.is_connected(_on_battle_finished):
			battle_manager.battle_finished.disconnect(_on_battle_finished)

# ---------------------------------------------------
