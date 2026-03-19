# PlayerEnemyBattleSlot.gd
extends Control


signal slot_clicked(slot, unit, team, index)

@onready var texture_rect = $TextureRect
@onready var button = $Button

var unit
var team
var index
var combatant

# ---------------------------------------------------
func _ready():
	button.pressed.connect(_on_pressed)

func _on_pressed():
	slot_clicked.emit(self, unit, team, index)

func set_texture(tex):
	texture_rect.texture = tex

# ---------------------------------------------------
