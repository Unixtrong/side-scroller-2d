extends Node


@onready var player_stats: Stats = $PlayerStats
@onready var color_rect: ColorRect = $ColorRect


# 切换游戏场景
func change_scene(path: String, entry_point: String) -> void:
	var tree := get_tree()
	tree.paused = true
	
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 1, 0.2)
	await tween.finished
	
	# 切换场景
	tree.change_scene_to_file(path)
	# 等待节点数发生变化，即场景切换完成
	await tree.tree_changed
	
	# 获取所有在「entry_points」中的节点
	for node in tree.get_nodes_in_group("entry_points"):
		# 如果节点名和指定入口点一致
		if node.name == entry_point:
			tree.current_scene.update_player(node.global_position, node.direction)
			break

	tree.paused = false
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0, 0.2)
