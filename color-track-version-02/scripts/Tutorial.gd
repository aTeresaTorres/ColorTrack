extends Control

var screen_width = 1152
var screen_height = 720
var current_step = 1
var tutorial_images = [
	"tutorial_1_1",
	"tutorial_1_2",
	"tutorial_1_3",
	"tutorial_1_4",
	"tutorial_1_5"
]

var tutorial_texts = [
	"El juego consiste en una cuadrícula de 6x6 con colores que cambian aleatoriamente.\n\nCuando la música se detenga, los colores se fijan y tendrás que pararte sobre el color que el sistema te indique.\n\n¡Tienes 5 segundos para hacerlo!",
	
	"Para moverte por la cuadrícula, usa las teclas:\n\nWASD  o  las FLECHAS del teclado.\n\n\nMuévete libremente y busca el color correcto antes de que se acabe el tiempo.",
	
	"Observa la barra de tiempo en la parte inferior de la pantalla.\n\nCuando esté en VERDE, tienes tiempo.\nCuando se vacíe, se acabó tu oportunidad.\n\n¡Apresúrate!",
	
	"\n\nEn la esquina superior derecha verás tu nivel actual.\n\nA medida que avanzas, el tiempo para colocarte sobre\nel color correcto se reduce",
	
	"¿Tienes lo que se necesita para alcanzar la dificultad INFINITA?"
]

var character_sprite: Sprite2D
var tutorial_panel: ColorRect
var text_label: Label
var space_indicator: Sprite2D

const GRID_SIZE = 6
const CELL_SIZE = 64
var grid_container: Node2D
var player: ColorRect
var grid_colors: Array = []
const COLORS_LIST = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.ORANGE, Color.PURPLE]
var show_grid: bool = false
var timer_bar: ColorRect
var time_left: float = 5.0
var bar_timer: Timer
var difficulty_sprite: Sprite2D = null
var difficulty_levels = ["easy", "medium", "hard"]
var current_difficulty_index = 0
var difficulty_timer: Timer
var time_values = {"easy": 5.0, "medium": 3.0, "hard": 2.0}
var extra_info_label: Label

func _ready():
	get_window().size = Vector2i(screen_width, screen_height)
	
	# Fondo negro
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1)
	bg.set_size(Vector2(screen_width, screen_height))
	add_child(bg)
	
	# Panel semitransparente para el tutorial
	tutorial_panel = ColorRect.new()
	tutorial_panel.color = Color(0.0, 0.0, 0.0, 0.0)
	tutorial_panel.set_size(Vector2(screen_width - 200, screen_height - 150))
	tutorial_panel.set_position(Vector2(100, 75))
	add_child(tutorial_panel)
	
	# MOSTRAR SEGÚN EL PASO
	match current_step:
		1:
			_show_demo_grid()
		2:
			_show_demo_grid_with_player()
		3:
			_show_timer_bar()
		4:
			_show_timer_and_difficulty()
		5:
			pass
	
	# Personaje del tutorial
	character_sprite = Sprite2D.new()
	_update_character_image()
	character_sprite.position = Vector2(1152/2, 720/2)
	character_sprite.z_index = 200
	add_child(character_sprite)
	
	# Texto del tutorial
	text_label = Label.new()
	text_label.add_theme_font_size_override("font_size", 24)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.set_size(Vector2(330, 400))
	text_label.set_position(Vector2(800, 150))
	text_label.text = tutorial_texts[0]
	add_child(text_label)
	
	# Indicador SPACE
	space_indicator = Sprite2D.new()
	var space_texture = load("res://assets/images/space.png")
	if space_texture:
		space_indicator.texture = space_texture
		space_indicator.scale = Vector2(0.5, 0.5)
		space_indicator.position = Vector2(screen_width - 100, screen_height - 50)
		space_indicator.z_index = 10
		add_child(space_indicator)
	
	# Texto de paso
	var step_label = Label.new()
	step_label.text = "Paso " + str(current_step) + " de " + str(tutorial_images.size())
	step_label.add_theme_font_size_override("font_size", 16)
	step_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	step_label.set_position(Vector2(screen_width - 145, screen_height - 90))
	add_child(step_label)

