extends Node

# Progreso
var current_level = 1
var current_round = 1
var checkpoint_level = 1

# Música
var player_music_paths = []  # Guardará rutas de canciones del jugador
var current_song_index = 0

# Configuración
var sfx_enabled = true

# Tiempos (para dificultad)
var color_change_time = 1.0  # segundos (cambia aleatoriamente)
var reaction_time = 5.0      # segundos para pisar el color

# Función para guardar progreso (automático)
func save_progress():
	var save_data = {
		"current_level": current_level,
		"current_round": current_round,
		"checkpoint_level": checkpoint_level
	}
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

# Función para cargar progreso
func load_progress():
	if FileAccess.file_exists("user://savegame.json"):
		var file = FileAccess.open("user://savegame.json", FileAccess.READ)
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		if data:
			current_level = data["current_level"]
			current_round = data["current_round"]
			checkpoint_level = data["checkpoint_level"]

# Lista de colores disponibles (nombre, textura_path, color_rgb)
var available_colors = [
	{
		"name": "Rojo",
		"texture": "res://assets/colors/red.png",
		"color": Color(1, 0, 0)
	},
	{
		"name": "Verde",
		"texture": "res://assets/colors/green.png",
		"color": Color(0, 1, 0)
	},
	{
		"name": "Azul",
		"texture": "res://assets/colors/blue.png",
		"color": Color(0, 0, 1)
	},
	{
		"name": "Amarillo",
		"texture": "res://assets/colors/yellow.png",
		"color": Color(1, 1, 0)
	},
	{
		"name": "Morado",
		"texture": "res://assets/colors/purple.png",
		"color": Color(0.5, 0, 0.5)
	},
	{
		"name": "Naranja",
		"texture": "res://assets/colors/orange.png",
		"color": Color(1, 0.5, 0)
	},
	{
		"name": "Rosa",
		"texture": "res://assets/colors/pink.png",
		"color": Color(1, 0.75, 0.8)
	},
	{
		"name": "Cian",
		"texture": "res://assets/colors/cyan.png",
		"color": Color(0, 1, 1)
	}
]
