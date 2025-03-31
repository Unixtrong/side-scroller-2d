extends Interactable

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hi_bubble: AnimatedSprite2D = $HiBubble


func interact() -> void:
	super()
	
	animation_player.play("activated")
	hi_bubble.hide()
	Game.save_game()
