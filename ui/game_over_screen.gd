extends Control


func _ready() -> void:
	hide()
	set_process_input(false)


func _input(event: InputEvent) -> void:
	get_window().set_input_as_handled()
	
	if (
		event is InputEventKey or
		event is InputEventMouseButton or
		event is InputEventJoypadButton
	):
		if (event.is_pressed() and not event.is_echo()):
			if Game.has_save():
				Game.load_game()
			else:
				Game.back_to_title()


func show_game_over():
	show()
	set_process_input(true)
