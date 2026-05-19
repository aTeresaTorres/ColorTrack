extends Node2D

@onready var grid = $GridContainer
@onready var player = $Player
@onready var color_target_ui = $Ui/ColorTarget/ColorRect  # Ajusta la ruta
@onready var level_label = $Ui/TopBar/Label
@onready var round_label = $Ui/TopBar/Label2

var current_target_color: Color
var reaction_time_left: float = 5.0
var waiting_for_reaction: bool = false
var reaction_timer: float = 0.0

func _ready():
	$Player.set_grid_bounds(Vector2(50, 50), Vector2(970, 570))
	start_new_round()

func start_new_round():
	# Elegir color objetivo aleatorio de la lista
	var target_data = Global.available_colors[randi() % Global.available_colors.size()]
	current_target_color = target_data["color"]
	color_target_ui.color = current_target_color

func freeze_and_check():
	grid.freeze_colors()
	waiting_for_reaction = true
	reaction_time_left = 5.0

func _process(delta):
	if waiting_for_reaction:
		reaction_time_left -= delta
		# Actualizar UI del temporizador (opcional)
		
		if reaction_time_left <= 0:
			# Tiempo agotado - fallaste
			waiting_for_reaction = false
			fail_round()
		else:
			# Verificar si el jugador está en el color correcto
			var player_color = grid.get_color_at_position(player.position)
			if player_color == current_target_color:
				# Éxito!
				waiting_for_reaction = false
				success_round()

func success_round():
	print("¡Correcto!")
	# Avanzar ronda/nivel
	# Aquí irá la lógica de progresión

func fail_round():
	print("¡Fallaste!")
	# Aquí irá la lógica de caer y reiniciar
