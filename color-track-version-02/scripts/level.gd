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
var time_left: float = 5
var round: int = 1
var dance_timer: float = 0.0
var move_cooldown: float = 0.0  # Para controlar velocidad

var pause_panel: ColorRect
var pause_button: Button

var character_sprite: Sprite2D

# Nuevas variables para la mecánica de botones
var required_button: String = ""  # "left", "center", "right"
var button_pressed_correctly: bool = false
var button_ui_container: ColorRect
var left_indicator: Sprite2D
var center_indicator: Sprite2D
var right_indicator: Sprite2D
var left_correct_indicator: Sprite2D
var center_correct_indicator: Sprite2D
var right_correct_indicator: Sprite2D

var buttons_mechanic_active: bool = false  # Solo activa desde nivel 10

var response_time: float = 5.0  # Variable global para el tiempo de respuesta

var difficulty_sprite: Sprite2D = null

var special_message_panel: ColorRect
var special_message_button: Button

func _ready():
	if has_meta("current_level"):
		current_level = get_meta("current_level")
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 1.0)
	bg.set_size(Vector2(1152, 720))
	bg.set_position(Vector2(0, 0))
	bg.z_index = -10  # Detrás de todo
	add_child(bg)
	
	get_window().size = Vector2i(1152, 720)
	_setup_grid()
	_setup_player()
	_setup_ui()
	_setup_music()
	_setup_character("guyStanding")
	_setup_controls()
	_setup_difficulty_indicator()
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
	
	# Panel para los indicadores de botones (derecha)
	button_ui_container = ColorRect.new()
	button_ui_container.color = Color(0, 0, 0, 0)
	button_ui_container.set_size(Vector2(150, 200))
	button_ui_container.set_position(Vector2(960, 330))
	button_ui_container.visible = false  # Oculto hasta fase move
	add_child(button_ui_container)
	
	# Crear indicadores (usando ColorRect como placeholder, luego cámbialo por imágenes)
	left_indicator = Sprite2D.new()
	center_indicator = Sprite2D.new()
	right_indicator = Sprite2D.new()
	
	# Si tienes imágenes, cárgalas:
	var left_texture = load("res://assets/images/left.png")
	var center_texture = load("res://assets/images/center.png")
	var right_texture = load("res://assets/images/right.png")
	
	if left_texture:
		left_indicator.texture = left_texture
		center_indicator.texture = center_texture
		right_indicator.texture = right_texture
	else:
		# Placeholder visual (texto)
		var label_left = Label.new()
		label_left.text = "←"
		label_left.add_theme_font_size_override("font_size", 40)
		left_indicator = label_left
	
	left_indicator.position = Vector2(0, 30)
	center_indicator.position = Vector2(0, 30)
	right_indicator.position = Vector2(0, 30)
	
	button_ui_container.add_child(left_indicator)
	button_ui_container.add_child(center_indicator)
	button_ui_container.add_child(right_indicator)
	
	left_indicator.visible = false
	center_indicator.visible = false
	right_indicator.visible = false
	
	# Indicadores de "correcto" (inicialmente ocultos)
	left_correct_indicator = Sprite2D.new()
	center_correct_indicator = Sprite2D.new()
	right_correct_indicator = Sprite2D.new()

	var left_correct_texture = load("res://assets/images/left_correct.png")
	var center_correct_texture = load("res://assets/images/center_correct.png")
	var right_correct_texture = load("res://assets/images/right_correct.png")

	if left_correct_texture:
		left_correct_indicator.texture = left_correct_texture
		center_correct_indicator.texture = center_correct_texture
		right_correct_indicator.texture = right_correct_texture

	left_correct_indicator.position = Vector2(0, 30)
	center_correct_indicator.position = Vector2(0, 30)
	right_correct_indicator.position = Vector2(0, 30)
	left_correct_indicator.visible = false
	center_correct_indicator.visible = false
	right_correct_indicator.visible = false

	button_ui_container.add_child(left_correct_indicator)
	button_ui_container.add_child(center_correct_indicator)
	button_ui_container.add_child(right_correct_indicator)
	
	pause_panel = ColorRect.new()
	pause_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	pause_panel.set_size(Vector2(1152, 200))
	pause_panel.set_position(Vector2(0, 720/2 - 100))
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.z_index = 100
	add_child(pause_panel)

	pause_button = Button.new()
	pause_button.set_size(Vector2(200, 50))
	pause_button.set_position(Vector2(1152/2 - 100, 75))
	pause_button.pressed.connect(_on_pause_button_pressed)
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.z_index = 101
	pause_panel.add_child(pause_button)
	
	if current_level <= 2:
		var space_indicator = Sprite2D.new()
		var space_texture = load("res://assets/images/space.png")
		if space_texture:
			space_indicator.texture = space_texture
			space_indicator.scale = Vector2(0.4, 0.4)
			space_indicator.position = Vector2(1152/2 - 18, 168)
			space_indicator.z_index = 101
			space_indicator.process_mode = Node.PROCESS_MODE_ALWAYS
			space_indicator.modulate = Color(1, 1, 1, 0.7)  # 70% opacidad (transparencia)
			pause_panel.add_child(space_indicator)
		else:
			# Placeholder
			var space_label = Label.new()
			space_label.text = "SPACE"
			space_label.add_theme_font_size_override("font_size", 16)
			space_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.7))
			space_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			space_label.set_size(Vector2(100, 30))
			space_label.set_position(Vector2(1152/2 - 50, 130))
			space_label.z_index = 101
			pause_panel.add_child(space_label)
		
		# Texto de ayuda
		var space_hint = Label.new()
		space_hint.text = "Presiona                              para continuar"
		space_hint.add_theme_font_size_override("font_size", 12)
		space_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))
		space_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		space_hint.set_size(Vector2(200, 20))
		space_hint.set_position(Vector2(1152/2 - 153, 160))
		space_hint.z_index = 101
		pause_panel.add_child(space_hint)

