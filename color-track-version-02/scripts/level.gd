extends Node2D

const GRID_SIZE = 6
const CELL_SIZE = 64
const COLORS_LIST = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.ORANGE, Color.PURPLE]

var grid_container: Node2D
var player: ColorRect
var ui_text: Label
var timer_bar: ColorRect
var music_player: AudioStreamPlayer

var current_level: int = 1
var current_phase = "dance"  # "dance", "move", "result"
var target_color: Color
var grid_colors: Array = []
var player_pos: Vector2i = Vector2i(3, 3)
var time_left: float = 5.0
var round: int = 1
var dance_timer: float = 0.0
var move_cooldown: float = 0.0  # Para controlar velocidad

func _ready():
	if has_meta("current_level"):
		current_level = get_meta("current_level")
	
	get_window().size = Vector2i(1152, 720)
	_setup_grid()
	_setup_player()
	_setup_ui()
	_setup_music()
	_update_level_display()
	_start_dance_phase()

func _update_level_display():
	# Actualizar título de ventana o UI con nivel actual
	ui_text.text = "Nivel " + str(current_level) + " - Ronda " + str(round) + "/3"

func _setup_grid():
	grid_container = Node2D.new()
	add_child(grid_container)
	
	var start_x = (1152 - GRID_SIZE * CELL_SIZE) / 2
	var start_y = (720 - GRID_SIZE * CELL_SIZE) / 2
	grid_container.position = Vector2(start_x, start_y)
	
	grid_colors.resize(GRID_SIZE)
	for i in range(GRID_SIZE):
		grid_colors[i] = []
		grid_colors[i].resize(GRID_SIZE)
		for j in range(GRID_SIZE):
			var color_rect = ColorRect.new()
			color_rect.set_size(Vector2(CELL_SIZE - 2, CELL_SIZE - 2))
			color_rect.set_position(Vector2(j * CELL_SIZE, i * CELL_SIZE))
			color_rect.color = _random_color()
			grid_colors[i][j] = color_rect.color
			grid_container.add_child(color_rect)

func _random_color() -> Color:
	return COLORS_LIST[randi() % COLORS_LIST.size()]

func _setup_player():
	player = ColorRect.new()
	player.color = Color.WHITE
	player.set_size(Vector2(CELL_SIZE - 10, CELL_SIZE - 10))
	add_child(player)
	_update_player_position()

func _setup_ui():
	ui_text = Label.new()
	ui_text.add_theme_font_size_override("font_size", 32)
	ui_text.add_theme_color_override("font_color", Color.WHITE)
	ui_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_text.set_size(Vector2(1152, 50))
	ui_text.set_position(Vector2(0, 20))
	add_child(ui_text)
	
	timer_bar = ColorRect.new()
	timer_bar.color = Color(0.2, 0.6, 0.2)
	timer_bar.set_size(Vector2(400, 20))
	# CAMBIADO: abajo del todo (Y = 680, considerando altura 720)
	timer_bar.set_position(Vector2(1152/2 - 200, 680))
	add_child(timer_bar)

func _setup_music():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	var default_music = preload("res://assets/music/default.mp3")
	if default_music:
		music_player.stream = default_music

func _start_dance_phase():
	current_phase = "dance"
	time_left = 5.0
	dance_timer = 0.0
	ui_text.text = "Nivel " + str(current_level) + " - Ronda " + str(round) + "/3\n¡Baila! (5 seg)"
	if music_player.stream:
		music_player.play()

func _process(delta):
	# MOVIMIENTO SIEMPRE ACTIVO (sin restricciones)
	if move_cooldown > 0:
		move_cooldown -= delta
	
	if move_cooldown <= 0:
		_handle_movement()
		_update_player_position()
	
	if current_phase == "dance":
		dance_timer += delta
		if dance_timer >= 0.1:
			dance_timer = 0
			_randomize_grid_colors()
		
		time_left -= delta
		var progress = max(time_left / 5.0, 0)
		timer_bar.set_size(Vector2(400 * progress, 20))
		
		if time_left <= 0:
			_end_dance_phase()
	
	elif current_phase == "move":
		time_left -= delta
		var progress = max(time_left / 5.0, 0)
		timer_bar.set_size(Vector2(400 * progress, 20))
		
		if time_left <= 0:
			_validate_result()
	
	elif current_phase == "result":
		time_left -= delta
		if time_left <= 0:
			if round > 3:
				_complete_level()
			else:
				_next_round()

