# DialogueBubble.gd
extends Node2D

@onready var label = $PanelContainer/Label


# ---------------------------------------------------
# 對話氣泡自動消失
func _ready():
	pass
#	await get_tree().create_timer(3).timeout
#	queue_free()


func set_text(t):
	label.text = t
	print("對話氣泡 set_text:", t)   # debug


# ---------------------------------------------------
