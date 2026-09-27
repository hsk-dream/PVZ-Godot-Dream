extends Resource
class_name ResourceLevelData

#region 选关数据,管理关卡存档
## 游戏模式(冒险，迷你游戏，解密，生存)，游戏选关场景
var game_mode: MainSceneRegistry.MainScenes = MainSceneRegistry.MainScenes.Null
## 游戏关卡所在的页面
var level_page: int = 0
## 当前关卡标识符
var level_id: String = "test"
## 多轮游戏存档保存的文件名(无后缀)
var save_game_name: String

## 初始化选关数据
func set_choose_level(curr_game_mode: MainSceneRegistry.MainScenes, curr_level_page: int, curr_level_id: String) -> void:
	game_mode = curr_game_mode
	level_page = curr_level_page
	level_id = curr_level_id
	save_game_name = str(game_mode) + "_" + str(level_page) + "_" + str(level_id)

#endregion

#region 关卡背景
## 游戏场景
@export var game_sences: MainSceneRegistry.MainScenes = MainSceneRegistry.MainScenes.MainGameFront
## 游戏轮次:多轮游戏且自然出怪 自动更新自然出怪列表 -1表示无尽，不要用其余的数字表示无尽
@export var game_round: int = 1

@export_group("关卡背景参数")
## 游戏背景
@export var game_BG: ConstLevelData.GameBg = ConstLevelData.GameBg.FrontDay
## 游戏背景音乐
@export var game_BGM: ConstLevelData.GameBGM = ConstLevelData.GameBGM.FrontDay
## 是否有雾
@export var is_fog: bool = false
## 是否有雨
@export var is_rain: bool = false
## 是否为白天,控制蘑菇睡觉
@export var is_day: bool = true
## 是否天降阳光,传送带没有
@export var is_day_sun: bool = true
## 是否有小推车
@export var is_lawn_mover: bool = true
## 是否僵尸能进房
@export var is_zombie_can_home: bool = true

@export_subgroup("预种植植物(从1开始,0为整行或整列)")
@export var all_pre_plant_data: Array[PrePlantResource] = []

#endregion

#region 关卡流程
@export_group("关卡流程参数")
## 开局查看展示僵尸
@export var look_show_zombie: bool = true
## 是否可以选择卡片,传送带不可选择
@export var can_choosed_card: bool = true
## 戴夫对话资源
@export var crazy_dave_dialog: CrazyDaveDialogResource
#endregion

#region 出怪参数
@export_group("出怪参数")
## 出怪模式
@export var monster_mode: ConstLevelData.E_MonsterMode = ConstLevelData.E_MonsterMode.Norm
## 是否为小僵尸模式
@export var is_mini_zombie := false
@export_subgroup("正常出怪模式")
## 出怪倍率
@export var zombie_multy := 1
## 每轮游戏出怪波次，每10波生成1旗帜
@export var max_wave := 30
## 僵尸种类刷新列表 多轮游戏且自然出怪 自动更新自然出怪列表
@export var zombie_refresh_types: Array[CharacterRegistry.ZombieType] = [
	CharacterRegistry.ZombieType.Z001Norm, # 普通僵尸
	#CharacterRegistry.ZombieType.Z002Flag, # 旗帜僵尸
	CharacterRegistry.ZombieType.Z003Cone, # 路障僵尸
	CharacterRegistry.ZombieType.Z004PoleVaulter, # 撑杆僵尸
	CharacterRegistry.ZombieType.Z005Bucket, # 铁桶僵尸
]
## 是否有蹦极僵尸
@export var is_bungi := false
## 大波时生成的蹦极僵尸数量范围
@export var range_num_bungi: Vector2i = Vector2i(3, 5)

