extends Node


#region 全局注册表（Character/MainScene/Bullet/Item registry）
# 这里提供便捷的 registry 引用给全局使用者
@onready var character_registry: CharacterRegistry = %CharacterRegistry
@onready var main_scene_registry: MainSceneRegistry = %MainSceneRegistry
@onready var bullet_registry: BulletRegistry = %BulletRegistry
@onready var item_registry: ItemRegistry = %ItemRegistry
#endregion

#region 用户管理（已从 Global 拆分）
@onready var user_manager: UserManager = %UserManager
#endregion


func _ready() -> void:
	## 读取当前用户名
	var is_have_user := user_manager.load_current_user()
	if is_have_user and not user_manager.curr_user_name.is_empty():
		## 加载全局数据存档
		load_global_game_data()
	## 创建全局数据自动存档计时器
	_create_save_game_timer()
	## 更新游戏场景可以刷新的白名单
	update_whitelist_refresh_zombie_types_with_zombie_row_type()
	## 更新罐子可以刷新的白名单
	update_whitelist_plant_types_with_pot()

var main_game:MainGameManager
var game_para:ResourceLevelData


#region 图鉴信息
var data_almanac:Dictionary
const PathDataAlmanac := "res://data/almanac_data.json"
#endregion

#region 全局游戏数据
#region 金币
## 金币数量
var coin_value : int = DefaultCoinValue:
	set(value):
		coin_value_change.emit()
		## 若存在金币显示ui 更新金币
		coin_value = value
		if coin_value_label:
			coin_value_label.update_label()
## 默认金币数量
const DefaultCoinValue:int = 0

## 金币改变信号
signal coin_value_change
## 显示金币的label
var coin_value_label:CoinBankLabel

## 生产金币,按概率生产，概率和为1, 将金币生产在coin_bank_bank（coin_value_label）节点下
## 概率顺序为 银币金币和钻石
func create_coin(probability:Array=[0.5, 0.5, 0], global_position_new_coin:Vector2=Vector2.ZERO, target_position:Vector2=Vector2(randf_range(-50, 50), randf_range(80, 90))):
	coin_value_label.update_label()
	## 如果当前场景有金币值的label,将金币生产在coin_bank_bank（coin_value_label）节点下
	if is_instance_valid(coin_value_label):
		assert(probability[0] + probability[1] + probability[2], "概率和不为1")
		var r = randf()
		var new_coin:Coin
		if r < probability[0]:
			new_coin = SceneRegistry.COIN_SILVER.instantiate()
		elif r < probability[0] + probability[1]:
			new_coin = SceneRegistry.COIN_GOLD.instantiate()
		else:
			new_coin = SceneRegistry.COIN_DIAMOND.instantiate()
		coin_value_label.add_child(new_coin)
		## 主游戏场景中,摄像位置修正
		if is_instance_valid(main_game):
			global_position_new_coin -= main_game.camera_2d.global_position
		new_coin.global_position = global_position_new_coin
		## 抛物线发射金币
		new_coin.launch(target_position)
	else:
		printerr("生成金币但没有coin_value_label")
#endregion

#region 花园
# TODO:暂时先写global，后面要改?
# 也可能不改 -- 20250907
## 掉落花园植物
func create_garden_plant(global_position_new_garden_plant:Vector2):
	coin_value_label.update_label()

	var new_garden_plant:Present = SceneRegistry.PRESENT.instantiate()

	coin_value_label.add_child(new_garden_plant)
	## 主游戏场景中,摄像位置修正
	if is_instance_valid(main_game):
		global_position_new_garden_plant -= main_game.camera_2d.global_position
	new_garden_plant.global_position = global_position_new_garden_plant
	SoundManager.play_other_SFX("chime")

## 当前花园的新增植物数量，进入花园时处理
var curr_num_new_garden_plant :int = DefaultCurrNumNewGardenPlant
## 默认花园新增植物数量
const DefaultCurrNumNewGardenPlant:int =3

## 花园数据
var garden_data:Dictionary = DefaultGardenData.duplicate(true)
## 默认花园数据
const DefaultGardenData:Dictionary = {
	"num_bg_page_0":1,
	"num_bg_page_1":1,
	"num_bg_page_2":1,
}
#endregion

