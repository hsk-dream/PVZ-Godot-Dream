## 全局游戏存档服务：持久化金币、花园、关卡进度和统一选卡引用。[br]
## 文件 IO、卡牌身份序列化与自动保存逻辑集中于此，Global 保存业务运行态。
extends Node
class_name SaveService

@onready var user_manager: UserManager = %UserManager
## 与 Global 根下的 GlobalGameState 同级，用 % 引用，避免依赖 get_parent() 类型
@onready var global_game_state: GlobalGameState = %GlobalGameState

const SaveGameVersion := "20251130"
const SaveGameFileName := "GlobalSaveGame.json"
## 主游戏关卡等存档子目录名（单点定义）。其它脚本请用 `SaveService.MAIN_GAME_SAVE_DIR_NAME` 或 `Global.save_service.MAIN_GAME_SAVE_DIR_NAME`，勿复制字符串。
const MAIN_GAME_SAVE_DIR_NAME := "main_game_saves_data"

var _auto_save_timer: Timer

func _get_save_game_path() -> String:
	if user_manager == null or user_manager.curr_user_name.is_empty():
		return ""
	return "user://" + user_manager.curr_user_name + "/" + SaveGameFileName

## 启用自动保存存档
func start_autosave(interval_sec: float = 60.0) -> void:
	if _auto_save_timer != null:
		return

	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = interval_sec
	_auto_save_timer.one_shot = false
	_auto_save_timer.autostart = true
	add_child(_auto_save_timer)
	print("开始自动保存存档")
	_auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)

func stop_autosave() -> void:
	if _auto_save_timer == null:
		return
	_auto_save_timer.stop()
	_auto_save_timer.queue_free()
	_auto_save_timer = null

func _on_auto_save_timer_timeout() -> void:
	print(GlobalUtils.get_curr_time(), " 自动存档")
	save_now()

## 保存当前用户的完整全局状态，选卡按卡槽顺序编码为三字段身份字典。[br]
## 用户未登录或运行态未就绪时跳过，写入失败时不报告保存成功。
func save_now() -> void:
	# 当前用户的全局存档路径；空路径表示尚未登录。
	var path := _get_save_game_path()
	if path.is_empty():
		# 未选用户时常见，不算错误（用 verbose 避免自动存档定时刷屏）
		print("全局存档跳过：未登录用户或用户名为空")
		return

	if global_game_state == null:
		push_error("❌ 全局存档失败：GlobalGameState 未就绪")
		return

	# 本次写入的完整状态，Resource 选卡引用转换为 JSON 可保存的身份值。
	var data: Dictionary = {
		"version": SaveGameVersion,
		"coin_value": global_game_state.coin_value,
		"garden_data": global_game_state.garden_data,
		"curr_num_new_garden_plant": global_game_state.curr_num_new_garden_plant,
		"curr_all_level_state_data": global_game_state.curr_all_level_state_data,
		"selected_cards": _serialize_selected_cards(),
		"curr_plant": global_game_state.curr_plant,
		"curr_zombie": global_game_state.curr_zombie,
	}

	if not _save_json(data, path):
		return
	print(GlobalUtils.get_curr_time(), " 存档全局数据成功, 存档路径:", path)

## 读取当前用户的全局状态；选卡只恢复新格式身份，缺失或无效条目按空列表处理。[br]
## 用户未登录或运行态未就绪时跳过，其他状态沿用各自默认值。
func load_global_game_data() -> void:
	# 当前用户的全局存档路径；空路径不执行读取。
	var path := _get_save_game_path()
	if path.is_empty():
		return

	if global_game_state == null:
		return

	# 从 JSON 读取的状态字典，文件缺失或解析失败时为空。
	var data := _load_json(path) as Dictionary

	# 本次恢复的运行态对象，避免重复访问服务成员。
	var state := global_game_state
	state.coin_value = data.get("coin_value", state.DEFAULT_COIN_VALUE)
	state.curr_num_new_garden_plant = data.get("curr_num_new_garden_plant", state.DEFAULT_CURR_NUM_NEW_GARDEN_PLANT)
	state.garden_data = data.get("garden_data", state.DEFAULT_GARDEN_DATA).duplicate(true)
	state.curr_all_level_state_data = data.get("curr_all_level_state_data", state.DEFAULT_CURR_ALL_LEVEL_STATE_DATA).duplicate(true)
	state.selected_cards = _deserialize_selected_cards(data.get("selected_cards", []))

	### 从存档读取当前植物和僵尸
	#var loaded_curr_plant_raw: Array = data.get("curr_plant", state.curr_plant)
	#var loaded_curr_plant: Array[CharacterRegistry.PlantType] = []
	#for plant_type in loaded_curr_plant_raw:
		#loaded_curr_plant.append(int(plant_type) as CharacterRegistry.PlantType)
	#state.curr_plant = loaded_curr_plant
