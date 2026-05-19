extends Node2D

@export var grid_width: int = 10      # 10 columnas
@export var grid_height: int = 6      # 8 filas
@export var tile_size: int = 100      # cada cuadrado de 64x64
@export var change_interval: float = 1.0  # cambia cada 1 segundo

var tiles = []           # matriz de tiles
var current_target_color: Color = Color.WHITE
var game_frozen: bool = false  # cuando se detiene el tiempo
var round_active: bool = true   # si la ronda está en curso

@onready var change_timer = $ChangeTimer

func _ready():
	generate_grid()
	
	# Crear Timer por código
	change_timer = Timer.new()
	change_timer.wait_time = change_interval
	change_timer.autostart = true  # <--- Agrega esto
	change_timer.one_shot = false  # <--- Asegura que se repita
	change_timer.timeout.connect(_on_change_timer_timeout)
	add_child(change_timer)
	
	print("Timer creado, wait_time = ", change_timer.wait_time)  # Debug

func generate_grid():
	for child in get_children():
		if child is Area2D:
			child.queue_free()
	tiles.clear()
	
	for x in range(grid_width):
		var column = []
		for y in range(grid_height):
			var tile = load("res://scenes/grid_tile.tscn").instantiate()
			# El tile se posiciona por su centro, no por esquina
			tile.position = Vector2(x * tile_size + tile_size/2, y * tile_size + tile_size/2)
			add_child(tile)
			column.append(tile)
		tiles.append(column)

func change_colors_randomly():
	if game_frozen or not round_active:
		return
	
	for x in range(grid_width):
		for y in range(grid_height):
			var random_color_data = Global.available_colors[randi() % Global.available_colors.size()]
			tiles[x][y].set_color(random_color_data)

func freeze_colors():
	if not is_inside_tree():
		return  # Salir si el nodo ya no está en escena
	
	game_frozen = true
	if change_timer and change_timer.is_inside_tree():
		change_timer.stop()

func start_round():
	if not is_inside_tree():
		return
	
	game_frozen = false
	round_active = true
	if change_timer and change_timer.is_inside_tree():
		change_timer.start()

func get_color_at_position(pos: Vector2) -> Color:
	# Convertir posición mundial a coordenada de tile
	var local_pos = pos - position
	var x = int(local_pos.x / tile_size)
	var y = int(local_pos.y / tile_size)
	
	if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
		return tiles[x][y].get_color()
	return Color.BLACK

func _on_change_timer_timeout():
	change_colors_randomly()

func get_color_data_at_position(pos: Vector2) -> Dictionary:
	var local_pos = pos - position
	var x = int(local_pos.x / tile_size)
	var y = int(local_pos.y / tile_size)
	
	if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
		return tiles[x][y].current_color_data
	return {}