@export_subgroup("僵王参数")
## 僵王场景通过 Global.character_registry 查询；Null 表示本关没有僵王。
## 是否接受僵王奖杯请求由 monster_mode 决定，与是否配置僵王分开。
@export var boss_type: CharacterRegistry.ZombieBossType = CharacterRegistry.ZombieBossType.Null
## 正常模式：0 为正式开战时生成，1 起为指定波次生成；Boss 模式必须为 0。
## 参数使用从 1 开始的波次，管理器接入时需与内部从 0 开始的 curr_wave 转换。
@export_range(0, 999, 1, "or_greater") var boss_spawn_wave: int = 0
## 相对于主游戏 ZombieBossRoot 的出生位置，不是植物格子行列或屏幕坐标。
@export var boss_spawn_position: Vector2 = Vector2.ZERO

@export_subgroup("锤僵尸出怪模式（需调整对应墓碑参数）")
## 墓碑出怪倍率
@export var zombie_multy_hammer := 1
## 锤僵尸出怪波数
@export var max_wave_hammer_zombie := 10
## 初始化僵尸速度
@export var speed_zombie_init := 1.0
## 每波僵尸速度提升
@export var speed_zombie_add := 0.15
## 僵尸速度提升最大值
@export var speed_zombie_max := 2.0

@export_subgroup("墓碑参数")
## 是否有墓碑,即墓碑是否生成僵尸
@export var is_have_tombston := false
## 初始生成的墓碑数量
@export var init_tombstone_num := 0

#endregion

#region 卡片参数
@export_group("卡片参数")
## 卡槽模式，只有Norm可以选卡
@export var card_mode: ConstLevelData.E_CardMode = ConstLevelData.E_CardMode.Norm
## 是否有种子雨
@export var is_seed_rain := false
@export_subgroup("正常卡槽参数")
## 最大卡槽数量
@export_range(1, 15) var max_choosed_card_num: int = 10
## 开始阳光数量
@export var start_sun: int = 50
## 预选卡片列表、预选卡片不能在选卡时取消
@export var pre_choosed_card_list_plant: Array[CharacterRegistry.PlantType] = []
@export var pre_choosed_card_list_zombie: Array[CharacterRegistry.ZombieType] = []

@export_subgroup("传送带卡片参数")
@export var all_card_plant_type_probability: Dictionary[CharacterRegistry.PlantType, int]
@export var all_card_zombie_type_probability: Dictionary[CharacterRegistry.ZombieType, int]
@export var card_order_plant: Dictionary[int, CharacterRegistry.PlantType] = {}
@export var card_order_zombie: Dictionary[int, CharacterRegistry.ZombieType] = {}
@export var create_new_card_speed: float = 1

@export_subgroup("种子雨卡片参数")
@export var all_card_plant_type_probability_seed_rain: Dictionary[CharacterRegistry.PlantType, int]
@export var all_card_zombie_type_probability_seed_rain: Dictionary[CharacterRegistry.ZombieType, int]
@export var card_order_plant_seed_rain: Dictionary[int, CharacterRegistry.PlantType] = {}
@export var card_order_zombie_seed_rain: Dictionary[int, CharacterRegistry.ZombieType] = {}

@export_subgroup("种植参数")
## 柱子模式
@export var is_mode_column := false
## 是否有铲子
@export var is_shovel := true
#endregion

#region 罐子参数
@export_group("罐子参数")
## 是否为罐子模式，影响胜利条件
@export var is_pot_mode := false
@export var pot_mode: ConstLevelData.E_PotMode = ConstLevelData.E_PotMode.Null
@export var pot_col_range: Vector2i = Vector2i(4, 9)
@export var is_can_look_random_res_pot := false
@export var is_save_plant_on_pot_mode := false

@export_subgroup("权重随机生成")
@export_range(0, 1, 0.01) var weight_res_fiexd: float = 1
@export var candidate_plant_pot: Dictionary[CharacterRegistry.PlantType, int] = {}
@export var candidate_zombie_pot: Dictionary[CharacterRegistry.ZombieType, int] = {}
var candidate_zombie_pot_with_zombie_row_type: Dictionary[CharacterRegistry.ZombieRowType, Dictionary] = {
	CharacterRegistry.ZombieRowType.Land: {},
	CharacterRegistry.ZombieRowType.Pool: {},
}
@export var weight_pot_type: Vector3i = Vector3i(6, 2, 2)
var weight_pot_type_sum: int = 10

