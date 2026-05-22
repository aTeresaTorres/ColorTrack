extends Control

var screen_width = 1152
var screen_height = 720

var character_sprite: Sprite2D

func _ready():
	get_window().size = Vector2i(screen_width, screen_height)
	
	# Fondo
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15)
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
	_start_game(1)

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