func _setup_music():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	var default_music = preload("res://assets/music/default.mp3")
	if default_music:
		music_player.stream = default_music

func _start_dance_phase():
	button_ui_container.visible = false  # Ocultar durante baile
	change_character_image("guyStanding")
	current_phase = "dance"
	time_left = 5.0
	dance_timer = 0.0
	ui_text.text = "Nivel " + str(current_level) + " - Ronda " + str(round) + "/3\n"
	if music_player.stream:
		music_player.play()
		music_player.seek(0)

func _process(delta):
	# Detectar ESC para ir al menú principal
	if Input.is_action_just_pressed("ui_cancel"):  # ui_cancel es ESC por defecto
		_return_to_menu()
	
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
		# Detectar presión de botones SOLO si la mecánica está activa
		if buttons_mechanic_active and not button_pressed_correctly:
			var pressed = ""
			if Input.is_action_just_pressed("button_left"):
				pressed = "left"
			elif Input.is_action_just_pressed("button_center"):
				pressed = "center"
			elif Input.is_action_just_pressed("button_right"):
				pressed = "right"
			
			if pressed != "":
				if pressed == required_button:
					button_pressed_correctly = true
					print("Botón correcto!")
					# Mostrar el indicador correcto y ocultar el normal
					_show_correct_button_feedback()
				else:
					print("Botón incorrecto! Perdiste")
					_fail_round_direct()
					return
		
		# Si la mecánica NO está activa, automáticamente se considera correcta
		if not buttons_mechanic_active and not button_pressed_correctly:
			button_pressed_correctly = true  # Auto-aprobar botón
			
		# Movimiento (tu código existente)
		if move_cooldown <= 0:
			_handle_movement()
			_update_player_position()
		
		# Timer
		time_left -= delta
		var progress = max(time_left / response_time, 0)
		timer_bar.set_size(Vector2(400 * progress, 20))
		
		if time_left <= 0:
			# Tiempo terminado sin presionar botón
			if not button_pressed_correctly:
				print("Tiempo agotado sin presionar botón")
				_fail_round_direct()
			else:
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
	button_pressed_correctly = false  # Resetear estado
	
	# Verificar si la mecánica de botones está activa (nivel 10+)
	buttons_mechanic_active = current_level >= 10
	
	# Solo elegir botón y mostrar UI si la mecánica está activa
	if buttons_mechanic_active:
		# Elegir botón aleatorio (left, center, right)
		var buttons = ["left", "center", "right"]
		required_button = buttons[randi() % buttons.size()]
		
		# Mostrar indicador visual (resaltar el botón requerido)
		_highlight_required_button()
		
		# Mostrar UI de botones
		button_ui_container.visible = true
	else:
		# Ocultar UI de botones
		button_ui_container.visible = false
	
	# Calcular tiempo según nivel
	response_time = 5.0
	match current_level:
		1, 10:
			response_time = 5.0
		2, 11, 12, 13, 14:
			response_time = 3.0
		3, 4, 15, 16, 17, 18, 19:
			response_time = 2.0
		20, 21, 22, 23, 24:
			response_time = 1.5
		_:
			response_time = 1.0
	
	time_left = response_time
	
	# Elegir color objetivo de los presentes
	var available_colors = []
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var color = grid_colors[i][j]
			if not available_colors.has(color):
				available_colors.append(color)
	
	target_color = available_colors[randi() % available_colors.size()]
	var color_name = _get_color_name(target_color)
	var button_name = {"left":"IZQUIERDA", "center":"CENTRO", "right":"DERECHA"}
	ui_text.text = "Nivel " + str(current_level) + " - Ronda " + str(round) + "/3\n " + color_name

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
	var current_cell_color = grid_colors[player_pos.y][player_pos.x]
	var on_correct_color = (current_cell_color == target_color)
	
	# Condición de victoria: botón correcto Y en color correcto
	if button_pressed_correctly and on_correct_color:
		change_character_image("guyWinner")
		# GANÓ la ronda
		round += 1
		var level_complete = round > 3
		
		if level_complete:
			pause_button.text = "SIGUIENTE NIVEL"
		else:
			pause_button.text = "SIGUIENTE"
		
		# Apagar otros colores (feedback visual)
		for i in range(GRID_SIZE):
			for j in range(GRID_SIZE):
				if grid_colors[i][j] != target_color:
					grid_colors[i][j] = Color.BLACK
					var color_rect = grid_container.get_child(i * GRID_SIZE + j)
					color_rect.color = Color.BLACK
	else:
		# PERDIÓ
		change_character_image("guyLoser")
		pause_button.text = "REINTENTAR"
	
	# Mostrar panel SIN pausar primero
	pause_panel.visible = true
	pause_button.grab_focus()
	
	# Pausar después de mostrar (para que el botón funcione)
	# IMPORTANTE: ProcessMode debe permitir que UI funcione
	get_tree().paused = true

