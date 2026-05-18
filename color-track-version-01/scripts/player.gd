extends CharacterBody2D

@export var speed: float = 300.0

@onready var fly_timer = $FlyTimer

var can_fly: bool = false
var is_flying: bool = false

func _physics_process(delta):
	# Movimiento WASD en 4 direcciones
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	
	# Si está volando, no hay restricción
	move_and_slide()

# Desbloquear habilidad de volar
func unlock_fly():
	can_fly = true

# Activar vuelo (se llama cuando usas la habilidad)
func activate_fly():
	if can_fly and not is_flying:
		is_flying = true
		fly_timer.start()
		# Opcional: cambiar color del personaje o efecto visual

func _on_fly_timer_timeout():
	is_flying = false

func get_current_tile_color():
	# Esto luego detecta qué color está pisando
	pass
