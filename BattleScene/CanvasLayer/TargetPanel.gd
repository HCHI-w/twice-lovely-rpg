# TargetPanel.gd
extends Control

signal target_selected(target)

@export var battle_manager: Node

func show_targets(targets):
	visible = true
	
	var container = $HBoxContainer
	# 清空舊按鈕
	for child in get_children():
		child.queue_free()
	
	for target in targets:
		var btn = Button.new()
		btn.text = target.get_display_name()
		btn.pressed.connect(func():
			target_selected.emit(target)
			visible = false
		)
		container.add_child(btn)