#region 关卡状态
## 当前所有的关卡游戏状态[save_game_name, Dictionary]
var curr_all_level_state_data:Dictionary = DefaultCurrAllLevelStateData.duplicate(true)
const DefaultCurrAllLevelStateData:Dictionary = {}
"""
## 一个关卡的游戏状态的例子
var curr_one_level_state_data:Dictionary = {
	"IsSuccess":false,
	"IsHaveMultiRoundSaveGameData":false,
	"CurrGameRound":1
}
"""
#endregion
#endregion

#region 自动保存全局数据存档
func _create_save_game_timer():
	var save_game_timer = Timer.new()

	save_game_timer.wait_time = 60
	save_game_timer.one_shot = false
	save_game_timer.autostart = true
	add_child(save_game_timer)
	# 连接超时信号
	save_game_timer.timeout.connect(_on_save_game_timer_timeout)


func _on_save_game_timer_timeout():
	print("自动保存全局数据存档")
	save_global_game_data()
#endregion

#region 保存数据

#region 存档全局数据
## 主游戏存档文件夹名字
const MainGameSaveDirName := "main_game_saves_data"
## 当前全局数据存档系统版本号
const SaveGameVersion:="20251130"

## 验证并创建存档文件夹，创建用户名时调用
func _ensure_save_directory_exists(user_name:String):
	var save_dir_path = "user://" + user_name + "/" + MainGameSaveDirName
	if not DirAccess.dir_exists_absolute(save_dir_path):
		var err = DirAccess.make_dir_recursive_absolute(save_dir_path)
		if err == OK:
			print("✅ 创建存档文件夹成功：", save_dir_path)
		else:
			push_error("❌ 创建存档文件夹失败，错误码：", err)
	else:
		print("存在存档文件")

## 保存全局数据存档到 JSON 文件
func save_global_game_data() -> void:
	if user_manager == null or user_manager.curr_user_name.is_empty():
		print("当前用户名不存在，无法保存全局数据存档")
		return
	print("保存全局数据存档")
	var data = {
		"version": SaveGameVersion,
		"coin_value": coin_value,
		"garden_data": garden_data,
		"curr_num_new_garden_plant": curr_num_new_garden_plant,
		"curr_all_level_state_data": curr_all_level_state_data,
	}
	var save_game_path = "user://" + user_manager.curr_user_name + "/GlobalSaveGame.json"
	save_json(data, save_game_path)

## 加载全局数据档
func load_global_game_data() -> void:
	print("加载全局数据存档")
	var save_game_path = "user://" + user_manager.curr_user_name + "/GlobalSaveGame.json"
	var data = load_json(save_game_path) as Dictionary
	coin_value = data.get("coin_value", DefaultCoinValue)
	curr_num_new_garden_plant = data.get("curr_num_new_garden_plant", DefaultCurrNumNewGardenPlant)
	garden_data = data.get("garden_data", DefaultGardenData.duplicate(true))
	curr_all_level_state_data = data.get("curr_all_level_state_data", DefaultCurrAllLevelStateData.duplicate(true))
#endregion

#region 保存上次选卡信息
## 植物选卡和僵尸选卡
var selected_cards := []
func save_selected_cards():
	print("保存选卡信息存档")
	var data:Dictionary = {
		"selected_cards" : selected_cards,
	}
	var selected_cards_path =  "user://" + user_manager.curr_user_name + "/selected_cards.json"
	save_json(data, selected_cards_path)

func load_selected_cards():
	print("加载选卡信息存档")
	var selected_cards_path =  "user://" + user_manager.curr_user_name + "/selected_cards.json"
	var data = load_json(selected_cards_path) as Dictionary
		# 加载数据
	selected_cards = data.get("selected_cards", [])
#endregion

#region 保存数据方法
## 保存数据到json
func save_json(data:Dictionary, path:String):
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("❌ 无法打开文件进行写入: %s" % path)
		return false

	var json_text := JSON.stringify(data, "\t")  # 可读性更强
	file.store_string(json_text)
	file.close()
	print("✅ 存档已保存到", path)

