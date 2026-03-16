# TransitionScene.gd
# 播放動畫
extends CanvasLayer

signal transition_finished

@onready var rect = $ColorRect
@onready var label = $Label
@onready var anim = $AnimationPlayer

# ---------------------------------------------------
func _ready():
	# 接收視窗縮放信號
	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()   # 初始化
	
	# 接收動畫結束
	anim.animation_finished.connect(_on_animation_finished)

# ---------------------------------------------------
func _on_window_resized():
	var window_size = get_viewport().get_visible_rect().size
	var is_portrait = window_size.y > window_size.x
	
	# 強制讓黑色背景填滿螢幕
	rect.size = window_size
	
	# 調整 Label
	# 設定寬度讓它可以換行（如果文字太長）
	label.size.x = window_size.x * 0.8
	
	# 置中計算
	label.position.x = (window_size.x - label.size.x) / 2
	label.position.y = (window_size.y - label.size.y) / 2
	
	# 調整字體大小
	var font_size = 48 if is_portrait else 32
	label.add_theme_font_size_override("font_size", font_size)


# ---------------------------------------------------
# 播放過場
func play_transition():
	# 播放前確保位置正確
	_on_window_resized()
	await _fade(0.0, 1.0, 0.5)
	anim.play("transition")

func _on_animation_finished(anim_name):
	if anim_name == "transition":
		print("動畫結束:", anim_name)
		transition_finished.emit()

# ---------------------------------------------------
func show_message(text:String, duration := 1.5):
	if text == "":
		label.hide()
		return   # 如果沒字就直接結束，不要 await
		
	label.text = text
	# 顯示前再次更新位置（防止在轉場中途旋轉手機）
	_on_window_resized()
	label.show()
	
	anim.play("transition")   # 播放動畫
	
	await get_tree().create_timer(duration).timeout
	label.hide()

# ---------------------------------------------------
func fade_in(duration := 0.4) -> void:
	self.show()              # 確保 CanvasLayer 是顯示的
	rect.show()              # 確保黑幕是顯示的
	rect.modulate.a = 0.0    # 初始透明度
	
	await get_tree().process_frame # 給網頁渲染器一幀的時間準備
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # 即使遊戲暫停也要跑動
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	
	await tween.finished

func fade_out(duration := 0.4) -> void:
	rect.modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	
	await tween.finished
	rect.hide()   # 跑完才藏起來，才不會擋到下面的按鈕
	self.hide()   # 整個層級藏起來

# 通用淡入 / 淡出 Tween 函式
# color_from: 起始顏色
# color_to: 結束顏色
# duration: 時間 (秒)
# on_finished: 可選回調
func _fade(from: float, to: float, duration: float) -> void:
	var tween = create_tween()

	rect.modulate.a = from
	tween.tween_property(rect, "modulate:a", to, duration)

	await tween.finished

# ---------------------------------------------------
