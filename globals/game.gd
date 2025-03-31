extends Node


const SAVE_PATH := "user://store.sav"

# 游戏场景状态 => {
#   enemies_alive = [ 敌人路径 ]
# }
var world_states := {}

@onready var player_stats: Stats = $PlayerStats
@onready var color_rect: ColorRect = $ColorRect
@onready var default_player_stats := player_stats.to_dict()


# 切换游戏场景
func change_scene(path: String, params := {}) -> void:
	var tree := get_tree()
	tree.paused = true
	
	# 播放黑屏动画
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 1, 0.2)
	await tween.finished
	
	if tree.current_scene is World:
		# 保存旧场景中的数据字典
		var old_name = tree.current_scene.scene_file_path.get_file().get_basename()
		world_states[old_name] = tree.current_scene.to_dict()
	
	# 切换场景
	tree.change_scene_to_file(path)
	
	# 场景切换回调
	if "on_scene_changed" in params:
		params.on_scene_changed.call()
	
	# 等待节点数发生变化，即场景切换完成
	await tree.tree_changed
	
	if tree.current_scene is World:
		# 加载旧场景中保存的数据字典
		var new_name := tree.current_scene.scene_file_path.get_file().get_basename()
		if new_name in world_states:
			tree.current_scene.from_dict(world_states[new_name])
	
	# 如果参数中包含入口点，说明是通过交互切换场景
	if "entry_point" in params:
		# 获取所有在「entry_points」中的节点
		for node in tree.get_nodes_in_group("entry_points"):
			# 如果节点名和指定入口点一致
			if node.name == params.entry_point:
				tree.current_scene.update_player(node.global_position, node.direction)
				break
	
	# 如果参数中直接包含了位置和方向，说明是加载游戏
	if "position" in params and "direction" in params:
		tree.current_scene.update_player(params.position, params.direction)

	tree.paused = false
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0, 0.2)


func save_game() -> void:
	var scene := get_tree().current_scene
	var scene_name = scene.scene_file_path.get_file().get_basename()
	world_states[scene_name] = scene.to_dict()
	
	var data := {
		world_states=world_states,
		stats=player_stats.to_dict(),
		scene_path=scene.scene_file_path,
		player={
			direction=scene.player.direction,
			position={
				x=scene.player.global_position.x,
				y=scene.player.global_position.y,
			}
		}
	}
	var json := JSON.stringify(data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(json)


func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := file.get_as_text()
	var data := JSON.parse_string(json) as Dictionary

	change_scene(data.scene_path, {
		position=Vector2(
			data.player.position.x,
			data.player.position.y
		),
		direction=data.player.direction,
		on_scene_changed=func ():
			world_states = data.world_states
			player_stats.from_dict(data.stats)
	})


# 切换游戏场景
func new_game() -> void:
	change_scene("res://worlds/room_1.tscn", {
		on_scene_changed=func ():
			world_states = {}
			player_stats.from_dict(default_player_stats)
	})


# 返回标题
func back_to_title() -> void:
	change_scene("res://ui/title_screen.tscn")


# 是否有存档
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
