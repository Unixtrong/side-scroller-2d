extends Node2D


@onready var tile_map_2d: Node2D = $TileMap2D
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var player: Player = $Player


@export var pig_scene: PackedScene  # 预制体
@export var spawn_position: Vector2  # 生成位置


func _ready() -> void:
	# 获取 TileMap2D 子场景中的 Platform 节点
	var platform = get_node("TileMap2D/Edge") as TileMapLayer
	# 获取已使用的矩形尺寸，单位是单元格个数
	var used = platform.get_used_rect()
	# 每个单元格的尺寸，单位像素
	var tile_size = platform.tile_set.tile_size
	# 限制相机四边大小，单位像素
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.limit_top = used.position.y * tile_size.y
	camera_2d.limit_right = used.end.x * tile_size.x
	camera_2d.limit_bottom = used.end.y * tile_size.y
	# 禁止游戏开始时镜头应用 limit 时的动画
	camera_2d.reset_smoothing()


func spawn_pig():
	var new_pig = pig_scene.instantiate()
	new_pig.position = spawn_position
	add_child(new_pig)
	new_pig.pig_free.connect(on_pig_died)


func on_pig_died():
	await get_tree().create_timer(1.0).timeout  # 等待 1 秒
	spawn_pig()  # 重新生成小怪


func update_player(position: Vector2, direction: Player.Direction) -> void:
	player.global_position = position
	camera_2d.reset_smoothing()
	camera_2d.force_update_scroll()