@export_subgroup("固定生成，随机位置(从后往前随机放置罐子，满足列对齐，不足的格子使用结果随机罐子补齐)")
@export var random_pot_plant: Dictionary[CharacterRegistry.PlantType, int]
@export var random_pot_zombie: Dictionary[CharacterRegistry.ZombieType, int]
var random_pot_zombie_with_zombie_row_type: Dictionary[CharacterRegistry.ZombieRowType, Dictionary]
@export var plant_pot: Dictionary[CharacterRegistry.PlantType, int]
@export var zombie_pot: Dictionary[CharacterRegistry.ZombieType, int]
var zombie_pot_with_zombie_row_type: Dictionary[CharacterRegistry.ZombieRowType, Dictionary]
var pot_num_on_fixed_mode: int = 0
@export var random_pot_num_on_fixed_mode: Vector3i = Vector3i.ZERO
#endregion

#region 我是僵尸模式
@export_group("我是僵尸模式")
@export var is_zombie_mode := false
@export var plant_col_on_zombie_mode: int = 4
@export var all_plants_weight_on_zombie_mode: Dictionary[CharacterRegistry.PlantType, int]
@export var all_must_plants_on_zombie_mode: Dictionary[CharacterRegistry.PlantType, int]

#endregion

#region 迷你游戏物品参数
@export_group("游戏物品参数")
@export_subgroup("保龄球红线")
@export var is_bowling_stripe := false
## 第几列植物格子之后(0开始)
@export var plant_cell_col_j: int = 2
@export var plant_cell_can_use: Dictionary[String, bool] = {
	"left_can_plant": true,
	"right_can_plant": true,
	"left_can_zombie": true,
	"right_can_zombie": true,
}

@export_subgroup("锤子")
@export var is_hammer := false
#endregion

## 存档之前的原始数据,如果因为存档改变, 删除存档后重新修复回来
var ori_data_on_save_data_update: Dictionary = {}
## 存档数据
var save_game_data_main_game: ResourceSaveGameMainGame

## 游戏开始会根据参数初始化一些硬性的参数。
## 卡槽: 传送带禁止选卡、禁止天降阳光。预选卡用 0 补全。
## 出怪: 正常模式下刷新列表会按白名单过滤；禁止在列表中写 Z021Bungi，应使用 is_bungi。
## 返回是否初始化成功；僵王配置错误时先报错并返回 false，避免修改参数或读取存档。
func init_para() -> bool:
	var boss_parameter_errors := validate_boss_parameters()
	if not boss_parameter_errors.is_empty():
		for message: String in boss_parameter_errors:
			push_error("ResourceLevelData：僵王配置无效：" + message)
		return false
	_apply_card_mode_constraints()
	_pad_prechosen_cards()
	_init_zombie_refresh_from_whitelist()
	_normalize_pot_col_range()
	_init_pot_mode()
	_apply_zombie_mode_rules()
	_maybe_load_multi_round_save()
	return true


## 只查询是否配置了僵王，不代表使用 Boss 出怪模式或僵王奖杯规则。
func has_boss() -> bool:
	return boss_type != CharacterRegistry.ZombieBossType.Null