## 从json中读取数据
func load_json(path:String):
	if not FileAccess.file_exists(path):
		print("⚠️ 存档文件不存在: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("❌ 无法打开文件进行读取: %s" % path)
		return {}
	var json_text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(json_text)
	if result == null:
		push_error("❌ JSON 解析失败")
		return {}

	print("✅ 成功读取json文件:", path)
	return result
#endregion

#endregion

#region 用户配置相关

## 用户选项控制台
var auto_collect_sun := false
var auto_collect_coin := false
var disappear_spare_card_Placeholder := false:
	set(value):
		disappear_spare_card_Placeholder = value
		signal_change_disappear_spare_card_placeholder.emit()
## 卡槽显示改变,隐藏多余卡槽
signal signal_change_disappear_spare_card_placeholder

## 需要区分植物和僵尸，因此将值作为参数发射
var display_plant_HP_label := false:
	set(value):
		display_plant_HP_label = value
		signal_change_display_plant_HP_label.emit(display_plant_HP_label)
## 血量显示改变信号
signal signal_change_display_plant_HP_label(value:bool)

var display_zombie_HP_label := false:
	set(value):
		display_zombie_HP_label = value
		signal_change_display_zombie_HP_label.emit(display_zombie_HP_label)

## 血量显示改变信号
signal signal_change_display_zombie_HP_label(value:bool)

var card_slot_top_mouse_focus := false:
	set(value):
		card_slot_top_mouse_focus = value
		signal_change_card_slot_top_mouse_focus.emit()
signal signal_change_card_slot_top_mouse_focus

## 静态迷雾
var fog_is_static := false:
	set(value):
		fog_is_static = value
		signal_fog_is_static.emit()

signal signal_fog_is_static

var plant_be_shovel_front := true	## 预铲除植物本格置顶

## 打开所有关卡，默认为冒险开放1关，其余开放三关,无尽模式默认开放
var open_all_level := false

var time_scale := 1.0

func save_config():
	var config_path := "user://" + user_manager.curr_user_name + "/config.ini"
	print("保存游戏控制台数据：", config_path)
	var config := ConfigFile.new()
	## 音乐相关
	config.set_value("audio", "master", SoundManager.get_volum(SoundManager.Bus.MASTER))
	config.set_value("audio", "bgm", SoundManager.get_volum(SoundManager.Bus.BGM))
	config.set_value("audio", "sfx", SoundManager.get_volum(SoundManager.Bus.SFX))
	# 用户选项控制台相关
	config.set_value("user_control", "auto_collect_sun", auto_collect_sun)
	config.set_value("user_control", "auto_collect_coin", auto_collect_coin)
	config.set_value("user_control", "disappear_spare_card_Placeholder", disappear_spare_card_Placeholder)
	config.set_value("user_control", "display_plant_HP_label", display_plant_HP_label)
	config.set_value("user_control", "display_zombie_HP_label", display_zombie_HP_label)
	config.set_value("user_control", "card_slot_top_mouse_focus", card_slot_top_mouse_focus)
	config.set_value("user_control", "fog_is_static", fog_is_static)
	config.set_value("user_control", "plant_be_shovel_front", plant_be_shovel_front)
	config.set_value("user_control", "open_all_level", open_all_level)

	config.save(config_path)



func load_config():
	var config := ConfigFile.new()
	var config_path := "user://" + user_manager.curr_user_name + "/config.ini"
	print("加载游戏控制台数据：", config_path)
	config.load(config_path)

	SoundManager.set_volume(
		SoundManager.Bus.MASTER,
		config.get_value("audio", "master", 1)
	)

	SoundManager.set_volume(
		SoundManager.Bus.BGM,
		config.get_value("audio", "bgm", 0.5)
	)

	SoundManager.set_volume(
		SoundManager.Bus.SFX,
		config.get_value("audio", "sfx", 0.5)
	)

	auto_collect_sun = config.get_value("user_control", "auto_collect_sun", false)
	auto_collect_coin = config.get_value("user_control", "auto_collect_coin", false)
	disappear_spare_card_Placeholder = config.get_value("user_control", "disappear_spare_card_Placeholder", false)
	display_plant_HP_label = config.get_value("user_control", "display_plant_HP_label", false)
	display_zombie_HP_label = config.get_value("user_control", "display_zombie_HP_label", false)
	card_slot_top_mouse_focus = config.get_value("user_control", "card_slot_top_mouse_focus", false)
	fog_is_static = config.get_value("user_control", "fog_is_static", false)
	plant_be_shovel_front = config.get_value("user_control", "plant_be_shovel_front", true)
	open_all_level = config.get_value("user_control", "open_all_level", false)
#endregion

#region 当前植物和僵尸
var curr_plant = [
	EnumsCharacter.PlantType.P001PeaShooterSingle,
	EnumsCharacter.PlantType.P002SunFlower,
	EnumsCharacter.PlantType.P003CherryBomb,
	EnumsCharacter.PlantType.P004WallNut,
	EnumsCharacter.PlantType.P005PotatoMine,
	EnumsCharacter.PlantType.P006SnowPea,
	EnumsCharacter.PlantType.P007Chomper,
	EnumsCharacter.PlantType.P008PeaShooterDouble,

	EnumsCharacter.PlantType.P009PuffShroom,
	EnumsCharacter.PlantType.P010SunShroom,
	EnumsCharacter.PlantType.P011FumeShroom,
	EnumsCharacter.PlantType.P012GraveBuster,
	EnumsCharacter.PlantType.P013HypnoShroom,
	EnumsCharacter.PlantType.P014ScaredyShroom,
	EnumsCharacter.PlantType.P015IceShroom,
	EnumsCharacter.PlantType.P016DoomShroom,

	EnumsCharacter.PlantType.P017LilyPad,
	EnumsCharacter.PlantType.P018Squash,
	EnumsCharacter.PlantType.P019ThreePeater,
	EnumsCharacter.PlantType.P020TangleKelp,
	EnumsCharacter.PlantType.P021Jalapeno,
	EnumsCharacter.PlantType.P022Caltrop,
	EnumsCharacter.PlantType.P023TorchWood,
	EnumsCharacter.PlantType.P024TallNut,

	EnumsCharacter.PlantType.P025SeaShroom,
	EnumsCharacter.PlantType.P026Plantern,
	EnumsCharacter.PlantType.P027Cactus,
	EnumsCharacter.PlantType.P028Blover,
	EnumsCharacter.PlantType.P029SplitPea,
	EnumsCharacter.PlantType.P030StarFruit,
	EnumsCharacter.PlantType.P031Pumpkin,
	EnumsCharacter.PlantType.P032MagnetShroom,

	EnumsCharacter.PlantType.P033CabbagePult,
	EnumsCharacter.PlantType.P034FlowerPot,
	EnumsCharacter.PlantType.P035CornPult,
	EnumsCharacter.PlantType.P036CoffeeBean,
	EnumsCharacter.PlantType.P037Garlic,
	EnumsCharacter.PlantType.P038UmbrellaLeaf,
	EnumsCharacter.PlantType.P039MariGold,
	EnumsCharacter.PlantType.P040MelonPult,

	EnumsCharacter.PlantType.P041GatlingPea,
	EnumsCharacter.PlantType.P042TwinSunFlower,
	EnumsCharacter.PlantType.P043GloomShroom,
	EnumsCharacter.PlantType.P044Cattail,
	EnumsCharacter.PlantType.P045WinterMelon,
	EnumsCharacter.PlantType.P046GoldMagnet,
	EnumsCharacter.PlantType.P047SpikeRock,
	EnumsCharacter.PlantType.P048CobCannon,

	#EnumsCharacter.PlantType.P049PeaShooterDoubleReverse,
	#EnumsCharacter.PlantType.P1001WallNutBowling,
	#EnumsCharacter.PlantType.P1002WallNutBowlingBomb,
	#EnumsCharacter.PlantType.P1003WallNutBowlingBig,
]

var curr_zombie = [
	EnumsCharacter.ZombieType.Z001Norm,
	EnumsCharacter.ZombieType.Z002Flag,
	EnumsCharacter.ZombieType.Z003Cone,
	EnumsCharacter.ZombieType.Z004PoleVaulter,
	EnumsCharacter.ZombieType.Z005Bucket,

	EnumsCharacter.ZombieType.Z006Paper,
	EnumsCharacter.ZombieType.Z007ScreenDoor,
	EnumsCharacter.ZombieType.Z008Football,
	EnumsCharacter.ZombieType.Z009Jackson,
	EnumsCharacter.ZombieType.Z010Dancer,

	EnumsCharacter.ZombieType.Z011Duckytube,
	EnumsCharacter.ZombieType.Z012Snorkle,
	EnumsCharacter.ZombieType.Z013Zamboni,
	EnumsCharacter.ZombieType.Z014Bobsled,
	EnumsCharacter.ZombieType.Z015Dolphinrider,

	EnumsCharacter.ZombieType.Z016Jackbox,
	EnumsCharacter.ZombieType.Z017Balloon,
	EnumsCharacter.ZombieType.Z018Digger,
	EnumsCharacter.ZombieType.Z019Pogo,
	EnumsCharacter.ZombieType.Z020Yeti,

	EnumsCharacter.ZombieType.Z021Bungi,
	EnumsCharacter.ZombieType.Z022Ladder,
	EnumsCharacter.ZombieType.Z023Catapult,
	EnumsCharacter.ZombieType.Z024Gargantuar,
	EnumsCharacter.ZombieType.Z025Imp,
	### 单人雪橇车小队僵尸
	EnumsCharacter.ZombieType.Z1001BobsledSingle,
]
#endregion


#endregion

#region 主游戏场景相关

#region 僵尸刷怪限制
## 僵尸行类型可以自然刷新的僵尸白名单
var whitelist_refresh_zombie_types_with_zombie_row_type:Dictionary[EnumsCharacter.ZombieRowType, Array] = {}

## 蹦极僵尸可以选择,选择后自动更新删除,修改游戏参数的is_bungi值
## 自然刷怪出现的僵尸黑名单类型(null, 旗帜, 鸭子, 伴舞, 小鬼, 滑雪单人)
var blacklist_refresh_zombie_types:Array[EnumsCharacter.ZombieType] = [
	EnumsCharacter.ZombieType.Null,
	EnumsCharacter.ZombieType.Z002Flag,
	EnumsCharacter.ZombieType.Z011Duckytube,
	EnumsCharacter.ZombieType.Z010Dancer,
	EnumsCharacter.ZombieType.Z025Imp,
	EnumsCharacter.ZombieType.Z1001BobsledSingle,
]

## 获取僵尸行类型对应的 僵尸刷新白名单
func get_whitelist_refresh_zombie_types_on_zombie_row_type(curr_zombie_row_type:EnumsCharacter.ZombieRowType) -> Array[EnumsCharacter.ZombieType]:
	var curr_whitelist_refresh_zombie_types:Array[EnumsCharacter.ZombieType] = []
	for zombie_type in EnumsCharacter.ZombieType.values():
		## 僵尸类型不能刷新
		if blacklist_refresh_zombie_types.has(zombie_type):
			continue

		## 满足当前场景的僵尸行类型
		if curr_zombie_row_type == EnumsCharacter.ZombieRowType.Both:
			curr_whitelist_refresh_zombie_types.append(zombie_type)
		else:
			var zombie_row_type:EnumsCharacter.ZombieRowType = character_registry.get_zombie_info(zombie_type, EnumsCharacter.ZombieInfoAttribute.ZombieRowType)
			if zombie_row_type == EnumsCharacter.ZombieRowType.Both:
				curr_whitelist_refresh_zombie_types.append(zombie_type)
			elif zombie_row_type == curr_zombie_row_type:
				curr_whitelist_refresh_zombie_types.append(zombie_type)

	return curr_whitelist_refresh_zombie_types

## 更新自然刷怪僵尸白名单
func update_whitelist_refresh_zombie_types_with_zombie_row_type():
	whitelist_refresh_zombie_types_with_zombie_row_type.clear()
	for curr_zombie_row_type in EnumsCharacter.ZombieRowType.values():
		whitelist_refresh_zombie_types_with_zombie_row_type[curr_zombie_row_type] = get_whitelist_refresh_zombie_types_on_zombie_row_type(curr_zombie_row_type)


#endregion

#region 植物罐子刷新限制
## 随机罐子刷新的植物白名单
var whitelist_plant_types_with_pot:Array[EnumsCharacter.PlantType] = []
## 罐子模式无冷却植物卡牌类型
var zero_cd_plnat_card_type_on_pot_mode: Array =[
	EnumsCharacter.PlantType.P017LilyPad,
	EnumsCharacter.PlantType.P034FlowerPot,
	EnumsCharacter.PlantType.P036CoffeeBean,
]


## 随机罐子刷新的植物黑名单类型(null等)
var blacklist_plant_types_with_pot:Array[EnumsCharacter.PlantType] = [
	EnumsCharacter.PlantType.Null,
	EnumsCharacter.PlantType.P036CoffeeBean,
	EnumsCharacter.PlantType.P999Imitater,
	EnumsCharacter.PlantType.P1000Sprout,
]
## 随机罐子刷新的僵尸黑名单,白名单使用自然刷怪白名单
var blacklist_zombie_types_with_pot:Array[EnumsCharacter.ZombieType] = [
	EnumsCharacter.ZombieType.Null,
	EnumsCharacter.ZombieType.Z011Duckytube,
]

## 更新随机罐子刷新白名单
func update_whitelist_plant_types_with_pot():
	whitelist_plant_types_with_pot.clear()
	for plant_type in EnumsCharacter.PlantType.values():
		if blacklist_plant_types_with_pot.has(plant_type):
			continue
		else:
			whitelist_plant_types_with_pot.append(plant_type)

#endregion

#endregion
