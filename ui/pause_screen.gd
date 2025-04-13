extends Control


signal pause_show(visible: bool)

@onready var resume: Button = $ColorRect/V/Actions/H/Resume
@onready var quit: Button = $ColorRect/V/Actions/H/Quit


func _ready() -> void:
    SoundManager.setup_ui_sounds(self)
    
    pause_show.connect(func (visible: bool):
        if visible:
            show()
            resume.grab_focus()
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            hide()
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    )
    visibility_changed.connect(func ():
        get_tree().paused = visible
    )
    pause_show.emit(false)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        pause_show.emit(false)
        get_window().set_input_as_handled()
    if event.is_action_pressed("ui_cancel"):
        pause_show.emit(false)
        get_window().set_input_as_handled()

func show_pause() -> void:
    pause_show.emit(true)


func _on_resume_pressed() -> void:
    pause_show.emit(false)


func _on_quit_pressed() -> void:
    Game.back_to_title()
