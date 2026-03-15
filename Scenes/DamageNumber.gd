extends Node2D
class_name DamageNumber

@onready var label := Label.new()

# ---------------------------------------------------
func _ready():
	add_child(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func show_damage(amount: int, is_critical: bool, damage_type: String):
	label.text = str(amount)
	
	# 顏色與樣式設定
	if is_critical:
		# 爆擊給它鮮艷的橘紅色，並且加上驚嘆號！
		label.text = str(amount)
		modulate = Color(1.0, 0.8, 0.0) # 亮金色/橘色
	else:
		match damage_type:
			"PHYSICAL":
				modulate = Color(1, 0.3, 0.3) # 紅
			"MAGIC":
				modulate = Color(0.3, 0.6, 1) # 藍
			_:
				modulate = Color.WHITE
		
	# 初始縮放 (爆擊一開始要超大！)
	if is_critical:
		scale = Vector2(2.5, 2.5) # 爆擊一開始放大 2.5 倍
	else:
		scale = Vector2.ONE
		
	var tween = create_tween()
	
	# 爆擊彈跳動畫 (Tween)
	if is_critical:
		# 快速縮小回一點點大的狀態 (1.5倍)，製造「撞擊感」
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)\
			.set_trans(Tween.TRANS_BOUNCE)\
			.set_ease(Tween.EASE_OUT)
		
		# 爆擊時左右抖動一下
		var original_x = position.x
		tween.parallel().tween_property(self, "position:x", original_x + 10, 0.05)
		tween.chain().tween_property(self, "position:x", original_x - 10, 0.05)
		tween.chain().tween_property(self, "position:x", original_x, 0.05)
	
	# 向上飄移與淡出
	var start_y = position.y
	var end_y = start_y - 80   # # 爆擊往上飄 80 pixels
	
	tween.parallel().tween_property(
		self,
		"position:y",
		end_y,
		0.8
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 淡出
	tween.parallel().tween_property(
		self,
		"modulate:a",
		0.0,
		0.8
	)
	
	await tween.finished
	queue_free()
