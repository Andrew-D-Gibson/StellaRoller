class_name EnemyResource
extends Resource

@export_category('Info')
@export var enemy_name: String
@export_multiline var description: String

@export_category('Graphics')
@export var ship_graphics_scene: PackedScene
@export var targeting_computer_image: Texture2D
@export var health_bar_position: Vector2
@export var intent_indicator_position: Vector2
@export var dice_queue_position: Vector2

@export_category('Behavior')
@export var max_health: int
@export var starting_shields: int
@export var actions_and_likelihoods: Dictionary[EnemyActionResource, float]
