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
