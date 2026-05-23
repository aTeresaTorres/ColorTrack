extends Control

var screen_width = 1152
var screen_height = 720

var character_sprite: Sprite2D

func _ready():
	get_window().size = Vector2i(screen_width, screen_height)
	
	# Fondo
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1)
	bg.set_size(Vector2(screen_width, screen_height))
	add_child(bg)
	
	# Título
	var title = Label.new()
	title.text = "ColorTrack"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_size(Vector2(screen_width, 70))
	title.set_position(Vector2(0, 100))
	add_child(title)
	
	var saved_level = load_saved_level()
	
	# Botón Nueva Partida
	var new_btn = Button.new()
	new_btn.text = "Nueva Partida"
	new_btn.set_size(Vector2(200, 50))
	new_btn.set_position(Vector2(screen_width/2 - 100, 250))
	new_btn.pressed.connect(_on_new_game_pressed)
	add_child(new_btn)
	
	# Botón Continuar (solo si hay partida guardada)
	if saved_level > 1:
		var continue_btn = Button.new()
		continue_btn.text = "Continuar (Nivel " + str(saved_level) + ")"
		continue_btn.set_size(Vector2(200, 50))
		continue_btn.set_position(Vector2(screen_width/2 - 100, 320))
		continue_btn.pressed.connect(_on_continue_pressed)
		add_child(continue_btn)
	
	# Añadir personaje
	_setup_character("guyWaving")
	
	# Añadir controles
	_setup_controls()
	

func load_saved_level() -> int:
	if FileAccess.file_exists("user://savegame.save"):
		var file = FileAccess.open("user://savegame.save", FileAccess.READ)
		var level = file.get_var()
		file.close()
		return level if level > 0 else 1
	return 1

func _on_new_game_pressed():
	# Borrar progreso
	if FileAccess.file_exists("user://savegame.save"):
		DirAccess.remove_absolute("user://savegame.save")
	
	# Abrir tutorial en lugar de nivel 1
	var tutorial_scene = Control.new()
	var tutorial_script = preload("res://scripts/Tutorial.gd")
	tutorial_scene.set_script(tutorial_script)
	get_tree().root.add_child(tutorial_scene)
	queue_free()

func _on_continue_pressed():
	var saved_level = load_saved_level()
	_start_game(saved_level)

func _start_game(level: int):
	var level_scene = Node2D.new()
	var level_script = preload("res://scripts/Level.gd")
	level_scene.set_script(level_script)
	level_scene.set_meta("current_level", level)
	get_tree().root.add_child(level_scene)
	queue_free()

func _setup_character(image_name: String):
	character_sprite = Sprite2D.new()
	var texture_path = "res://assets/images/" + image_name + ".png"
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		character_sprite.texture = texture
		character_sprite.position = Vector2(200, 360)  # Izquierda, centrado vertical
		add_child(character_sprite)

func _setup_controls():
	# Etiqueta "Mover personaje"
	var move_label = Label.new()
	move_label.text = "Mover personaje:"
	move_label.add_theme_font_size_override("font_size", 20)
	move_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.set_size(Vector2(200, 30))
	move_label.set_position(Vector2(screen_width/2 - 100, screen_height - 230))
	add_child(move_label)
	
	# Imagen WASD
	var wasd_sprite = Sprite2D.new()
	var wasd_texture = load("res://assets/images/wasd.png")
	if wasd_texture:
		wasd_sprite.texture = wasd_texture
		wasd_sprite.scale = Vector2(0.8, 0.8)
		wasd_sprite.position = Vector2(screen_width/2 - 90, screen_height - 100)
		add_child(wasd_sprite)
	else:
		# Placeholder
		var wasd_label = Label.new()
		wasd_label.text = "WASD"
		wasd_label.add_theme_font_size_override("font_size", 24)
		wasd_label.add_theme_color_override("font_color", Color.WHITE)
		wasd_label.set_position(Vector2(screen_width/2 - 90, screen_height - 100))
		add_child(wasd_label)
	
	# Imagen ARROWS
	var arrows_sprite = Sprite2D.new()
	var arrows_texture = load("res://assets/images/arrows.png")
	if arrows_texture:
		arrows_sprite.texture = arrows_texture
		arrows_sprite.scale = Vector2(0.8, 0.8)
		arrows_sprite.position = Vector2(screen_width/2 + 90, screen_height - 100)
		add_child(arrows_sprite)
	else:
		# Placeholder
		var arrows_label = Label.new()
		arrows_label.text = "←↑↓→"
		arrows_label.add_theme_font_size_override("font_size", 24)
		arrows_label.add_theme_color_override("font_color", Color.WHITE)
		arrows_label.set_position(Vector2(screen_width/2 + 90, screen_height - 100))
		add_child(arrows_label)
	
	# "POSA"
	var saved_level = load_saved_level()
	var show_jkl = saved_level >= 10
	
	if show_jkl:
		# Etiqueta "Presionar botón"
		var button_label = Label.new()
		button_label.text = "Posa:"
		button_label.add_theme_font_size_override("font_size", 20)
		button_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_label.set_size(Vector2(200, 30))
		button_label.set_position(Vector2(screen_width/2 + 250, screen_height - 230))
		add_child(button_label)
		
		# Imagen JKL
		var jkl_sprite = Sprite2D.new()
		var jkl_texture = load("res://assets/images/jkl.png")
		if jkl_texture:
			jkl_sprite.texture = jkl_texture
			jkl_sprite.scale = Vector2(0.8, 0.8)
			jkl_sprite.position = Vector2(screen_width/2 + 350, screen_height - 105)
			add_child(jkl_sprite)
		else:
			var jkl_label = Label.new()
			jkl_label.text = "J K L"
			jkl_label.add_theme_font_size_override("font_size", 24)
			jkl_label.add_theme_color_override("font_color", Color.WHITE)
			jkl_label.set_position(Vector2(screen_width/2 + 350, screen_height - 105))
			add_child(jkl_label)