func _next_round():
	left_correct_indicator.visible = false
	center_correct_indicator.visible = false
	right_correct_indicator.visible = false
	
	button_ui_container.visible = false  # Ocultar hasta próxima fase move
	change_character_image("guyStanding")
	# Limpiar y empezar nueva ronda (mismo nivel)
	current_phase = "dance"
	round = round  # Ya aumentado en _validate_result
	
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var new_color = _random_color()
			grid_colors[i][j] = new_color
			var color_rect = grid_container.get_child(i * GRID_SIZE + j)
			color_rect.color = new_color
	
	player_pos = Vector2i(3, 3)
	_update_player_position()
	_start_dance_phase()

func _complete_level():
	if current_level == 9:
		_show_level_10_warning()
		return
	else:
		# Subir de nivel
		current_level += 1
		round = 1
		
		# Guardar progreso
		var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
		file.store_var(current_level)
		file.close()
		
		# Reiniciar escena con nuevo nivel
		_restart_level_with_new_level()

func _restart_level_with_new_level():
	left_correct_indicator.visible = false
	center_correct_indicator.visible = false
	right_correct_indicator.visible = false

	button_ui_container.visible = false
	change_character_image("guyStanding")
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
	_setup_difficulty_indicator()
	_update_level_display()
	_start_dance_phase()
	_setup_controls()

func _restart_level():
	left_correct_indicator.visible = false
	center_correct_indicator.visible = false
	right_correct_indicator.visible = false

	button_ui_container.visible = false
	change_character_image("guyStanding")
	# Reiniciar el nivel actual
	current_phase = "dance"
	round = 1
	
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var new_color = _random_color()
			grid_colors[i][j] = new_color
			var color_rect = grid_container.get_child(i * GRID_SIZE + j)
			color_rect.color = new_color
	
	player_pos = Vector2i(3, 3)
	_update_player_position()
	_start_dance_phase()
	
	_setup_difficulty_indicator()

func _on_pause_button_pressed():
	#print("Botón presionado: ", pause_button.text)  # Debug
	
	# Despausar
	get_tree().paused = false
	pause_panel.visible = false
	
	if pause_button.text == "REINTENTAR":
		_restart_level()
	elif pause_button.text == "SIGUIENTE":
		_next_round()
	elif pause_button.text == "SIGUIENTE NIVEL":
		_complete_level()

