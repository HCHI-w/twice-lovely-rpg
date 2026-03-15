# SkillPanel.gd
extends Control

@export var battle_manager: Node
var current_user

func show_skills(user):
	visible = true
	current_user = user
	
	# 清空舊按鈕
	for child in get_children():
		child.queue_free()
	# 為每個技能建立按鈕
	for skill in user.skill_list:
		var btn = Button.new()
		btn.text = skill.skill_name
		
		btn.pressed.connect(func():
			var action = SkillAction.new(skill)
			battle_manager.receive_player_action(action)
			visible = false
			)
			
		add_child(btn)
