# PlayerEnemyBattleSlot.gd
extends Control


signal slot_clicked(slot)

@onready var texture_rect = $TextureRect
@onready var button = $Button

# ---------------------------------------------------
func _ready():
	button.pressed.connect(_on_pressed)

func _on_pressed():
	slot_clicked.emit(self)

func set_texture(tex):
	texture_rect.texture = tex

# ---------------------------------------------------
