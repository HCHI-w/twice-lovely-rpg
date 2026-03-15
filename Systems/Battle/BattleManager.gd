# 控制戰鬥邏輯
extends Node
class_name BattleManager

# ---------------------------------------------------
signal targets_updated(targets)
signal player_turn_started
signal stats_changed
signal damage_dealt(target, amount, is_critical, damage_type)
signal battle_finished(victory: bool)
signal turn_started(combatant)

enum BattleState {
	ROUND_START,
	TURN_START,
	ACTION_SELECT,
	TARGET_SELECT,
	ACTION_EXECUTE,
	TURN_END,
	BATTLE_END
}

var allies: Array[Combatant] = []
var enemies: Array[Combatant] = []
var selectable_targets: Array[Combatant] = []

var turn_queue: Array[Combatant] = []
var turn_index: int = 0

var state: int = BattleState.ROUND_START
var current_combatant: Combatant
var current_target: Combatant

var waiting_for_player_input: bool = false
var selected_action: BattleAction = null

@export var turn_delay: float = 0.3

# ---------------------------------------------------
# 初始化戰鬥
func setup(party_members: Array[PartyMember], enemy_data: EnemyData):
	allies.clear()
	enemies.clear()
	turn_queue.clear()
	# 建立 Allies
	for m in party_members:
		allies.append(Combatant.new(m))
	# 建立 Enemy
	enemies.append(Combatant.from_enemy_data(enemy_data))
	# 生成行動順序
	build_turn_queue()

# 建立行動順序
func build_turn_queue():
	turn_queue.clear()
	for c in allies + enemies:
		if c.is_alive:
			turn_queue.append(c)
	#依Dex由高到低排序
	turn_queue.sort_custom(func(a, b):
		return a.get_dex() > b.get_dex()
	)
	print("=== Turn Queue Built ===")
	for c in turn_queue:
		print(c.get_display_name(), " Dex:", c.get_dex())

# ---------------------------------------------------
# 戰鬥開始
func start_battle():
	print("=== Battle Start ===")
	turn_index = 0
	start_next_turn()

# 進入下一回合/下一個行動者
func start_next_turn():
	if is_battle_over():
		state = BattleState.BATTLE_END
		print("=== Battle End ===")
		end_battle()
		return
		
	if turn_index >= turn_queue.size():
		build_turn_queue()
		turn_index = 0
		state = BattleState.ROUND_START
		print("=== New Round ===")
	
	# 取得下一個存活的行動者
	while turn_index < turn_queue.size():
		current_combatant = turn_queue[turn_index]
		turn_index += 1
		if current_combatant.is_alive:
			state = BattleState.TURN_START
			process_turn_start()
			return
	# 如果這回合沒人了 → 新回合
	build_turn_queue()
	turn_index = 0
	state = BattleState.ROUND_START
	print("=== New Round ===")
	start_next_turn()

# 回合開始
func process_turn_start():
	# 如果已經死了，直接跳過
	if not current_combatant.is_alive:
		start_next_turn()
		return
	# 回合開始先處理狀態
	current_combatant.update_buffs()
	# 如果因持續傷害 → 死亡
	if not current_combatant.is_alive:
		start_next_turn()
		return
		
	print(">> Turn:", current_combatant.get_display_name())
	turn_started.emit(current_combatant)
	
	# 如果被暈眩
	if current_combatant.is_stunned():
		print(current_combatant.get_display_name(), " 被暈眩無法攻擊!")
		# --- 視覺提示 ---
		_show_skill_shout(current_combatant, "暈眩中...")   # 寫好的文字飄浮功能
		_play_shake_anim(current_combatant)   # 寫好的晃動動畫
		# 稍微停頓一下，讓玩家看清楚發生什麼事
		await get_tree().create_timer(1.0).timeout
		
		start_next_turn()
		return
		
	# 目標(每次只有一個敵人)
	if current_combatant.is_enemy():
		if allies.size() > 0:
			current_target = allies[0]

	if not current_combatant.is_enemy():
		state = BattleState.ACTION_SELECT
		waiting_for_player_input = true
		print("Player turn: 選擇動作...")
		player_turn_started.emit()
		# 這裡不呼叫 execute，等待玩家輸入
	else:
		state = BattleState.ACTION_EXECUTE
		enemy_execute()

