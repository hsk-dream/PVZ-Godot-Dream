extends Node

## 全局注册表（Character/MainScene/Bullet/Item registry）
# 这里提供便捷的 registry 引用给全局使用者
@onready var character_registry: CharacterRegistry = %CharacterRegistry
@onready var main_scene_registry: MainSceneRegistry = %MainSceneRegistry
@onready var bullet_registry: BulletRegistry = %BulletRegistry
@onready var item_registry: ItemRegistry = %ItemRegistry
## 用户管理（已从 Global 拆分）
@onready var user_manager: UserManager = %UserManager
@onready var save_service: SaveService = %SaveService
@onready var config_service: ConfigService = %ConfigService
@onready var global_game_state: GlobalGameState = %GlobalGameState
@onready var global_read_data: GlobalReadData = %GlobalReadData



func _ready() -> void:
	## 读取当前用户名
	var is_have_user := user_manager.load_current_user()
	if is_have_user and not user_manager.curr_user_name.is_empty():
		## 加载全局数据存档
		save_service.load_global_game_data()
		## 初始化配置（音量 + 用户选项）
		config_service.load_and_apply_config()
	## 创建全局数据自动存档计时器（由 SaveService 负责）
	save_service.start_autosave(60.0)

var main_game:MainGameManager
var game_para:ResourceLevelData


#region 全局游戏数据
#region 金币
## 显示金币的label
var coin_value_label:CoinBankLabel

## 生产金币,按概率生产，概率和为1, 将金币生产在coin_bank_bank（coin_value_label）节点下
## 概率顺序为 银币金币和钻石
func create_coin(probability:Array=[0.5, 0.5, 0], global_position_new_coin:Vector2=Vector2.ZERO, target_position:Vector2=Vector2(randf_range(-50, 50), randf_range(80, 90))):
	coin_value_label.update_label()
	## 如果当前场景有金币值的label,将金币生产在coin_bank_bank（coin_value_label）节点下
	if is_instance_valid(coin_value_label):
		var probability_sum: float = float(probability[0]) + float(probability[1]) + float(probability[2])
		assert(abs(probability_sum - 1.0) < 0.001, "概率和不为1")
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

#endregion

#endregion

## 游戏倍速
var time_scale := 1.0

#endregion