func _setup_character(image_name: String):
	character_sprite = Sprite2D.new()
	var texture_path = "res://assets/images/" + image_name + ".png"
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		character_sprite.texture = texture
		character_sprite.position = Vector2(180, 360)
		character_sprite.z_index = 200
		add_child(character_sprite)
		print("Personaje añadido correctamente")
	else:
		print("No se encontró la imagen: ", texture_path)

func change_character_image(image_name: String):
	var texture_path = "res://assets/images/" + image_name + ".png"
	print("Intentando cargar: ", texture_path)  # Debug
	
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		if character_sprite:
			character_sprite.texture = texture
			print("Éxito: cambiado a ", image_name)
		else:
			print("character_sprite es null")
	else:
		print("No existe el archivo: ", texture_path)

func _highlight_required_button():
	# Primero, ocultar todos
	left_indicator.visible = false
	center_indicator.visible = false
	right_indicator.visible = false
	
	# Luego, mostrar solo el requerido
	match required_button:
		"left":
			left_indicator.visible = true
			if left_indicator is Sprite2D:
				left_indicator.modulate = Color(1, 1, 1)
		"center":
			center_indicator.visible = true
			if center_indicator is Sprite2D:
				center_indicator.modulate = Color(1, 1, 1)
		"right":
			right_indicator.visible = true
			if right_indicator is Sprite2D:
				right_indicator.modulate = Color(1, 1, 1)
	
	# Resaltar el requerido
	var target = null
	match required_button:
		"left": target = left_indicator
		"center": target = center_indicator
		"right": target = right_indicator
	
	if target:
		if target is Sprite2D:
			target.modulate = Color(1, 1, 1)
		elif target is Label:
			target.add_theme_color_override("font_color", Color(1, 1, 0))

func _fail_round_direct():
	current_phase = "result"
	change_character_image("guyLoser")
	pause_button.text = "REINTENTAR"
	pause_panel.visible = true
	pause_button.grab_focus()
	get_tree().paused = true

func _return_to_menu():
	# Despausar si estaba pausado
	if get_tree().paused:
		get_tree().paused = false
	
	# Crear el menú desde código (igual que en _start_game)
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	get_tree().root.add_child(menu)
	
	# Eliminar el nivel actual
	queue_free()

func _setup_controls():
	# Etiqueta "Mover personaje"
	var move_label = Label.new()
	move_label.text = "Mover personaje"
	move_label.add_theme_font_size_override("font_size", 16)
	move_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.set_size(Vector2(200, 25))
	move_label.set_position(Vector2(1152/2 + 220, 570))
	move_label.z_index = 50
	add_child(move_label)
	
	# Imagen WASD
	var wasd_sprite = Sprite2D.new()
	var wasd_texture = load("res://assets/images/wasd.png")
	if wasd_texture:
		wasd_sprite.texture = wasd_texture
		wasd_sprite.scale = Vector2(0.5, 0.5)
		wasd_sprite.position = Vector2(1152/2 + 260, 720 - 80)
		wasd_sprite.z_index = 50
		add_child(wasd_sprite)
	else:
		var wasd_label = Label.new()
		wasd_label.text = "WASD"
		wasd_label.add_theme_font_size_override("font_size", 18)
		wasd_label.add_theme_color_override("font_color", Color.WHITE)
		wasd_label.set_position(Vector2(1152/2 + 260, 720 - 80))
		add_child(wasd_label)
	
	# Imagen ARROWS
	var arrows_sprite = Sprite2D.new()
	var arrows_texture = load("res://assets/images/arrows.png")
	if arrows_texture:
		arrows_sprite.texture = arrows_texture
		arrows_sprite.scale = Vector2(0.5, 0.5)
		arrows_sprite.position = Vector2(1152/2 + 370, 720 - 80)
		arrows_sprite.z_index = 50
		add_child(arrows_sprite)
	else:
		var arrows_label = Label.new()
		arrows_label.text = "←↑↓→"
		arrows_label.add_theme_font_size_override("font_size", 18)
		arrows_label.add_theme_color_override("font_color", Color.WHITE)
		arrows_label.set_position(Vector2(1152/2 + 370, 720 - 80))
		add_child(arrows_label)
	
	var show_jkl = current_level > 9
	if show_jkl:
		# Etiqueta "Posar"
		var button_label = Label.new()
		button_label.text = "Posar"
		button_label.add_theme_font_size_override("font_size", 16)
		button_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_label.set_size(Vector2(200, 25))
		button_label.set_position(Vector2(1152/2 + 400, 570))
		button_label.z_index = 50
		add_child(button_label)
		
		# Imagen JKL
		var jkl_sprite = Sprite2D.new()
		var jkl_texture = load("res://assets/images/jkl.png")
		if jkl_texture:
			jkl_sprite.texture = jkl_texture
			jkl_sprite.scale = Vector2(0.5, 0.5)
			jkl_sprite.position = Vector2(1152/2 + 500, 720 - 80)
			jkl_sprite.z_index = 50
			add_child(jkl_sprite)
		else:
			var jkl_label = Label.new()
			jkl_label.text = "J K L"
			jkl_label.add_theme_font_size_override("font_size", 18)
			jkl_label.add_theme_color_override("font_color", Color.WHITE)
			jkl_label.set_position(Vector2(1152/2 + 500, 720 - 80))
			add_child(jkl_label)

