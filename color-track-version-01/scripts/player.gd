extends CharacterBody2D

@export var speed: float = 300.0

@onready var fly_timer = $FlyTimer

var can_fly: bool = false
var is_flying: bool = false

func _physics_process(delta):
	# Movimiento WASD
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	
	# Activar vuelo con SPACE (solo si tiene la habilidad y no está volando)
	if Input.is_action_just_pressed("jump") and can_fly and not is_flying:
		activate_fly()

func unlock_fly():
	can_fly = true

func activate_fly():
	is_flying = true
	fly_timer.start()
	print("Volando por 3 segundos!")  # Temporal para probar

func _on_fly_timer_timeout():
	is_flying = false
	print("Vuelo terminado")

func get_current_tile_color():
	pass  # Lo haremos después
