#PlayerStatusItem.gd
extends HBoxContainer

var combatant

@onready var name_label = $MainGrid/NameLabel
@onready var hp_bar = $MainGrid/HPBar
@onready var mp_bar = $MainGrid/MPBar
@onready var hp_label = $MainGrid/HPLabel
@onready var mp_label = $MainGrid/MPLabel
@onready var buff_container = $MainGrid/BuffContainer

# ---------------------------------------------------
func setup(c):
	combatant = c
	name_label.text = combatant.get_display_name()
	update_stats()

func update_stats():
	# HP 數字
	hp_label.text = "HP: %d / %d" % [
		combatant.current_hp,
		combatant.get_max_hp()
	]
	# MP 數字
	mp_label.text = "MP: %d / %d" % [
		combatant.current_mp,
		combatant.get_max_mp()
	]
	# 血條動畫
	hp_bar.max_value = combatant.get_max_hp()
	var tween = create_tween()
	tween.tween_property(
		hp_bar,
		"value",
		combatant.current_hp,
		0.4
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 魔力條動畫
	mp_bar.max_value = combatant.get_max_mp()
	tween.tween_property(
		mp_bar,
		"value",
		combatant.current_mp,
		0
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func show_damage(amount: int, is_critical: bool, damage_type := "PHYSICAL"):
	var dmg_scene = preload("res://Scenes/DamageNumber.tscn")
	var dmg = dmg_scene.instantiate()
	
	add_child(dmg)
	
	dmg.position = Vector2(0, -40)
	dmg.show_damage(amount, is_critical, damage_type)

# buff icon
func update_buffs():
	if combatant == null:
		return
	
	# 清空
	for child in buff_container.get_children():
		child.queue_free()
	
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	# icon 大小設定
	var base_size = 24
	var scale_factor = window_size.x / (720.0 if is_portrait else 1920.0)
	var final_size = int(base_size * scale_factor)
	
	# 限制範圍
	var min_size = 36 if is_portrait else 24   # 直式放大
	var max_size = 64
	final_size = clamp(final_size, min_size, max_size)
	
	# 重新建立
	for buff in combatant.active_buffs:
		var icon = TextureRect.new()
		icon.texture = buff.get_icon()
		icon.custom_minimum_size = Vector2(final_size, final_size)
		buff_container.add_child(icon)


# ---------------------------------------------------
func _ready():
	# 連接視窗大小改變的信號，這樣縮放時會自動調整
	get_tree().root.size_changed.connect(_on_window_resized)
	# 初始化執行一次
	await get_tree().process_frame
	_on_window_resized()

func _on_window_resized():
	if combatant == null:
		return
	
	var window_size = get_viewport().get_visible_rect().size
	# 對所有的 Label 執行縮放
	scale_label_font(name_label, 20, window_size)
	scale_label_font(hp_label, 18, window_size)
	scale_label_font(mp_label, 18, window_size)
	
	update_buffs()

# 為了方便維護，直接把縮放邏輯寫進來，或者調用一個全局的工具函數
func scale_label_font(label: Control, base_size: int, window_size: Vector2):
	var is_portrait = window_size.y > window_size.x
	var scale_factor = window_size.x / (720.0 if is_portrait else 1920.0)
	
	var final_size = int(base_size * scale_factor)
	# 設定直向模式下最小字體，確保清晰
	var min_font = 33 if is_portrait else 24
	
	label.add_theme_font_size_override("font_size", clamp(final_size, min_font, 33))

# ---------------------------------------------------
