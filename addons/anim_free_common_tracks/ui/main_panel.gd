@tool
extends PanelContainer
class_name AFPanelMainContainer

const MAX_HISTORY = 5
const CONFIG_PATH = "user://Anim_Free_Path.cfg"

@onready var anim_path_option = %anim_path_option
@onready var anim_select_button = %anim_select_button
@onready var run_button = %run_button
@onready var status_label = %StatusLabel

@onready var anim_path_option_2: OptionButton = %anim_path_option2
@onready var anim_select_button_2: Button = %anim_select_button2
@onready var run_button_2: Button = %run_button2
@onready var status_label_2: Label = %StatusLabel2
@onready var anim_play_name: TextEdit = %AnimPlayName

var plugin_interface: EditorPlugin

func _ready():
	_load_history_list("anim_path", anim_path_option)
	_load_history_list("scene_path", anim_path_option_2)

	anim_select_button.pressed.connect(_on_select_anim_folder)
	run_button.pressed.connect(_on_run_exe)

	anim_select_button_2.pressed.connect(_on_select_scene_file)
	run_button_2.pressed.connect(_on_run_scene_exe)


func _on_select_anim_folder():
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR

	var full_path = anim_path_option.text
	dialog.current_dir = full_path

	dialog.dir_selected.connect(func(path):
		var fixed_path = path
		if not fixed_path.ends_with("/"):
			fixed_path += "/"
		_add_to_history("anim_path", fixed_path, anim_path_option)
	)
	add_child(dialog)
	dialog.popup_centered()

func _on_run_exe():
	var anim_arg = anim_path_option.get_item_text(anim_path_option.get_selected_id()).strip_edges()
	if anim_arg == "":
		push_error("请填写完整的参数路径")
		return
	_on_dir_selected(anim_arg)
	if plugin_interface:
		plugin_interface.refresh_resources()

func _on_dir_selected(dir_path: String):
	status_label.text = "处理中: " + dir_path
	_process_directory(dir_path)