var player_pos: Vector2i = Vector2i(3, 3)
var move_cooldown: float = 0.0

func _process(delta):
	# Solo permitir movimiento en paso 2
	if current_step == 2 and player:
		if move_cooldown > 0:
			move_cooldown -= delta
		
		if move_cooldown <= 0:
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
					move_cooldown = 0.15
					_update_player_position()
	
	# ESC para salir
	if Input.is_action_just_pressed("ui_cancel"):
		_return_to_menu()

func _update_player_position():
	if player and grid_container:
		var start_x = (1152 - GRID_SIZE * CELL_SIZE) / 2
		var start_y = (720 - GRID_SIZE * CELL_SIZE) / 2
		player.position = Vector2(start_x + player_pos.x * CELL_SIZE + 5, start_y + player_pos.y * CELL_SIZE + 5)

func _update_character_image():
	var texture_path = "res://assets/images/" + tutorial_images[current_step - 1] + ".png"
	if ResourceLoader.exists(texture_path):
		character_sprite.texture = load(texture_path)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		_return_to_menu()
	
	if event.is_action_pressed("ui_accept"):  # SPACE
		current_step += 1
		
		if current_step <= tutorial_images.size():
			# Detener timers antes de limpiar
			if grid_container and grid_container.get_parent():
				for child in get_children():
					if child is Timer and child.timeout.is_connected(_randomize_demo_grid):
						child.stop()
						child.queue_free()
			
			# Limpiar elementos anteriores según el paso
			if current_step == 2 and grid_container:
				grid_container.queue_free()
			
			if current_step == 3:
				if grid_container:
					grid_container.queue_free()
				if player:
					player.queue_free()
			
			if current_step == 4:
				if timer_bar:
					timer_bar.queue_free()
				if bar_timer:
					bar_timer.stop()
					bar_timer.queue_free()
			
			if current_step == 5:
				if timer_bar:
					timer_bar.queue_free()
				if bar_timer:
					bar_timer.stop()
					bar_timer.queue_free()
				if difficulty_timer:
					difficulty_timer.stop()
					difficulty_timer.queue_free()
				if difficulty_sprite:
					difficulty_sprite.queue_free()
				
				# Eliminar labels específicos del paso 4
				var explanation = get_node_or_null("difficulty_explanation")
				if explanation:
					explanation.queue_free()
				var time_text = get_node_or_null("time_text")
				if time_text:
					time_text.queue_free()
				
				# También limpiar grid y player por si acaso
				if grid_container:
					grid_container.queue_free()
				if player:
					player.queue_free()
				
				# CREAR LABEL DE INFORMACIÓN EXTRA
				extra_info_label = Label.new()
				extra_info_label.add_theme_font_size_override("font_size", 16)
				extra_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
				extra_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
				extra_info_label.set_size(Vector2(330, 120))
				extra_info_label.set_position(Vector2(50, 100))
				extra_info_label.text = "Cada nivel tiene 3 rondas.\nSi fallas una ronda, tendrás que reiniciar el nivel.\n\nPresiona ESC para ir al menú principal.\n\nSi sales del juego, solo se guarda el nivel.\n¡Las rondas no se guardan, ten cuidado!"
				extra_info_label.z_index = 50
				add_child(extra_info_label)
			
			# Si entramos al paso 2, mostrar grid con jugador
			if current_step == 2:
				_show_demo_grid_with_player()
			
			# Si entramos al paso 3, mostrar barra de tiempo
			if current_step == 3:
				_show_timer_bar()
			
			# Si entramos al paso 4, mostrar timer y dificultad
			if current_step == 4:
				_show_timer_and_difficulty()
			
			# Actualizar imagen y texto
			_update_character_image()
			text_label.text = tutorial_texts[current_step - 1]
			
			# Actualizar texto de paso
			for child in get_children():
				if child is Label and child.position.y > screen_height - 100:
					child.queue_free()
			var step_label = Label.new()
			step_label.text = "Paso " + str(current_step) + " de " + str(tutorial_images.size())
			step_label.add_theme_font_size_override("font_size", 16)
			step_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			step_label.set_position(Vector2(screen_width - 145, screen_height - 90))
			add_child(step_label)
		else:
			_start_game()

