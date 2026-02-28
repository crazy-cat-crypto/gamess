extends CharacterBody2D

signal mine_requested(world_position: Vector2)

@export var speed: float = 220.0
@export var jump_velocity: float = -430.0
@export var mine_reach: float = 28.0

var facing: int = 1
@onready var character_visual: Node2D = $CharacterVisual

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	if not is_on_floor():
		velocity.y += gravity * delta

	var move_input: float = Input.get_axis("ui_left", "ui_right")
	if move_input != 0.0:
		facing = 1 if move_input > 0.0 else -1
		character_visual.scale.x = facing

	velocity.x = move_input * speed

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_target: Vector2 = get_global_mouse_position()
		if global_position.distance_to(mouse_target) <= mine_reach:
			mine_requested.emit(mouse_target)
		else:
			mine_requested.emit(global_position + Vector2(facing * mine_reach, 0))
