class_name Map
extends Node2D

@export_category('Game Data')
var scenario_list: Array[ScenarioResource]
var current_scenario_index: int

@export_category('Map Textures')
@export var current_scenario_icon: Texture2D
@export var timeline_icon: Texture2D
@export var connector_sprite: Texture2D

@export_category('Components')
@export var LeftDiceReceptacle: DiceReceptacle
@export var RightDiceReceptacle: DiceReceptacle
@export var map_button_label: RichTextLabel
@export var map_button: Clickable
@export var map_viewport: SubViewport
@export var map_camera: Camera2D
@export var error_text: RichTextLabel


@export_category('Behavior')
@export var empty_scenario: ScenarioResource
@export var sprite_spacing: int = 14

var scenario_sprites: Array[Sprite2D]
var desired_scenario_index: int
var tween: Tween


func _ready() -> void:
	Globals.map = self
	
	LeftDiceReceptacle.dice_queue.die_added.connect(_update_desired_scenario)
	LeftDiceReceptacle.dice_queue.die_removed.connect(_update_desired_scenario)
	RightDiceReceptacle.dice_queue.die_added.connect(_update_desired_scenario)
	RightDiceReceptacle.dice_queue.die_removed.connect(_update_desired_scenario)
	
	map_button.clicked.connect(_jump)
	
	Events.load_game_save.connect(_load_game_save)
	Events.start_scenario.connect(_update_map_sprites)
	Events.engine_charge_changed.connect(_update_ui)
	
	
func _load_game_save(game_save: GameSaveResource) -> void:
	scenario_list = game_save.sector_scenarios
	
	current_scenario_index = game_save.current_scenario_index
	_update_map_sprites()
	
	
func _on_visibility_changed() -> void:
	_update_ui()
	
	
func _update_ui() -> void:
	_update_desired_scenario()
	
	if not Globals.player:
		return
	
	if Globals.player.engine_charge != Globals.player.max_engine_charge:
		error_text.text = '[pulse freq=1.0 color=#d0365640 ease=-2.0][color=#d03656]CHARGE ENGINES[/color][/pulse]'
		$LeftArrow.frame = 0
		$RightArrow.frame = 0
		return
		
	$LeftArrow.frame = 1
	$RightArrow.frame = 1
		
	if desired_scenario_index == current_scenario_index:
		error_text.text = '[color=#c552f1]CHOOSE DESTINATION[/color]'
	


func _update_map_sprites() -> void:
	# Delete any old map
	for child in map_viewport.get_children():
		if child is Sprite2D:
			child.queue_free()
	scenario_sprites = []
	
	# Shouldn't ever return here, but still
	if len(scenario_list) == 0:
		return
		
	for i in range(len(scenario_list)):
		# Create a timeline bar to the next location
		if i < len(scenario_list) - 1:
			var timeline_bar_sprite = Sprite2D.new()
			timeline_bar_sprite.texture = timeline_icon
			timeline_bar_sprite.position = Vector2((i * sprite_spacing) + 7, 0)
			map_viewport.add_child(timeline_bar_sprite)
			
			
		# Add the sprite for this encounter
		var scenario_sprite: Sprite2D = Sprite2D.new()
		scenario_sprite.position = Vector2(i * sprite_spacing, 0)
		
		# Mark the encounter as either our present location or 
		# a possible destination with a map icon
		if current_scenario_index == i:
			scenario_sprite.texture = current_scenario_icon
			map_camera.position = scenario_sprite.position
		else:
			scenario_sprite.texture = scenario_list[i].map_icon
			
			# Offset the icon up or down
			scenario_sprite.position += Vector2(0, -13 if i%2==0 else 13)
		
			# Add the connector sprite
			# Add the timeline connector sprite
			var timeline_connector_sprite: Sprite2D = Sprite2D.new()
			timeline_connector_sprite.position = Vector2(i * sprite_spacing, -4 if i%2==0 else 4)
			timeline_connector_sprite.texture = connector_sprite
			map_viewport.add_child(timeline_connector_sprite)
			
		map_viewport.add_child(scenario_sprite)
		scenario_sprites.append(scenario_sprite)
		
	_update_desired_scenario()
	

func _update_desired_scenario() -> void:
	# Sum the dice values in the left selector
	var left_offset = 0
	for die in LeftDiceReceptacle.dice_queue.queue:
		left_offset += die.value
		
	# Sum the dice values in the right selector
	var right_offset = 0
	for die in RightDiceReceptacle.dice_queue.queue:
		right_offset += die.value
	
	
	if len(scenario_list) == 0:
		return
	
	# Sum the values to find the new desired encounter's index
	desired_scenario_index = current_scenario_index + right_offset - left_offset
	
	# Clamp the desired location to within the map
	desired_scenario_index = clampi(desired_scenario_index, 0, len(scenario_list) - 1)
	
	# Tween the camera to center on the desired encounter
	var camera_tween_time = 0.5
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_property(map_camera, 'position', \
		Vector2(desired_scenario_index * sprite_spacing, 0), camera_tween_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Use the map's tween to animate the desired encounter's sprite
	# We use a singular tween to make sure only one tween is running at a time
	var tween_time = 0.75
	if tween:
		tween.kill()
		# Make sure the other sprites are scaled properly,
		# in case we killed the tween midway
		for sprite in scenario_sprites:
			sprite.scale = Vector2(1,1)
	
	if desired_scenario_index != current_scenario_index:
		tween = get_tree().create_tween()
		tween.tween_property(scenario_sprites[desired_scenario_index], 'scale', Vector2(1.5,1.5), tween_time).from(Vector2(1,1))
		tween.tween_property(scenario_sprites[desired_scenario_index], 'scale', Vector2(1,1), tween_time)
		tween.set_loops()
	
	_update_map_button()


func _update_map_button() -> void:
	if desired_scenario_index != current_scenario_index:
		map_button_label.text = '[color=#c552f1][wave amp=15.0 freq=5.0 connected=1]JUMP[/wave][/color]'
	else:
		map_button_label.text = '[color=#171615]JUMP[/color]'


func _jump() -> void:
	if desired_scenario_index != current_scenario_index:
		# Set the current index scenario to empty
		scenario_list[current_scenario_index] = empty_scenario

		# Move to the new encounter
		current_scenario_index = desired_scenario_index
		
		Events.load_scenario.emit(
			scenario_list[desired_scenario_index]
		)
		Events.start_scenario.emit()