## 返回全部僵王配置错误；空数组表示通过，不修改资源，也不实例化角色。
## init_para() 统一处理校验错误并中止初始化；本方法仅返回错误，不修改关卡状态。
## 无僵王的旧关卡忽略僵王专属字段，保留原有特殊模式及多轮游戏行为。
func validate_boss_parameters() -> PackedStringArray:
	var errors := PackedStringArray()
	if not has_boss():
		if monster_mode == ConstLevelData.E_MonsterMode.Boss:
			errors.append("Boss 出怪模式必须配置 boss_type。")
		return errors

	# 注册表为静态公共定义，校验无需依赖 Global 节点已经完成 _ready()。
	if not CharacterRegistry.ZombieBossInfo.has(boss_type):
		errors.append("boss_type 未在角色注册表中注册：%s。" % boss_type)
	else:
		var boss_info: Dictionary = CharacterRegistry.ZombieBossInfo[boss_type]
		var scene := boss_info.get(CharacterRegistry.ZombieBossInfoAttribute.BossScenes) as PackedScene
		if scene == null or not scene.can_instantiate():
			errors.append("注册的僵王场景无效或无法实例化。")

	match monster_mode:
		ConstLevelData.E_MonsterMode.Boss:
			if boss_spawn_wave != 0:
				errors.append("Boss 出怪模式的 boss_spawn_wave 必须为 0，表示正式开战时生成。")
		ConstLevelData.E_MonsterMode.Norm:
			if boss_spawn_wave < 0 or boss_spawn_wave > max_wave:
				errors.append("正常出怪模式的 boss_spawn_wave 必须在 0 到 max_wave 之间。")
		_:
			errors.append("当前仅正常出怪模式和 Boss 出怪模式支持配置僵王。")

	# 现有多轮存档不保存僵王的血量与生成状态，首版不能无提示地允许该组合。
	if game_round != 1:
		errors.append("配置僵王的关卡暂只支持单轮游戏，game_round 必须为 1。")
	if is_pot_mode or pot_mode != ConstLevelData.E_PotMode.Null or is_zombie_mode:
		errors.append("僵王配置暂不支持与罐子模式或我是僵尸模式组合。")
	# 负坐标可用于场外入场；只拒绝 NaN、无穷等无法定位角色的坐标。
	if not boss_spawn_position.is_finite():
		errors.append("boss_spawn_position 必须为有限坐标。")
	return errors


func _apply_card_mode_constraints() -> void:
	match card_mode:
		ConstLevelData.E_CardMode.Norm:
			pass
		ConstLevelData.E_CardMode.ConveyorBelt:
			can_choosed_card = false
			is_day_sun = false
	if card_mode != ConstLevelData.E_CardMode.Norm and can_choosed_card:
		print("warning: 当前卡槽模式无法选卡, 已修改选卡为false")
		can_choosed_card = false


func _pad_prechosen_cards() -> void:
	if pre_choosed_card_list_plant.size() < max_choosed_card_num:
		GlobalUtils.pad_array(pre_choosed_card_list_plant, max_choosed_card_num, 0)
	if pre_choosed_card_list_zombie.size() < max_choosed_card_num:
		GlobalUtils.pad_array(pre_choosed_card_list_zombie, max_choosed_card_num, 0)
	print("预选卡植物:", pre_choosed_card_list_plant)
	print("预选卡僵尸:", pre_choosed_card_list_zombie)


func _init_zombie_refresh_from_whitelist() -> void:
	if monster_mode != ConstLevelData.E_MonsterMode.Norm:
		return
	whitelist_refresh_zombie_types = Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[Global.main_scene_registry.ZombieRowTypewithMainScenesMap[game_sences]]
	zombie_refresh_types = filter_invalid_zombie_refresh_types(zombie_refresh_types, whitelist_refresh_zombie_types)


func _normalize_pot_col_range() -> void:
	if pot_mode == ConstLevelData.E_PotMode.Null:
		return
	if pot_col_range.x > pot_col_range.y:
		pot_col_range = Vector2i(pot_col_range.y, pot_col_range.x)
	print("生成罐子的列数为", pot_col_range.x, "（含）到", pot_col_range.y, "（不含）")


func _init_pot_mode() -> void:
	match pot_mode:
		ConstLevelData.E_PotMode.Weight:
			_init_pot_mode_weight()
		ConstLevelData.E_PotMode.Fixd:
			_init_pot_mode_fixed()
		_:
			pass


