# CharacterIcon.gd
extends TextureRect



# ---------------------------------------------------
# 當滑鼠「進入」這個圖片的範圍時
func _on_mouse_entered() -> void:
	# 創造一個「補間動畫」工具
	var tween = create_tween()
	
	# 讓圖片向上移動 10 像素，花費 0.1 秒
	# Vector2(0, -10) 代表向上 (Y 軸負方向是上)
	tween.tween_property(self, "position:y", position.y - 20, 0.1)
	
	# 接著讓它回到原位，花費 0.1 秒
	tween.tween_property(self, "position:y", position.y, 0.1)

# ---------------------------------------------------
