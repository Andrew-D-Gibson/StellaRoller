class_name Tile
extends Node2D

@export var tile_resource: TileResource:
	set(new_resource):
		tile_resource = new_resource
		_update_texture()
		
@export_category('Components')
@export var draggable: Draggable
@export var clickable: Clickable

signal tile_activation_complete()


func _ready() -> void:
	assert(tile_resource)
	_update_texture()
	
	clickable.clicked.connect(func(): 
		Events.show_info.emit(_get_tile_info())
	)
	
	
func _update_texture() -> void:
	# OLD CODE FOR BLENDING ACTIVATION IMAGE
	#var base_image: Image = tile_resource.base_texture.get_image()
	#var activation_image: Image = tile_resource.activation.activation_texture.get_image()
	#
	## Blend the overlay image onto the base at position (0, 0)
	#base_image.blend_rect(activation_image, Rect2i(Vector2i(0, 0), activation_image.get_size()), Vector2i(0, 0))
	#
	## Create a new texture from the modified image
	#var result_texture = ImageTexture.create_from_image(base_image)
	#
	#$Sprite2D.texture = result_texture
	$Sprite2D.texture = tile_resource.base_texture


func _get_tile_info() -> InfoResource:
	var info = InfoResource.new()
	info.title_label_text = tile_resource.tile_name
	
	info.top_label_text = ''
	for activation in tile_resource.activation_checks:
		info.top_label_text += activation.description + ' '
	
	info.texture = $Sprite2D.texture
	info.bottom_label_text = tile_resource.description
	
	return info


func try_to_activate(activator_die: Dice) -> void:
	for check in tile_resource.activation_checks:
		if not check.criteria_satisfied(activator_die):
			return
			
	activator_die.draggable.state = Draggable.DragState.MOVING_WITH_CODE
	_activate(activator_die)
		

func _activate(activator_die: Dice = null) -> void:
	# Set up the effects variables for chaining effects
	var effect_variables = EffectVariables.new()
	effect_variables.source = Globals.player
	effect_variables.activator_die = activator_die
		
	for effect_resource in tile_resource.effect_chain:
		# Add the effect node to the scene
		var effect = effect_resource.effect_scene.instantiate()
		effect.amount = effect_resource.amount
		add_child(effect)
		
		# Play the effect, recording the change in variables
		await effect.play(effect_variables)
		
		# Remove the effect node from the scene
		effect.queue_free()
		
	tile_activation_complete.emit()
