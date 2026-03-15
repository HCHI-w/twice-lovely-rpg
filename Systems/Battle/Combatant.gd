extends RefCounted
class_name Combatant

var member: PartyMember = null
var enemy: Enemy = null

var current_hp: int
var current_mp: int = 0
var is_alive: bool = true
var has_acted: bool = false
var battle_texture: Texture2D

var active_buffs: Array[BuffInstance] = []

var node_ref: CanvasItem = null   # 新增：對應畫面節點

# ---------------------------------------------------
func _init(source):
	if source is PartyMember:
		member = source
		current_hp = source.current_hp
		current_mp = source.current_mp
		battle_texture = source.character_data.battle_texture

	elif source is Enemy:
		enemy = source
		current_hp = source.current_hp
		current_mp = source.current_mp
		battle_texture = source.data.battle_texture

	else :
		push_error("Combatant init with invalid source")

# ---------------------------------------------------
# 靜態工廠函數：直接從 EnemyData 建立 Combatant
static func from_enemy_data(d: EnemyData) -> Combatant:
	return Combatant.new(Enemy.new(d))

# ---------------------------------------------------
# 判斷是否為敵人
func is_enemy() -> bool:
	return enemy != null

# ---------------------------------------------------
# 屬性讀取
func get_max_hp() -> int:
	return member.get_max_hp() if member else enemy.get_hp()

func get_max_mp() -> int:
	return member.get_max_mp() if member else enemy.get_mp()

func get_str() -> int:
	return member.get_final_str() if member else enemy.get_str()

func get_def() -> int:
	return member.get_final_def() if member else enemy.get_def()

func get_int() -> int:
	return member.get_final_int() if member else enemy.get_int()

func get_dex() -> int:
	return member.get_final_dex() if member else enemy.get_dex()

func get_luk() -> int:
	return member.get_final_luk() if member else enemy.get_luk()

# ---------------------------------------------------
# 影響屬性數值
func get_stat(stat_name: String) -> int:
	var base = 0

	match stat_name:
		"hp": base = get_max_hp()
		"mp": base = get_max_mp()
		"str": base = get_str()
		"def": base = get_def()
		"int": base = get_int()
		"dex": base = get_dex()
	# Buff 計算
	var flat_bonus = 0
	var percent_bonus = 0.0
	
	for buff in active_buffs:
		flat_bonus += buff.data.stats_flat.get(stat_name, 0)
		percent_bonus += buff.data.stats_percent.get(stat_name, 0.0)
		
	base += flat_bonus
	base = int(base * (1.0 + percent_bonus))
	
	return base

func take_damage(amount: int):
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		is_alive = false
		print(get_display_name()," has fallen!")
	else:
		is_alive = true

func get_display_name() -> String:
	if member:
		return "%s %s" % [member.class_data.display_name,member.character_data.display_name]
	else:
		return enemy.data.name

# ---------------------------------------------------
# 攻擊力讀取，Buff影響能力 交給 PartyMember / Enemy 各自決定
func get_physical_attack() -> int:
	if member:
		return member.get_physical_attack()
	elif enemy:
		return enemy.get_physical_attack()
	return 0

func get_magic_attack() -> int:
	if member:
		return member.get_magic_attack()
	else :
		return enemy.get_magic_attack()

# 回傳傷害給 BattleAction
func receive_attack(attacker: Combatant, is_physical: bool = true) -> int:
	var damage: int
	if is_physical:
		# 使用 Combatant 現有屬性計算傷害
		damage = max(1, attacker.get_physical_attack() - get_def())
	else:
		# 魔法傷害計算
		damage = max(1, attacker.get_magic_attack() - get_int())
	take_damage(damage)
	return damage

# ---------------------------------------------------
# 是否死亡判斷
func is_dead() -> bool:
	return current_hp <= 0

# 針對活著的
func heal(amount: int):
	if is_dead():
		return   # 死亡不能被治療
	
	current_hp += amount
	if current_hp > get_max_hp():
		current_hp = get_max_hp()

# 針對死掉的
func revive(percent: float = 0.3):
	if not is_dead():
		return
		
	current_hp = int(get_max_hp() * percent)   # 復活後恢復百分比血量
	is_alive = true

# ---------------------------------------------------
# 新增技能來源
func get_skill_list() -> Array[SkillData]:
	var result: Array[SkillData] = []
	
	if member and member.class_data:
		result = member.class_data.skill_list.duplicate()
	elif enemy and enemy.data:
		result = enemy.data.skill_list.duplicate()
	return result

# 可用技能列表
func get_available_skills() -> Array[SkillData]:
	var result: Array[SkillData] = []
	for s in get_skill_list():
		if current_mp >= s.mp_cost:
			result.append(s)
	return result

func choose_attack_action() -> BattleAction:
	# 敵人AI　判斷是否使用技能
	if is_enemy():
		var skills = get_available_skills()
		if skills.size() > 0 and randf() < 0.5:
			var chosen  = skills.pick_random()
			return SkillAction.new(chosen)
	# 再決定普通攻擊類型
	if get_int() > get_str():
		return MagicAttackAction.new()
	else:
		return PhysicalAttackAction.new()

func can_use_skill() -> bool:
	return get_available_skills().size() > 0

# ---------------------------------------------------
# 加入新 Buff
func add_buff(buff_data: BuffData, turns: int):
	if buff_data == null:
		return
	# 先檢查是否已有同名 buff
	for buff in active_buffs:
		if buff.data.buff_id == buff_data.buff_id:
			# 存在 → 刷新回合數
			buff.remaining_turns = turns
			print(
				get_display_name(),
				" refreshes buff: ",
				buff_data.name,
				" (",
				turns,
				" turns)"
			)
			return
	# 不存在 → 新增
	var instance = BuffInstance.new(buff_data, turns)
	active_buffs.append(instance)
	
	print(
		get_display_name(),
		" gains buff: ",
		buff_data.name,
		" (",
		turns,
		"turns)"
	)

# 回合數減少 Buff
func update_buffs():
	var to_remove: Array[BuffInstance] = []
	
	for buff in active_buffs:
		# 持續傷害觸發
		if buff.data.is_damage_over_time:
			var max_hp = get_max_hp()
			var damage = int(max_hp * buff.data.damage_ratio)
			damage = max(damage, 1) # 最少1點
			
			take_damage(damage)
			print(get_display_name(), " takes poison damage: ", damage)
		# 回合數減少
		buff.remaining_turns -= 1
		if buff.remaining_turns <= 0:
			to_remove.append(buff)
	# 移除過期buff
	for buff in to_remove:
		active_buffs.erase(buff)
		print(get_display_name(), " buff expired: ", buff.data.name)
		
# 暈眩debuff
func is_stunned() -> bool:
	for buff in active_buffs:
		if buff.data.prevents_action:
			return true
	return false

# 戰鬥結束後清空 Buff
func clear_buffs():
	if active_buffs.is_empty():
		return
	
	print(get_display_name(), " clears all buffs.")
	active_buffs.clear()

# ---------------------------------------------------
# 敵人收藏品
func get_enemy_data() -> EnemyData:
	if enemy:
		return enemy.data
	return null

# ---------------------------------------------------
# 營地恢復 MP
func restore_mp():
	if member:
		current_mp = member.get_max_mp()
	elif enemy:
		current_mp = enemy.get_mp()

# ---------------------------------------------------
