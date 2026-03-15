extends BattleAction
class_name SkillAction

var skill_data: SkillData

func _init(s: SkillData):
	skill_data = s

# int 回傳造成傷害的總和
func execute(attacker: Combatant, defender: Combatant) -> Array:
	var results = []
	# 檢查 MP
	if attacker.current_mp < skill_data.mp_cost:
		print(attacker.get_display_name(), "does not have enough MP !")
		return results   # 回傳數值
	# 扣 MP
	attacker.current_mp -= skill_data.mp_cost
	
	# 確認技能名稱、類型
	print("Executing skill:", skill_data.skill_name, "Type:", skill_data.effect_type)
	
	match skill_data.effect_type:
		SkillData.EffectType.DAMAGE:
			# 計算並造成傷害 (這是 100% 發生)
			var damage_info = DamageResolver.calculate_skill_damage(
				attacker,
				defender,
				skill_data
			)
			var damage = damage_info["damage"]
			var is_critical = damage_info["is_critical"]
			var type_text = damage_info["type_text"]
			
			defender.take_damage(damage)
			
			# --- 檢查技能是否附帶 Buff/暈眩/中毒 ---
			# 判定是否附加狀態 (這是機率發生)
			if skill_data.buff_data != null:
				# 加上 randf() 判定 擲骰子判定 (例如 0.3 <= 0.5 成功)
				if randf() <= skill_data.effect_chance:
					# 如果這個傷害技能有填寫 buff_data，就幫防禦者加上去
					var turns = skill_data.buff_turns if skill_data.buff_turns > 0 else skill_data.buff_data.duration
					defender.add_buff(skill_data.buff_data, turns)
				else:
					print(skill_data.skill_name, " 附加效果 (", skill_data.buff_data.name, ") 失敗")
			
			results.append({
				"target": defender,
				"amount": damage,
				"is_critical": is_critical,
				"damage_type": type_text,
				"is_heal": false
			})
			
		SkillData.EffectType.HEAL:
			var heal_amount = _execute_heal(attacker, defender)
			if heal_amount > 0:
				results.append({
					"target": defender,
					"amount": heal_amount,
					"is_critical": false,
					"damage_type": "HEAL"
				})
		SkillData.EffectType.REVIVE:
			var success = _execute_revive(defender)
			if success:
				results.append({
					"target": defender,
					"amount": 0,
					"damage_type": "REVIVE"
				})
		SkillData.EffectType.BUFF:
			var success = _execute_buff(defender)
			if success:
				results.append({
					"target": defender,
					"amount": 0,
					"damage_type": "BUFF"
				})
			
	return results

# 回血
func _execute_heal(attacker: Combatant, target: Combatant) -> int:
	if target.is_dead():
		print(target.get_display_name(), " 死掉了，沒辦法補血。")
		return 0
		
	var heal_amount = skill_data.power + attacker.get_int()
	target.heal(heal_amount)
	
	print(
		attacker.get_display_name(),
		" 幫 ",
		target.get_display_name(),
		" 恢復 ",
		heal_amount,
		" HP"
	)
	return heal_amount

# 復活
func _execute_revive(target: Combatant):
	if not target.is_dead():
		print(target.get_display_name(), " 還活著!")
		return false
		
	target.revive(skill_data.revive_percent)
	print(
		target.get_display_name(),
		" 復活!"
	)
	return true

# Buff觸發
func _execute_buff(target: Combatant):
	if skill_data.buff_data == null:
		return false   # 沒 Buff 資料就當作失敗
	
	# 判定機率
	if randf() <= skill_data.effect_chance:
		var turns = skill_data.buff_turns if skill_data.buff_turns > 0 else skill_data.buff_data.duration
		target.add_buff(skill_data.buff_data, turns)
		
		print(target.get_display_name(), " 成功獲得狀態：", skill_data.buff_data.name)
		return true # 判定成功
	else:
		print(skill_data.skill_name, " 附加效果失敗！")
		return false # 判定失敗
	
