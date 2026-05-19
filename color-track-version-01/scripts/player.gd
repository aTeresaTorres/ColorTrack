extends CharacterBody2D

@export var speed: float = 300.0
@export var grid_rect: Rect2  # Límites de la cuadrícula (x, y, ancho, alto)

@onready var fly_timer = $FlyTimer

var can_fly: bool = false
var is_flying: bool = false

func _physics_process(delta):
	# Movimiento WASD
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	
	# Limitar posición dentro de la cuadrícula
	position.x = clamp(position.x, grid_rect.position.x, grid_rect.position.x + grid_rect.size.x)
	position.y = clamp(position.y, grid_rect.position.y, grid_rect.position.y + grid_rect.size.y)
	
	# Activar vuelo con SPACE
	if Input.is_action_just_pressed("jump") and can_fly and not is_flying:
		activate_fly()

# Llamar esta función desde Main cuando la cuadrícula esté lista
func set_grid_bounds(grid_position: Vector2, grid_size: Vector2):
	grid_rect = Rect2(grid_position, grid_size)

func unlock_fly():
	can_fly = true

func activate_fly():
	is_flying = true
	fly_timer.start()
	# Durante el vuelo, temporalmente desactivamos los límites? 
	# (para que pueda "salir" del color y no morir)
	# Lo decidimos después

func _on_fly_timer_timeout():
	is_flying = false

func get_current_tile_color():
	pass
