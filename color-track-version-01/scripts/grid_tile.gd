extends Area2D

@onready var sprite = $Sprite2D
var current_color_data: Dictionary

func set_color(color_data: Dictionary):
	current_color_data = color_data
	var texture = load(color_data["texture"])
	if texture:
		sprite.texture = texture
		# Asegurar tamaño correcto
		sprite.centered = true
		sprite.position = Vector2.ZERO