func _randomize_grid_colors():
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var new_color = _random_color()
			grid_colors[i][j] = new_color
			var color_rect = grid_container.get_child(i * GRID_SIZE + j)
			color_rect.color = new_color

func _end_dance_phase():
	current_phase = "move"
	move_cooldown = 0
	music_player.stop()
	time_left = 5.0
	
	# Elegir color objetivo de los presentes
	var available_colors = []
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var color = grid_colors[i][j]
			if not available_colors.has(color):
				available_colors.append(color)
	
	target_color = available_colors[randi() % available_colors.size()]
	var color_name = _get_color_name(target_color)
	ui_text.text = "Nivel " + str(current_level) + " - Ronda " + str(round) + "/3\n¡Pisa " + color_name + "! (5 seg)"

func _get_color_name(color: Color) -> String:
	if color == Color.RED: return "ROJO"
	if color == Color.GREEN: return "VERDE"
	if color == Color.BLUE: return "AZUL"
	if color == Color.YELLOW: return "AMARILLO"
	if color == Color.ORANGE: return "NARANJA"
	if color == Color.PURPLE: return "MORADO"
	return "?"

func _handle_movement():
	var move = Vector2i.ZERO
	if Input.is_action_pressed("move_right"):
		move.x = 1
	elif Input.is_action_pressed("move_left"):
		move.x = -1
	elif Input.is_action_pressed("move_down"):
		move.y = 1
	elif Input.is_action_pressed("move_up"):
		move.y = -1
	
	if move != Vector2i.ZERO:
		var new_pos = player_pos + move
		if new_pos.x >= 0 and new_pos.x < GRID_SIZE and new_pos.y >= 0 and new_pos.y < GRID_SIZE:
			player_pos = new_pos
			move_cooldown = 0.15  # Retraso de 0.15 segundos entre movimientos

func _update_player_position():
	var start_x = (1152 - GRID_SIZE * CELL_SIZE) / 2
	var start_y = (720 - GRID_SIZE * CELL_SIZE) / 2
	player.position = Vector2(start_x + player_pos.x * CELL_SIZE + 5, start_y + player_pos.y * CELL_SIZE + 5)

func _validate_result():
	current_phase = "result"
	time_left = 3.0
	
	var current_cell_color = grid_colors[player_pos.y][player_pos.x]
	
	if current_cell_color == target_color:
		ui_text.text = "¡CORRECTO!\n+1 ronda"
		# Apagar otros colores
		for i in range(GRID_SIZE):
			for j in range(GRID_SIZE):
				if grid_colors[i][j] != target_color:
					grid_colors[i][j] = Color.BLACK
					var color_rect = grid_container.get_child(i * GRID_SIZE + j)
					color_rect.color = Color.BLACK
		round += 1
	else:
		ui_text.text = "¡FALLASTE!\nReiniciando nivel " + str(current_level)
		await get_tree().create_timer(1.5).timeout
		_restart_level()
		return

func _next_round():
	# Limpiar y empezar nueva ronda
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var color_rect = grid_container.get_child(i * GRID_SIZE + j)
			color_rect.color = _random_color()
			grid_colors[i][j] = color_rect.color
	
	player_pos = Vector2i(3, 3)
	_update_player_position()
	_start_dance_phase()

func _complete_level():
	current_phase = "result"
	
	# Subir de nivel (infinito)
	current_level += 1
	round = 1
	
	ui_text.text = "¡NIVEL " + str(current_level - 1) + " COMPLETADO!\nSiguiente: Nivel " + str(current_level)
	
	# Guardar progreso
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_var(current_level)
	file.close()
	
	await get_tree().create_timer(2.0).timeout
	
	# Reiniciar nivel con nuevo número
	_restart_level_with_new_level()

func _restart_level_with_new_level():
	# Limpiar todo
	for child in grid_container.get_children():
		child.queue_free()
	grid_container.queue_free()
	player.queue_free()
	ui_text.queue_free()
	timer_bar.queue_free()
	
	# Reconstruir con nuevo nivel
	_setup_grid()
	_setup_player()
	_setup_ui()
	_update_level_display()
	_start_dance_phase()

func _restart_level():
	get_tree().reload_current_scene()
