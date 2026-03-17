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
# # 依畫面方向載入 Scene - BattleScene
func load_battle_scene(message: String = "", play_anim: bool = true):
	var size = get_viewport().size
	
	var scene_path := ""
	
	if size.y > size.x:
		scene_path = "res://Scenes/BattleScene_Portrait.tscn"
	else:
		scene_path = "res://Scenes/BattleScene_Landscape.tscn"
	
	await change_scene(scene_path, message, play_anim)

# ---------------------------------------------------
# 關卡顯示
func show_stage_title(stage:int):
	transition_instance.show()
	# 在開始淡入動畫前，先把透明度設為 1 (全黑)
	# 這樣 show() 的瞬間就是黑的，不會看到後面的場景
	transition_instance.rect.modulate.a = 1.0
	transition_instance.rect.show()
	
	# 播放文字動畫 (這會觸發 AnimationPlayer)
	await transition_instance.show_message("第 %d 關" % stage, 2)
	# 文字播完後，用 Tween 把黑幕拿掉
	await transition_instance.fade_out(0.8)
	
	transition_instance.hide()

# ---------------------------------------------------
