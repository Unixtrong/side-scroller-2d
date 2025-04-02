extends Node


enum Bus { MASTER, SFX, BGM }


@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BgmPlayer


func play_sfx(name: String) -> void:
	var player := sfx.get_node(name) as AudioStreamPlayer
	if !player:
		return
	player.play()


func play_bgm(stream: AudioStream) -> void:
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.play()


func setup_ui_sounds(node: Node) -> void:
	var button := node as Button
	if button:
		button.pressed.connect(play_sfx.bind("UiPress"))
		button.focus_entered.connect(play_sfx.bind("UiFocus"))
		button.mouse_entered.connect(button.grab_focus)
	
	var slider := node as Slider
	if slider:
		slider.value_changed.connect(play_sfx.bind("UiPress").unbind(1))
		slider.focus_entered.connect(play_sfx.bind("UiFocus"))
	
	for child in node.get_children():
		setup_ui_sounds(child)


func get_volumn(bus_index: int) -> float:
	return AudioServer.get_bus_volume_linear(bus_index)


func set_volumn(bus_index: int, volumn: float) -> void:
	AudioServer.set_bus_volume_linear(bus_index, volumn)
