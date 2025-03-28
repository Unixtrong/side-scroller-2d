extends Node2D


@onready var tile_map_2d: Node2D = $TileMap2D
@onready var camera_2d: Camera2D = $Player/Camera2D


func _ready() -> void:
	# 获取 TileMap2D 子场景中的 Platform 节点
	var platform = get_node("TileMap2D/Platform") as TileMapLayer
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