# ---------------------------------------------------
# 玩家按鈕觸發:傳入 BattleAction
func receive_player_action(action: BattleAction):
	if state != BattleState.ACTION_SELECT:
		return
		
	selected_action = action
	# 如果是技能
	if action is SkillAction:
		var skill = action.skill_data
		# self 或 全體技能 不需要選擇目標
		if skill.target_type in ["self", "all_enemies", "all_allies"]:
			state = BattleState.ACTION_EXECUTE
			execute_action(action)
			return
		# 需要選擇目標 → 先取得名單 
		selectable_targets = get_valid_targets(skill, current_combatant)
		if selectable_targets.is_empty():
			print("沒有可復活的對象")
			
			selected_action = null
			state = BattleState.ACTION_SELECT
			# 通知 UI 重新開啟選單
			player_turn_started.emit()
			return
	else:
		# 普通攻擊 → 自動選第一個活著的敵人
		var alive_enemies = enemies.filter(func(c): return c.is_alive)
		if alive_enemies.is_empty():
			start_next_turn()
			return
		
		current_target = alive_enemies[0]   # 自動選第一個
		
		state = BattleState.ACTION_EXECUTE
		execute_action(action)
		return
	# 進入選擇目標狀態
	state = BattleState.TARGET_SELECT
	targets_updated.emit(selectable_targets)
	print("State:", state)
	print("選擇目標...")
	for t in selectable_targets:
		print("-", t.get_display_name())
	

func receive_target(target: Combatant):
	if state != BattleState.TARGET_SELECT:
		return
		
	if not selectable_targets.has(target):
		print("Invalid target!")
		return
		
	current_target = target
	print("Target received: ", target.get_display_name())
	
	state = BattleState.ACTION_EXECUTE
	execute_action(selected_action)

# ---------------------------------------------------
# 敵人自動執行動作
func enemy_execute():
	var action = current_combatant.choose_attack_action()
	# 取得可攻擊的目標 (活的 allies)
	var possible_targets = allies.filter(func(c): return c.is_alive)
	
	if possible_targets.is_empty():
		start_next_turn()
		return
		
	current_target = possible_targets[0]   # 先選第一個
	
	# 延遲 0.5 ~ 1 秒 看想延遲的時間調整
	var delay = 1.0
	await get_tree().create_timer(delay).timeout
	
	execute_action(action)

# ---------------------------------------------------
# 執行動作
func execute_action(action: BattleAction):
	print("Executing action...")

	var targets = get_targets(action)
	# 目標不存在或已死亡
	if targets.is_empty():
		print("目標已死亡")
		start_next_turn()
		return
	
	# --- 攻擊者跳起來 & 喊招式 ---
	_play_jump_anim(current_combatant)
	if action is SkillAction:
		_show_skill_shout(current_combatant, action.skill_data.skill_name)
		
	# ------------------------
	var results = []
	
	for t in targets:
		# --- 被攻擊者晃動 ---
		_play_shake_anim(t)
		
		# ------------------------
		var r = action.execute(current_combatant, t)
		results.append_array(r)
		
		for result in r:
			# result 應該包含 damage 資訊
			if result.has("amount"):
				# 做個保險，讓它兩個標籤都認得
				var crit_flag = result.get("is_critical", false)   # 先找 is_critical
				if not crit_flag:
					crit_flag = result.get("critical", false)     # 如果沒有，再找 critical
				
				print("CRIT FLAG:", crit_flag)
				damage_dealt.emit(
					t,
					result["amount"],
					crit_flag,    # 使用我們抓到的正確布林值
					result.get("damage_type", "PHYSICAL")
				)
		stats_changed.emit()
	
	# 清空選擇
	selected_action = null
	current_target = null
	
	state = BattleState.TURN_END
	await get_tree().create_timer(turn_delay).timeout
	start_next_turn()