func _init_pot_mode_weight() -> void:
	weight_pot_type_sum = weight_pot_type.x + weight_pot_type.y + weight_pot_type.z
	if candidate_plant_pot.is_empty():
		for plant_type in Global.global_read_data.whitelist_plant_types_with_pot:
			candidate_plant_pot[plant_type] = 1
	else:
		for plant_type in candidate_plant_pot.keys():
			if Global.global_read_data.blacklist_plant_types_with_pot.has(plant_type):
				candidate_plant_pot.erase(plant_type)
				print("warning: 植物", Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.PlantName), "在罐子刷新黑名单中，已删除该植物")
	if candidate_zombie_pot.is_empty():
		for zombie_type in Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[CharacterRegistry.ZombieRowType.Land]:
			candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Land][zombie_type] = 1
		for zombie_type in Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[CharacterRegistry.ZombieRowType.Pool]:
			candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Pool][zombie_type] = 1
	else:
		for zombie_type: CharacterRegistry.ZombieType in candidate_zombie_pot.keys():
			if Global.global_read_data.blacklist_zombie_types_with_pot.has(zombie_type):
				candidate_zombie_pot.erase(zombie_type)
				print("warning: 僵尸", Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieName), "在罐子刷新黑名单中，已删除该僵尸")
				continue

			var curr_zombie_row_type: CharacterRegistry.ZombieRowType = Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieRowType)
			match curr_zombie_row_type:
				CharacterRegistry.ZombieRowType.Land:
					candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Land][zombie_type] = candidate_zombie_pot[zombie_type]
				CharacterRegistry.ZombieRowType.Pool:
					candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Pool][zombie_type] = candidate_zombie_pot[zombie_type]
				CharacterRegistry.ZombieRowType.Both:
					candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Land][zombie_type] = candidate_zombie_pot[zombie_type]
					candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Pool][zombie_type] = candidate_zombie_pot[zombie_type]
		if candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Land].is_empty():
			for zombie_type in Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[CharacterRegistry.ZombieRowType.Land]:
				candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Land][zombie_type] = 1
		if candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Pool].is_empty():
			for zombie_type in Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[CharacterRegistry.ZombieRowType.Pool]:
				candidate_zombie_pot_with_zombie_row_type[CharacterRegistry.ZombieRowType.Pool][zombie_type] = 1


func _init_pot_mode_fixed() -> void:
	pot_num_on_fixed_mode = 0
	for plant_type in random_pot_plant.keys():
		if Global.global_read_data.blacklist_plant_types_with_pot.has(plant_type):
			random_pot_plant.erase(plant_type)
			print("warning: 植物", Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.PlantName), "在罐子刷新黑名单中，已删除该植物")
		else:
			pot_num_on_fixed_mode += random_pot_plant[plant_type]
	for plant_type in plant_pot.keys():
		if Global.global_read_data.blacklist_plant_types_with_pot.has(plant_type):
			plant_pot.erase(plant_type)
			print("warning: 植物", Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.PlantName), "在罐子刷新黑名单中，已删除该植物")
		else:
			pot_num_on_fixed_mode += plant_pot[plant_type]
	for zombie_type in random_pot_zombie.keys():
		if Global.global_read_data.blacklist_zombie_types_with_pot.has(zombie_type):
			random_pot_zombie.erase(zombie_type)
			print("warning: 僵尸", Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieName), "在罐子刷新黑名单中，已删除该僵尸")
		else:
			pot_num_on_fixed_mode += random_pot_zombie[zombie_type]
	for zombie_type in zombie_pot.keys():
		if Global.global_read_data.blacklist_zombie_types_with_pot.has(zombie_type):
			zombie_pot.erase(zombie_type)
			print("warning: 僵尸", Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieName), "在罐子刷新黑名单中，已删除该僵尸")
		else:
			pot_num_on_fixed_mode += zombie_pot[zombie_type]
	pot_num_on_fixed_mode += random_pot_num_on_fixed_mode.x + random_pot_num_on_fixed_mode.y + random_pot_num_on_fixed_mode.z
	print("固定模式的罐子需求总数（包括结果固定罐子和结果随机罐子）为：", pot_num_on_fixed_mode)
	random_pot_zombie_with_zombie_row_type = get_pot_zombie_with_row_type_pot_on_fiexd_mode(random_pot_zombie)
	zombie_pot_with_zombie_row_type = get_pot_zombie_with_row_type_pot_on_fiexd_mode(zombie_pot)


