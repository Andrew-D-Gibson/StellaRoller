class_name GameStateManager
extends Node2D

@export var current_game_save: GameSaveResource

enum GameState {
	IN_COMBAT,
	OUT_OF_COMBAT
}

var state: GameState = GameState.OUT_OF_COMBAT:
	set(new_state):
		if state == GameState.OUT_OF_COMBAT\
		and new_state == GameState.IN_COMBAT:
			Events.start_combat.emit()
			
		elif state == GameState.IN_COMBAT\
		and new_state == GameState.OUT_OF_COMBAT:
			Events.combat_finished.emit()
			
		state = new_state


# This node has to be the last thing loaded in our game
func _ready() -> void:
	Globals.state_manager = self

	Events.start_scenario.connect(_check_combat_state)
	Events.enemy_died.connect(_check_combat_state)
	
	Events.load_game_save.emit(current_game_save)
	Events.load_scenario.emit(
		current_game_save.sector_scenarios[
			current_game_save.current_scenario_index
		]
	)
	Events.start_scenario.emit()
	
	
func _check_combat_state() -> void:
	if _in_combat():
		state = GameState.IN_COMBAT
	else:
		state = GameState.OUT_OF_COMBAT
	
	
func _in_combat() -> bool:
	for enemy in Globals.enemy_manager.get_alive_enemies():
		if enemy.scenario_state\
		and enemy.scenario_state.attitude\
		and enemy.scenario_state.attitude == Enemy.Attitude.AGGRESSIVE:
			return true
	return false