func _process_directory(path: String):
	var anim_files := []
	var dir = DirAccess.open(path)
	if not dir:
		status_label.text = "❌ 无法打开目录: " + path
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				anim_files.append(path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	status_label.text = "动画数量共："+ str(anim_files.size())+ "个\n"
	var common_tracks = _remove_common_constant_tracks(anim_files, status_label)
	print("===============================================")
	for file_path in anim_files:
		_remove_false_visible_node_tracks(file_path, status_label)


func _on_select_scene_file():
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.tscn", "*.scn"]

	var full_path = anim_path_option_2.text.strip_edges()
	if full_path != "":
		if FileAccess.file_exists(full_path):
			dialog.current_file = full_path.get_file()
			dialog.current_dir = full_path.get_base_dir()
		else:
			dialog.current_dir = full_path.get_base_dir()

	dialog.file_selected.connect(func(path):
		_add_to_history("scene_path", path, anim_path_option_2)
	)
	add_child(dialog)
	dialog.popup_centered()

func _on_run_scene_exe():
	var scene_path = anim_path_option_2.get_item_text(anim_path_option_2.get_selected_id()).strip_edges()
	if scene_path == "":
		push_error("请先选择场景文件")
		return
	_process_scene_file(scene_path)
	if plugin_interface:
		plugin_interface.refresh_resources()

func _process_scene_file(scene_path: String):
	status_label_2.text = "处理中场景: " + scene_path

	var scene_res = ResourceLoader.load(scene_path)
	if not (scene_res is PackedScene):
		push_error("不是有效的场景文件: " + scene_path)
		return

	var root_node = scene_res.instantiate()
	var anim_files := []
	_find_animation_players(root_node, anim_files)

	print("动画数量共：",anim_files.size(), "个")
	status_label_2.text = "动画数量共："+ str(anim_files.size())+ "个\n"
	var common_tracks = _remove_common_constant_tracks(anim_files, status_label_2)
	print("===============================================")
	for item in anim_files:
		_remove_false_visible_node_tracks(item, status_label_2)


func _find_animation_players(node: Node, anim_files: Array):

	if node is AnimationPlayer and (anim_play_name.text == "" or node.name == anim_play_name.text):
		for anim_name in node.get_animation_list():
			var anim_res = node.get_animation(anim_name)
			if anim_res is Animation:
				var res_path = anim_res.resource_path
				if res_path != "" and (res_path.ends_with(".tres") or res_path.ends_with(".res")):
					if not anim_files.has(res_path):
						anim_files.append(res_path)
				else:
					if not anim_files.has(anim_res):
						anim_files.append(anim_res)
	for child in node.get_children():
		_find_animation_players(child, anim_files)


func _add_to_history(key: String, path: String, option: OptionButton):
	var cfg = ConfigFile.new()
	cfg.load(CONFIG_PATH)
	var history := cfg.get_value("paths", key + "_history", [])

	if path in history:
		history.erase(path)
	history.insert(0, path)
	history = history.slice(0, MAX_HISTORY)

	cfg.set_value("paths", key + "_history", history)
	cfg.save(CONFIG_PATH)

	option.clear()
	for item in history:
		option.add_item(item)
	option.tooltip_text = history[0]
	option.select(0)

func _load_history_list(key: String, option: OptionButton):
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var history := cfg.get_value("paths", key + "_history", [])
	history = history.slice(0, MAX_HISTORY)
	option.clear()
	for item in history:
		option.add_item(item)
	if history.size() > 0:
		option.select(0)
		option.tooltip_text = history[0]


func _remove_common_constant_tracks(files: Array, target_label: Label) -> Dictionary:
	var track_values_per_file = []
	print("===== 删除公共恒定轨道 =====")
	for item in files:
		var anim_res: Animation = null
		if typeof(item) == TYPE_STRING:
			anim_res = ResourceLoader.load(item)
		elif typeof(item) == TYPE_OBJECT and item is Animation:
			anim_res = item
		else:
			continue

		if anim_res == null:
			continue

		print("动画文件:", anim_res.resource_name, "("+ anim_res.resource_path +")")
		var track_data := {}
		for i in range(anim_res.get_track_count()):
			if anim_res.track_get_type(i) == Animation.TYPE_VALUE:
				var key_count = anim_res.track_get_key_count(i)
				if key_count > 0:
					var first_val = anim_res.track_get_key_value(i, 0)
					var constant = true
					for k in range(1, key_count):
						if anim_res.track_get_key_value(i, k) != first_val:
							constant = false
							break
					if constant:
						track_data[anim_res.track_get_path(i)] = first_val
						print("\t恒定轨道:", anim_res.track_get_path(i), "值:", first_val)
		track_values_per_file.append(track_data)

	print("查找所有动画文件共有恒定轨道...")
	var common_tracks = {}
	if track_values_per_file.size() > 0:
		var first_file_tracks = track_values_per_file[0]
		for track_path in first_file_tracks.keys():
			var same_in_all = true
			var value_to_match = first_file_tracks[track_path]
			for track_dict in track_values_per_file:
				if not track_dict.has(track_path) or track_dict[track_path] != value_to_match:
					same_in_all = false
					break
			if same_in_all:
				common_tracks[track_path] = value_to_match
				print("\t公共轨道:", track_path)

	print("开始删除公共轨道...")
	if common_tracks.size() > 0:
		for item in files:
			var anim_res: Animation = null
			if typeof(item) == TYPE_STRING:
				anim_res = ResourceLoader.load(item)
			elif typeof(item) == TYPE_OBJECT and item is Animation:
				anim_res = item
			else:
				continue

			if anim_res == null:
				continue

			var modified = false
			for i in range(anim_res.get_track_count() - 1, -1, -1):
				var track_path = anim_res.track_get_path(i)
				if common_tracks.has(track_path):
					anim_res.remove_track(i)
					modified = true
			if modified:
				if typeof(item) == TYPE_STRING:
					ResourceSaver.save(anim_res, item)

	target_label.text += "✅ 删除了 %d 个公共恒定轨道\n" % common_tracks.size()
	return common_tracks


func _remove_false_visible_node_tracks(anim_item, target_label: Label) -> void:
	var anim_res: Animation = null
	if typeof(anim_item) == TYPE_STRING:
		anim_res = ResourceLoader.load(anim_item)
	elif typeof(anim_item) == TYPE_OBJECT and anim_item is Animation:
		anim_res = anim_item
	else:
		print("⚠️ 非动画资源:", anim_item)
		return
	print("-----------------------------------------")
	print("处理动画文件节点visible轨道恒定false:\n", anim_res.resource_path if anim_res.resource_path != "" else "(内置动画)")

	var false_visible_nodes := {}
	for i in range(anim_res.get_track_count()):
		if anim_res.track_get_type(i) == Animation.TYPE_VALUE:
			var track_path: NodePath = anim_res.track_get_path(i)
			if track_path.get_name_count() == 0:
				continue
			var prop_name = track_path.get_subname(0)
			if prop_name != "visible":
				continue
			var key_count = anim_res.track_get_key_count(i)
			if key_count == 0:
				continue
			var all_false = true
			for k in range(key_count):
				var val = anim_res.track_get_key_value(i, k)
				if val != false:
					all_false = false
					break
			if all_false:
				var node_path :String= track_path.get_concatenated_names()
				if "_ground" not in node_path:
					false_visible_nodes[node_path] = true
				else:
					print("_ground节点跳过")

	var modified = false
	for i in range(anim_res.get_track_count() - 1, -1, -1):
		var track_path: NodePath = anim_res.track_get_path(i)
		var node_path = track_path.get_concatenated_names()
		if false_visible_nodes.has(node_path):
			var prop_name = track_path.get_subname(0)
			if prop_name != "visible":
				anim_res.remove_track(i)
				modified = true
				print("删除轨道：", track_path)

	if modified:
		if typeof(anim_item) == TYPE_STRING:
			ResourceSaver.save(anim_res, anim_item)
		target_label.text += anim_res.resource_name +"("+ anim_res.resource_path+")" + " ✅ 删除了节点visible恒定false的相关其他轨道\n"
		print("✅ 删除了节点visible恒定false的相关其他轨道")
	else:
		target_label.text += anim_res.resource_name + "("+ anim_res.resource_path+")" + " 没有需要删除的节点visible相关轨道\n"
		print("没有需要删除的节点visible相关轨道")