func _setup_difficulty_indicator():
	if difficulty_sprite:
		difficulty_sprite.queue_free()
	
	difficulty_sprite = Sprite2D.new()
	var texture_path = ""
	
	# Determinar dificultad según nivel
	match current_level:
		1:
			texture_path = "res://assets/images/difficulty_easy.png"
		2:
			texture_path = "res://assets/images/difficulty_medium.png"
		3, 4:
			texture_path = "res://assets/images/difficulty_hard.png"
		5, 6, 7, 8, 9:
			texture_path = "res://assets/images/difficulty_extreme.png"
		10:
			texture_path = "res://assets/images/difficulty_easy_advanced.png"
		11, 12, 13, 14:
			texture_path = "res://assets/images/difficulty_medium_advanced.png"
		15, 16, 17, 18, 19:
			texture_path = "res://assets/images/difficulty_hard_advanced.png"
		20, 21, 22, 23, 24:
			texture_path = "res://assets/images/difficulty_extreme_advanced.png"
		_:
			texture_path = "res://assets/images/difficulty_infinite.png"
	
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		difficulty_sprite.texture = texture
		difficulty_sprite.scale = Vector2(0.5, 0.5)  # Ajusta escala según necesites
		difficulty_sprite.position = Vector2(970, 80)  # Esquina superior derecha
		difficulty_sprite.z_index = 50
		add_child(difficulty_sprite)
		print("Dificultad cargada: ", texture_path)
	else:
		print("No se encontró imagen de dificultad: ", texture_path)
		# Texto de respaldo si no hay imagen
		var difficulty_label = Label.new()
		var difficulty_text = ""
		match current_level:
			1: difficulty_text = "FÁCIL"
			2: difficulty_text = "MEDIO"
			3, 4: difficulty_text = "DIFÍCIL"
			5, 6, 7, 8, 9: difficulty_text = "EXTREMO"
			10: difficulty_text = "FÁCIL AVZ"
			11, 12, 13, 14: difficulty_text = "MEDIO AVZ"
			15, 16, 17, 18, 19: difficulty_text = "DIFÍCIL AVZ"
			20, 21, 22, 23, 24: difficulty_text = "EXTREMO AVZ"
			_: difficulty_text = "INFINITO"
		difficulty_label.text = difficulty_text
		difficulty_label.add_theme_font_size_override("font_size", 20)
		difficulty_label.add_theme_color_override("font_color", Color.YELLOW)
		difficulty_label.set_position(Vector2(1050, 80))
		difficulty_label.z_index = 50
		add_child(difficulty_label)

