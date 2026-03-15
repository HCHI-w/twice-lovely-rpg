# TransitionManager.gd
# 轉場系統
extends Node

var transition_scene := preload("res://Scenes/TransitionScene.tscn")
var transition_instance : CanvasLayer

# ---------------------------------------------------
func _ready():
	# 建立轉場 UI
	transition_instance = transition_scene.instantiate()
	# 延遲加入 SceneTree
	get_tree().root.call_deferred("add_child", transition_instance)
	# 等真的加入 tree
	await transition_instance.tree_entered
	# 一開始先隱藏
	transition_instance.hide()

# ---------------------------------------------------
# 場景切換
# message: 要顯示的文字，預設為空 (不顯示)
# play_anim: 是否播放那個特殊的 transition 動畫，預設為 true
func change_scene(scene_path: String, message: String = "", play_anim: bool = true) -> void:
	transition_instance.show()
	# 黑畫面 (Fade In)
	await transition_instance.fade_in()
	
	# 如果有傳入文字，才顯示訊息
	if message != "":
		await transition_instance.show_message(message, 3.0)

	# 換場景
	get_tree().change_scene_to_file(scene_path)
	
	# 只有當 play_anim 為 true 時才播放動畫
	if play_anim:
		# 播放過場動畫
		await transition_instance.play_transition()
		# 等動畫結束
		await transition_instance.transition_finished
	
	# 等待一幀，讓 Godot 把新場景實例化完成
	await get_tree().process_frame
	# 恢復透明並隱藏
	await transition_instance.fade_out()
	transition_instance.hide()

# ---------------------------------------------------
# 關卡顯示
func show_stage_title(stage:int):
	transition_instance.show()
	# 在開始淡入動畫前，先把透明度設為 1 (全黑)
	# 這樣 show() 的瞬間就是黑的，不會看到後面的場景
	transition_instance.rect.modulate.a = 1.0
	
	await transition_instance.show_message("第 %d 關" % stage, 2)
	
	await transition_instance.fade_out()
	
	transition_instance.hide()

# ---------------------------------------------------