#
	#var loaded_curr_zombie_raw: Array = data.get("curr_zombie", state.curr_zombie)
	#var loaded_curr_zombie: Array[CharacterRegistry.ZombieType] = []
	#for zombie_type in loaded_curr_zombie_raw:
		#loaded_curr_zombie.append(int(zombie_type) as CharacterRegistry.ZombieType)
	#state.curr_zombie = loaded_curr_zombie


## 单独保存上次选卡的新格式身份列表，保留全局存档中的其他字段。[br]
## 用户未登录或运行态未就绪时跳过，选卡 Resource 不直接写入 JSON。
func save_selected_cards() -> void:
	# 当前用户的全局存档路径；空路径表示尚未登录。
	var path := _get_save_game_path()
	if path.is_empty():
		print("选卡存档跳过：未登录用户或用户名为空")
		return
	if global_game_state == null:
		push_error("❌ 选卡存档失败：GlobalGameState 未就绪")
		return
	# 现有存档内容，只更新选卡字段后原样写回其余数据。
	var data := _load_json(path)
	data["selected_cards"] = _serialize_selected_cards()
	if not _save_json(data, path):
		return

## 单独恢复上次选卡的统一引用，保持存档顺序；旧格式及无效条目不会恢复。[br]
## 用户未登录或运行态未就绪时跳过，缺失列表恢复为空。
func load_selected_cards() -> void:
	# 当前用户的全局存档路径；空路径不执行读取。
	var path := _get_save_game_path()
	if path.is_empty():
		return
	if global_game_state == null:
		return
	# 现有全局存档，本次只读取其中的选卡身份列表。
	var data := _load_json(path)
	global_game_state.selected_cards = _deserialize_selected_cards(data.get("selected_cards", []))

## 将上次选卡引用转成 JSON 可写的字典列表，保持卡槽顺序；不写入 Resource 实例。
func _serialize_selected_cards() -> Array[Dictionary]:
	# 序列化后的卡片身份，供完整存档和单独保存选卡共用。
	var serialized_cards: Array[Dictionary] = []
	# 当前引用只读使用，编码不会修改卡片模板或游戏状态。
	for card_reference: ResourceCardReference in global_game_state.selected_cards:
		if card_reference != null:
			serialized_cards.append(card_reference.to_dict())
	return serialized_cards

## 从 [param data] 读取新格式的选卡列表；无效条目和旧格式不会恢复。[br]
## 返回有序的卡片身份引用，不修改金币、花园、关卡进度或其他存档字段。
func _deserialize_selected_cards(data: Variant) -> Array[ResourceCardReference]:
	# 成功解析的新格式卡片；缺失列表时保持为空。
	var selected_card_references: Array[ResourceCardReference] = []
	if not data is Array:
		return selected_card_references
	# 只接受由卡片引用定义的字典结构，不根据旧植物或僵尸字段推导类别。
	for card_data: Variant in data:
		if not card_data is Dictionary:
			continue
		# 解码创建独立的身份引用，错误或不支持的结构由引用资源拒绝。
		var card_reference: ResourceCardReference = ResourceCardReference.from_dict(card_data)
		if card_reference != null:
			selected_card_references.append(card_reference)
	return selected_card_references

func _save_json(data: Dictionary, path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		push_error("❌ 存档写入失败：无法打开文件 %s（错误码 %d）" % [path, err])
		return false

	var json_text := JSON.stringify(data, "\t") # 可读性更强
	file.store_string(json_text)
	file.close()
	return true

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