func _show_level_10_warning():
	# Pausar el juego
	get_tree().paused = true
	
	# Panel de fondo semi-transparente
	special_message_panel = ColorRect.new()
	special_message_panel.color = Color(0, 0, 0, 0.9)
	special_message_panel.set_size(Vector2(1152, 720))
	special_message_panel.set_position(Vector2(0, 0))
	special_message_panel.z_index = 200
	special_message_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(special_message_panel)
	
	# Personaje en el mensaje (usando tutorial_1_4 o una imagen especial)
	var msg_character = Sprite2D.new()
	var char_texture = load("res://assets/images/tutorial_2_1.png")
	if char_texture:
		msg_character.texture = char_texture
	msg_character.position = Vector2(1152/2, 720/2 - 50)
	msg_character.z_index = 501
	msg_character.scale = Vector2(1, 1)
	special_message_panel.add_child(msg_character)
	
	# Título del mensaje
	var title_label = Label.new()
	title_label.text = "¡NIVEL 10 DESBLOQUEADO!"
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_size(Vector2(1152, 60))
	title_label.set_position(Vector2(0, 50))
	title_label.z_index = 201
	special_message_panel.add_child(title_label)
	
	# Texto explicativo
	var message_label = Label.new()
	message_label.text = "A partir del Nivel 10, se activará una NUEVA MECÁNICA:\n\n"
	message_label.text += "Presiona los botones que aparecerán en pantalla:\n\n"
	message_label.text += "   J   →   Izquierda\n"
	message_label.text += "   K   →   Centro\n"
	message_label.text += "   L   →   Derecha\n\n"
	message_label.text += "DEBES presionar el botón correcto Y estar parado en el color indicado.\n"
	message_label.text += "¡Si fallas el botón, pierdes la ronda inmediatamente!\n\n"
	message_label.text += "¿Estás listo para el desafío?"
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.set_size(Vector2(700, 300))
	message_label.set_position(Vector2(1152/2 - 350, 150))
	message_label.z_index = 201
	special_message_panel.add_child(message_label)
	
	# Botón para continuar
	special_message_button = Button.new()
	special_message_button.text = "¡ENTIENDO!"
	special_message_button.set_size(Vector2(300, 60))
	special_message_button.set_position(Vector2(1152/2 - 150, 1000))
	special_message_button.pressed.connect(_on_special_message_closed)
	special_message_button.process_mode = Node.PROCESS_MODE_ALWAYS
	special_message_button.z_index = 201
	special_message_panel.add_child(special_message_button)
	special_message_button.grab_focus()
	
	# Indicador SPACE (opcional)
	var space_img = Sprite2D.new()
	var space_tex = load("res://assets/images/space.png")
	if space_tex:
		space_img.texture = space_tex
		space_img.scale = Vector2(0.4, 0.4)
		space_img.position = Vector2(1152/2, 630)
		space_img.z_index = 201
		special_message_panel.add_child(space_img)
	
	var space_label = Label.new()
	space_label.text = "o presiona ESPACIO"
	space_label.add_theme_font_size_override("font_size", 14)
	space_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	space_label.position = Vector2(1152/2 + 30, 1000)
	space_label.z_index = 201
	special_message_panel.add_child(space_label)
	
	# Forzar que el botón tenga foco
	special_message_button.grab_focus()

func _on_special_message_closed():
	# Limpiar el panel
	if special_message_panel:
		special_message_panel.queue_free()
		special_message_panel = null
	
	# Despausar y continuar al nivel 10
	get_tree().paused = false
	
	# Continuar al nivel 10
	current_level += 1
	round = 1
	
	# Guardar progreso
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_var(current_level)
	file.close()
	
	# Reiniciar escena con nuevo nivel
	_restart_level_with_new_level()

func _input(event):
	# Para el mensaje especial, permitir SPACE como atajo
	if special_message_panel and special_message_panel.visible and event.is_action_pressed("ui_accept"):
		_on_special_message_closed()
	
	# ESC para ir al menú principal (solo si no hay mensaje especial)
	if not special_message_panel and Input.is_action_just_pressed("ui_cancel"):
		_return_to_menu()

func _show_correct_button_feedback():
	# Ocultar indicador normal y mostrar el de "correcto"
	match required_button:
		"left":
			left_indicator.visible = false
			left_correct_indicator.visible = true
			left_correct_indicator.modulate = Color(1, 1, 1)
		"center":
			center_indicator.visible = false
			center_correct_indicator.visible = true
			center_correct_indicator.modulate = Color(1, 1, 1)
		"right":
			right_indicator.visible = false
			right_correct_indicator.visible = true
			right_correct_indicator.modulate = Color(1, 1, 1)
	
	# Opcional: ocultar después de 0.5 segundos (pero mantener hasta que termine la ronda)
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(_hide_correct_button_feedback)
	add_child(timer)
	timer.start()

func _hide_correct_button_feedback():
	# No ocultamos completamente porque queremos que se vea que ya se presionó
	# Solo cambiamos el color o mantenemos visible
	pass
