# GameFlowManager.gd
extends Node

enum GameState {
	BATTLE,
	RESULT,
	CAMP
}

var current_state: GameState

signal state_changed(new_state)

# ---------------------------------------------------
func go_to_battle():
	current_state = GameState.BATTLE
	emit_signal("state_changed", current_state)

func go_to_result():
	current_state = GameState.RESULT
	emit_signal("state_changed", current_state)

func go_to_camp():
	current_state = GameState.CAMP
	emit_signal("state_changed", current_state)
