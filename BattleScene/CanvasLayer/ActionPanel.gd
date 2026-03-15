# ActionPanel.gd
extends Control

signal attack_pressed
signal skill_pressed(skill_data)

@onready var attack_button = $AttackButton
@onready var skill_button = $SkillButton
@onready var skill_name_label = $DescriptionVBox/SkillNameLabel
@onready var skill_desc_label = $DescriptionVBox/SkillDescriptionLabel

@export var battle_manager: Node

var current_skill_data: SkillData

# ---------------------------------------------------
func _ready():
	attack_button.pressed.connect(_on_attack_pressed)
	skill_button.pressed.connect(_on_skill_pressed)
	
	# 一開始就縮放按鈕與 Label
	var window_size = get_viewport().get_visible_rect().size
	scale_label_font(attack_button, 20, window_size)
	scale_label_font(skill_button, 20, window_size)
	scale_label_font(skill_name_label, 20, window_size)
	scale_label_font(skill_desc_label, 20, window_size)

func _on_attack_pressed():
	attack_pressed.emit()

func _on_skill_pressed():
	if current_skill_data:
		skill_pressed.emit(current_skill_data)

# ---------------------------------------------------
# 顯示技能名稱 + 說明
func set_skill(skill: SkillData):
	current_skill_data = skill
	
	if skill == null:
		skill_name_label.text = ""
		skill_desc_label.text = ""
		skill_button.text = "Skill"
		return
	
	skill_name_label.text = skill.skill_name
	skill_desc_label.text = skill.description
	skill_button.text = skill.skill_name
	
	# 縮放文字
	var window_size = get_viewport().get_visible_rect().size
	scale_label_font(skill_name_label, 20, window_size)
	scale_label_font(skill_desc_label, 20, window_size)
	scale_label_font(skill_button, 20, window_size)

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