func _start_game():
	var level_scene = Node2D.new()
	var level_script = preload("res://scripts/Level.gd")
	level_scene.set_script(level_script)
	level_scene.set_meta("current_level", 1)
	get_tree().root.add_child(level_scene)
	queue_free()

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

var demo_timer: Timer  # Añade esta variable al inicio

func _show_demo_grid():
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
	
	# Animar cambios de color para demostración
	demo_timer = Timer.new()
	demo_timer.wait_time = 0.2
	demo_timer.timeout.connect(_randomize_demo_grid)
	add_child(demo_timer)
	demo_timer.start()

func _randomize_demo_grid():
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var new_color = _random_color()
			grid_colors[i][j] = new_color
			var color_rect = grid_container.get_child(i * GRID_SIZE + j)
			color_rect.color = new_color

func _return_to_menu():
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	get_tree().root.add_child(menu)
	
	# Eliminar el nivel actual
	queue_free()

func _show_demo_grid_with_player():
	# Mostrar cuadrícula
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
	
	# Mostrar jugador (cuadrado blanco)
	player = ColorRect.new()
	player.color = Color.WHITE
	player.set_size(Vector2(CELL_SIZE - 10, CELL_SIZE - 10))
	player.position = Vector2(start_x + 3 * CELL_SIZE + 5, start_y + 3 * CELL_SIZE + 5)
	player.z_index = 150
	add_child(player)
	
	# Añadir un timer para que los colores cambien
	demo_timer = Timer.new()
	demo_timer.wait_time = 0.2
	demo_timer.timeout.connect(_randomize_demo_grid)
	add_child(demo_timer)
	demo_timer.start()

func _show_timer_bar():
	# Crear barra de tiempo
	timer_bar = ColorRect.new()
	timer_bar.color = Color(0.2, 0.6, 0.2)
	timer_bar.set_size(Vector2(400, 20))
	timer_bar.set_position(Vector2(1152/2 - 200, 680))
	timer_bar.z_index = 50
	add_child(timer_bar)
	
	# Crear timer para animar la barra
	bar_timer = Timer.new()
	bar_timer.wait_time = 0.01
	bar_timer.timeout.connect(_update_timer_bar)
	add_child(bar_timer)
	bar_timer.start()
	
	# Texto explicativo adicional
	var timer_explanation = Label.new()
	timer_explanation.text = "→ La barra se vacía en 5 segundos y se reinicia ←"
	timer_explanation.add_theme_font_size_override("font_size", 18)
	timer_explanation.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	timer_explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_explanation.set_size(Vector2(500, 30))
	timer_explanation.set_position(Vector2(1152/2 - 250, 650))
	timer_explanation.z_index = 50
	add_child(timer_explanation)

func _update_timer_bar():
	if timer_bar:
		time_left -= 0.01
		var progress = max(time_left / 5.0, 0)
		timer_bar.set_size(Vector2(400 * progress, 20))
		timer_bar.color = Color(0.2, 0.6, 0.2)  # Verde
		
		# Reiniciar cuando llega a 0
		if time_left <= 0:
			time_left = 5.0

func _stop_all_demo_timers():
	for child in get_children():
		if child is Timer:
			child.stop()
			child.queue_free()