# 選擇對象
func get_targets(action: BattleAction) -> Array[Combatant]:
	var result: Array[Combatant] = []
	#普通攻擊沒有 SkillData → 當成單體敵人
	if action is SkillAction:
		var skill = action.skill_data
		
		match skill.target_type:
			"single_enemy":
				result.append(current_target)
			"single_ally":
				result.append(current_target)
			"self":
				result.append(current_combatant)
			"all_enemies":
				if not current_combatant.is_enemy():
					result = enemies.filter(func(c): return c.is_alive)
				else:
					result = allies.filter(func(c): return c.is_alive)
			"all_allies":
				if not current_combatant.is_enemy():
					result = allies.filter(func(c): return c.is_alive)
				else:
					result = enemies.filter(func(c): return c.is_alive)
	else:
		#普通攻擊
		result.append(current_target)
		
	return result

# 限制目標選擇
func get_valid_targets(skill: SkillData, user: Combatant) -> Array[Combatant]:
	var targets: Array[Combatant] = []
	var user_allies: Array[Combatant]
	var user_enemies: Array[Combatant]
	
	if user.is_enemy():
		user_allies = enemies
		user_enemies = allies
	else:
		user_allies = allies
		user_enemies = enemies
	
	match skill.effect_type:
		SkillData.EffectType.REVIVE:
			targets = user_allies.filter(func(c): return c.is_dead())
		SkillData.EffectType.HEAL:
			targets = user_allies.filter(func(c): return c.is_alive)
		SkillData.EffectType.BUFF:
			targets = user_allies.filter(func(c): return c.is_alive)
		SkillData.EffectType.DAMAGE:
			targets = user_enemies.filter(func(c): return c.is_alive)
		_:
			targets = []
	print("Skill target type:", skill.target_type)
	return targets

# ---------------------------------------------------
# 戰鬥結束判斷
func is_battle_over() -> bool:
	var allies_alive = allies.any(func(c): return c.is_alive)
	var enemies_alive = enemies.any(func(c): return c.is_alive)
	
	if not allies_alive:
		print("=== All Allies Defeated ===")
		return true
	if not enemies_alive:
		print("=== All Enemies Defeated ===")
		return true
		
	return false

# 戰鬥結束清除 buff
func end_battle():
	print("Cleaning up battle...")
	
	for member in GameManager.party.get_members():
		member.clear_buffs()
	
	var victory = enemies.any(func(c): return c.is_alive) == false
	for c in allies:
		for b in c.active_buffs:
			c.clear_buffs()
		
	for c in enemies:
		for b in c.active_buffs:
			c.clear_buffs()
		
	battle_finished.emit(victory)

# --------------------------------------------------------------------------------------
# 玩家選擇攻擊
func player_chose_attack():
	print("選擇攻擊")
	
	var action = current_combatant.choose_attack_action()
	receive_player_action(action)

# 玩家選擇技能
func player_chose_skill(skill_data: SkillData):
	print("選擇技能：", skill_data.skill_name)
	
	if skill_data == null:
		print("No skill available")
		return
	
	if current_combatant.current_mp < skill_data.mp_cost:
		print("MP 不足")
		return  # 不進入 receive_player_action
	
	var action = SkillAction.new(skill_data)
	receive_player_action(action)

# ---------------------------------------------------
# --- 演出動畫工具 (Tween) ---
# 跳躍動畫 (攻擊者用)
func _play_jump_anim(combatant: Combatant):
	var node = combatant.node_ref
	if not node: return
	var tween = create_tween()
	# 往上跳 (y 軸減少)
	tween.tween_property(node, "position", node.position + Vector2(0, -30), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 掉回來 (回到原位)
	tween.tween_property(node, "position", node.position, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# 晃動動畫 (被攻擊者用)
func _play_shake_anim(combatant: Combatant):
	var node = combatant.node_ref
	if not node: return
	var tween = create_tween()
	var orig = node.position
	# 快速左右晃動
	tween.tween_property(node, "position", orig + Vector2(10, 0), 0.05)
	tween.tween_property(node, "position", orig + Vector2(-10, 0), 0.05)
	tween.tween_property(node, "position", orig, 0.05)

# 喊出招式名 (標籤飄浮)
func _show_skill_shout(combatant: Combatant, skill_name: String):
	var node = combatant.node_ref
	if not node: return
	
	var label = Label.new()
	label.text = "【" + skill_name + "！】"
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	
	node.add_child(label)
	label.position = Vector2(-60, -100) # 出現在角色頭上
	
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.finished.connect(label.queue_free)

# ---------------------------------------------------