func _apply_zombie_mode_rules() -> void:
	if is_zombie_mode:
		is_zombie_can_home = false


func _maybe_load_multi_round_save() -> void:
	if game_round != 1:
		print("更新多轮游戏存档数据")
		update_data_with_save_game_data()


## 罐子固定生成模式下，获取僵尸按行类型生成的分类字典
func get_pot_zombie_with_row_type_pot_on_fiexd_mode(pot_zombie_dic: Dictionary) -> Dictionary[CharacterRegistry.ZombieRowType, Dictionary]:
	var pot_zombie_with_row_type: Dictionary[CharacterRegistry.ZombieRowType, Dictionary] = {
		CharacterRegistry.ZombieRowType.Land: {},
		CharacterRegistry.ZombieRowType.Pool: {},
		CharacterRegistry.ZombieRowType.Both: {},
	}
	for zombie_type in pot_zombie_dic.keys():
		var zombie_row_type: CharacterRegistry.ZombieRowType = Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieRowType)
		pot_zombie_with_row_type[zombie_row_type][zombie_type] = pot_zombie_dic[zombie_type]

	return pot_zombie_with_row_type


## 更新数据 (存档相关)
func update_data_with_save_game_data() -> void:
	var path = get_save_game_path()
	if ResourceLoader.exists(path):
		var res = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res is ResourceSaveGameMainGame:
			save_game_data_main_game = res
			print("加载关卡数据存档成功：", path)
		else:
			push_error("加载的资源类型不对: “%s” 不是 ResourceSaveGameMainGame" % path)
			save_game_data_main_game = null
	else:
		print("关卡数据存档不存在：", path)
		save_game_data_main_game = null


## 删除存档
func delete_game_data():
	save_game_data_main_game = null
	var path = get_save_game_path()

	if ResourceLoader.exists(path):
		var err = DirAccess.remove_absolute(path)
		if err == OK:
			print("删除存档成功：", path)
			return true
		else:
			push_error("删除存档失败: %s 错误码 %d" % [path, err])
			return false

#region 自然刷怪过滤
## 当前场景可以刷新的僵尸
var whitelist_refresh_zombie_types: Array[CharacterRegistry.ZombieType] = []

## 根据白名单过滤出怪类型列表。
## 不修改入参 zombie_types，返回新数组。若列表中含 Z021Bungi，会将本资源的 is_bungi 设为 true。
func filter_invalid_zombie_refresh_types(
	zombie_types: Array[CharacterRegistry.ZombieType],
	curr_whitelist_refresh_zombie_types: Array[CharacterRegistry.ZombieType]
) -> Array[CharacterRegistry.ZombieType]:
	var out: Array[CharacterRegistry.ZombieType] = []
	var is_err := false
	for zt: CharacterRegistry.ZombieType in zombie_types:
		if not curr_whitelist_refresh_zombie_types.has(zt):
			print(
				"warning: 出怪刷新列表中",
				Global.character_registry.get_zombie_info(zt, CharacterRegistry.ZombieInfoAttribute.ZombieName),
				"不在当前场景可以自然刷怪列表"
			)
			is_err = true
			continue
		if zt == CharacterRegistry.ZombieType.Z021Bungi:
			print("warning: 出怪刷新列表禁止使用 Z021Bungi ,已修改为选择 is_bungi 参数")
			is_bungi = true
			is_err = true
			continue
		out.append(zt)

	if is_err:
		print("将上述出怪刷新列表错误僵尸删除")

	return out

#endregion

#region 存档
## 读档系统只能从空白场景读档
## 获取存档路径
func get_save_game_path() -> String:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(Global.user_manager.curr_user_name + "/" + Global.save_service.MAIN_GAME_SAVE_DIR_NAME):
		dir.make_dir(Global.user_manager.curr_user_name + "/" + Global.save_service.MAIN_GAME_SAVE_DIR_NAME)

	return "user://" + Global.user_manager.curr_user_name + "/" + Global.save_service.MAIN_GAME_SAVE_DIR_NAME + "/" + save_game_name + ".tres"

#endregion