func _show_timer_and_difficulty():
	# Mostrar barra de tiempo
	timer_bar = ColorRect.new()
	timer_bar.color = Color(0.2, 0.6, 0.2)
	timer_bar.set_size(Vector2(400, 20))
	timer_bar.set_position(Vector2(1152/2 - 200, 680))
	timer_bar.z_index = 50
	add_child(timer_bar)
	
	# Mostrar indicador de dificultad
	difficulty_sprite = Sprite2D.new()
	difficulty_sprite.scale = Vector2(0.5, 0.5)
	difficulty_sprite.position = Vector2(970, 80)
	difficulty_sprite.z_index = 50
	add_child(difficulty_sprite)
	
	# Texto explicativo de dificultad
	var difficulty_explanation = Label.new()
	difficulty_explanation.name = "difficulty_explanation"
	difficulty_explanation.text = "→ La dificultad afecta el tiempo disponible ←"
	difficulty_explanation.add_theme_font_size_override("font_size", 16)
	difficulty_explanation.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	difficulty_explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_explanation.set_size(Vector2(350, 30))
	difficulty_explanation.set_position(Vector2(780, 120))
	difficulty_explanation.z_index = 50
	add_child(difficulty_explanation)
	
	# Texto del tiempo actual
	var time_text = Label.new()
	time_text.name = "time_text"
	time_text.add_theme_font_size_override("font_size", 20)
	time_text.add_theme_color_override("font_color", Color.WHITE)
	time_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_text.set_size(Vector2(300, 30))
	time_text.set_position(Vector2(1152/2 - 150, 640))
	time_text.z_index = 50
	add_child(time_text)
	
	# Iniciar el ciclo de dificultades
	_start_difficulty_cycle()

func _start_difficulty_cycle():
	var current_difficulty = difficulty_levels[current_difficulty_index]
	var time_value = time_values[current_difficulty]
	time_left = time_value
	
	# Resetear barra al máximo
	if timer_bar:
		timer_bar.set_size(Vector2(400, 20))
		timer_bar.color = Color(0.2, 0.6, 0.2)
	
	# Actualizar imagen y texto
	_update_difficulty_image()
	var time_text = get_node_or_null("time_text")
	if time_text:
		var difficulty_name = ""
		match current_difficulty:
			"easy": difficulty_name = "FÁCIL"
			"medium": difficulty_name = "MEDIO"
			"hard": difficulty_name = "DIFÍCIL"
		time_text.text = "Tiempo: " + str(time_value) + " segundos (" + difficulty_name + ")"
	
	# Timer para actualizar la barra
	if bar_timer:
		bar_timer.stop()
		bar_timer.queue_free()
	bar_timer = Timer.new()
	bar_timer.wait_time = 0.01
	bar_timer.timeout.connect(_update_difficulty_timer)
	add_child(bar_timer)
	bar_timer.start()
	
	# Timer para cambiar a la siguiente dificultad
	if difficulty_timer:
		difficulty_timer.stop()
		difficulty_timer.queue_free()
	difficulty_timer = Timer.new()
	difficulty_timer.wait_time = time_value
	difficulty_timer.timeout.connect(_next_difficulty)
	add_child(difficulty_timer)
	difficulty_timer.start()

func _update_difficulty_timer():
	if timer_bar and difficulty_timer and difficulty_timer.time_left > 0:
		# Calcular progreso basado en el tiempo restante del difficulty_timer
		var total_time = time_values[difficulty_levels[current_difficulty_index]]
		var time_remaining = difficulty_timer.time_left
		var progress = time_remaining / total_time
		var bar_width = 400 * progress
		timer_bar.set_size(Vector2(bar_width, 20))
		
		timer_bar.color = Color(0.2, 0.6, 0.2)  # Verde
	else:
		# Cuando el timer está por terminar, asegurar barra en 0
		if timer_bar:
			timer_bar.set_size(Vector2(0, 20))
			timer_bar.color = Color(0.5, 0.5, 0.5)

func _next_difficulty():
	# Avanzar a la siguiente dificultad
	current_difficulty_index += 1
	
	# Si llegamos al final, reiniciar el ciclo
	if current_difficulty_index >= difficulty_levels.size():
		current_difficulty_index = 0
	
	# Iniciar la siguiente dificultad
	_start_difficulty_cycle()

func _update_difficulty_image():
	var texture_path = ""
	match difficulty_levels[current_difficulty_index]:
		"easy":
			texture_path = "res://assets/images/difficulty_easy.png"
		"medium":
			texture_path = "res://assets/images/difficulty_medium.png"
		"hard":
			texture_path = "res://assets/images/difficulty_hard.png"
	
	if ResourceLoader.exists(texture_path) and difficulty_sprite:
		difficulty_sprite.texture = load(texture_path)
