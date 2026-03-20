extends ChooseLevel
class_name CustomChooseLevel

const CHOOSE_LEVEL_BUTTON_CUSTOMIZE = preload("res://scenes/choose_level/choose_level_button_customize.tscn")

@onready var panel_help: Panel = $PanelHelp
@onready var grid_container: GridContainer = $AllPage/GridContainer

## 每一页的关卡数量
var num_level_button_every_page:=20

func _ready() -> void:
	## 获取游戏参数文件
	var all_game_paras:Array = load_resources_with_get_files("level_game_para")
	## 初始化页面数据
	all_pages_array.clear()
	all_page.remove_child(grid_container)
	var curr_num_page:int = -1
	for i in range(all_game_paras.size()):
		var page_i:int = int(float(i) / num_level_button_every_page)
		if curr_num_page < page_i:
			curr_num_page += 1
			var new_grid_container = grid_container.duplicate()
			all_page.add_child(new_grid_container)
			all_pages_array.append(new_grid_container)
		## 当前页面
		var curr_grid_container = all_page.get_child(page_i)

		## 关卡按钮
		var chooes_level_button:ChooseLevelButtonCustomize = CHOOSE_LEVEL_BUTTON_CUSTOMIZE.instantiate()
		chooes_level_button.init_choose_level_button_customize(all_game_paras[i][0], all_game_paras[i][1])
		curr_grid_container.add_child(chooes_level_button)

		chooes_level_button.signal_choose_level_button.connect(_on_choose_level_button)
		chooes_level_button.curr_level_data_game_para.set_choose_level(game_mode, page_i, all_game_paras[i][1])
		chooes_level_button.update_curr_level_button_state(Global.global_game_state.curr_all_level_state_data.get(chooes_level_button.curr_level_data_game_para.save_game_name, {}))

	grid_container.queue_free()
	print("当前模式关卡数量:", all_game_paras.size())

	_ready_update_page()


func get_base_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://")
	else:
		return OS.get_executable_path().get_base_dir()


const RESOURCE_EXT = ["tres"]

func is_resource_file(path: String) -> bool:
	var ext = path.get_extension().to_lower()
	return RESOURCE_EXT.has(ext)


func load_resources_with_get_files(folder_path: String) -> Array:
	var base = get_base_path()
	var real_path = base + "/" + folder_path

	var dir = DirAccess.open(real_path)
	if dir == null:
		print("目录不存在:", real_path)
		return []

	var files = dir.get_files()	# ← 仅目录内文件，不含子目录
	var resources: Array = []

	for file_name in files:
		var full_path = real_path + "/" + file_name
		if is_resource_file(full_path):
			var res = ResourceLoader.load(full_path)
			if res:
				resources.append([res, file_name.get_basename()])
				print("加载游戏参数资源文件：" + file_name.get_basename())
			else:
				print("资源加载失败:", full_path)

	return resources


func _on_help_pressed() -> void:
	panel_help.visible = true

func _on_button_ok_pressed() -> void:
	panel_help.visible = false

