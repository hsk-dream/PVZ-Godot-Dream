extends Node
class_name SaveService

## 全局游戏存档服务：只负责持久化金币/花园/关卡进度
## 文件 IO 与自动保存逻辑放在这里，Global 只负责业务/运行态状态

@onready var user_manager: UserManager = %UserManager

const SaveGameVersion := "20251130"
const SaveGameFileName := "GlobalSaveGame.json"
const MAIN_GAME_SAVE_DIR_NAME := "main_game_saves_data"

var _auto_save_timer: Timer

func _get_save_game_path() -> String:
	if user_manager == null or user_manager.curr_user_name.is_empty():
		return ""
	return "user://" + user_manager.curr_user_name + "/" + SaveGameFileName

func start_autosave(interval_sec: float = 60.0) -> void:
	if _auto_save_timer != null:
		return
	var path := _get_save_game_path()
	if path.is_empty():
		return

	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = interval_sec
	_auto_save_timer.one_shot = false
	_auto_save_timer.autostart = true
	add_child(_auto_save_timer)
	_auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)

func stop_autosave() -> void:
	if _auto_save_timer == null:
		return
	_auto_save_timer.stop()
	_auto_save_timer.queue_free()
	_auto_save_timer = null

func _on_auto_save_timer_timeout() -> void:
	save_now()

func save_now() -> void:
	var path := _get_save_game_path()
	if path.is_empty():
		return

	var global := get_parent()
	if global == null:
		return
	var state: GlobalGameState = global.global_game_state
	if state == null:
		return

	var data: Dictionary = {
		"version": SaveGameVersion,
		"coin_value": state.coin_value,
		"garden_data": state.garden_data,
		"curr_num_new_garden_plant": state.curr_num_new_garden_plant,
		"curr_all_level_state_data": state.curr_all_level_state_data,
		"selected_cards": state.selected_cards,
		"curr_plant": state.curr_plant,
		"curr_zombie": state.curr_zombie,
	}
	_save_json(data, path)

func load_global_game_data() -> void:
	var path := _get_save_game_path()
	if path.is_empty():
		return

	var global := get_parent()
	if global == null:
		return
	var state: GlobalGameState = global.global_game_state
	if state == null:
		return

	var data := _load_json(path) as Dictionary

	state.coin_value = data.get("coin_value", state.DEFAULT_COIN_VALUE)
	state.curr_num_new_garden_plant = data.get("curr_num_new_garden_plant", state.DEFAULT_CURR_NUM_NEW_GARDEN_PLANT)
	state.garden_data = data.get("garden_data", state.DEFAULT_GARDEN_DATA).duplicate(true)
	state.curr_all_level_state_data = data.get("curr_all_level_state_data", state.DEFAULT_CURR_ALL_LEVEL_STATE_DATA).duplicate(true)
	state.selected_cards = data.get("selected_cards", [])
	var loaded_curr_plant_raw: Array = data.get("curr_plant", state.curr_plant)
	var loaded_curr_plant: Array[EnumsCharacter.PlantType] = []
	for plant_type in loaded_curr_plant_raw:
		loaded_curr_plant.append(int(plant_type) as EnumsCharacter.PlantType)
	state.curr_plant = loaded_curr_plant

	var loaded_curr_zombie_raw: Array = data.get("curr_zombie", state.curr_zombie)
	var loaded_curr_zombie: Array[EnumsCharacter.ZombieType] = []
	for zombie_type in loaded_curr_zombie_raw:
		loaded_curr_zombie.append(int(zombie_type) as EnumsCharacter.ZombieType)
	state.curr_zombie = loaded_curr_zombie


func save_selected_cards() -> void:
	var path := _get_save_game_path()
	if path.is_empty():
		return
	var global := get_parent()
	if global == null:
		return
	var state: GlobalGameState = global.global_game_state
	if state == null:
		return
	var data := _load_json(path)
	data["selected_cards"] = state.selected_cards
	_save_json(data, path)

func load_selected_cards() -> void:
	var path := _get_save_game_path()
	if path.is_empty():
		return
	var global := get_parent()
	if global == null:
		return
	var state: GlobalGameState = global.global_game_state
	if state == null:
		return
	var data := _load_json(path)
	state.selected_cards = data.get("selected_cards", [])

func _save_json(data: Dictionary, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("❌ 无法打开文件进行写入: %s" % path)
		return

	var json_text := JSON.stringify(data, "\t") # 可读性更强
	file.store_string(json_text)
	file.close()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_text := file.get_as_text()
	file.close()
	var result: Dictionary = JSON.parse_string(json_text) as Dictionary
	if result == null:
		return {}
	return result
