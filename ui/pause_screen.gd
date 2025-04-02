extends Control


@onready var resume: Button = $ColorRect/V/Actions/H/Resume
@onready var quit: Button = $ColorRect/V/Actions/H/Quit


func _ready() -> void:
	hide()
	SoundManager.setup_ui_sounds(self)
	
	visibility_changed.connect(func ():
		get_tree().paused = visible
	)


func show_pause() -> void:
	show()
	resume.grab_focus()


func _on_resume_pressed() -> void:
	hide()


func _on_quit_pressed() -> void:
	Game.back_to_title()
