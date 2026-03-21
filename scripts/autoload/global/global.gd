extends Node

## 全局注册表（Character/MainScene/Bullet/Item registry）
# 这里提供便捷的 registry 引用给全局使用者
@onready var character_registry: CharacterRegistry = %CharacterRegistry
@onready var main_scene_registry: MainSceneRegistry = %MainSceneRegistry
@onready var bullet_registry: BulletRegistry = %BulletRegistry
@onready var item_registry: ItemRegistry = %ItemRegistry
## 用户管理（已从 Global 拆分）
@onready var user_manager: UserManager = %UserManager
## 存档服务
@onready var save_service: SaveService = %SaveService
## 配置服务（用户音量、控制台）
@onready var config_service: ConfigService = %ConfigService
## 全局游戏状态（金币、花园数据、关卡数据、当前植物、当前僵尸）
@onready var global_game_state: GlobalGameState = %GlobalGameState
## 全局只读数据（图鉴数据、刷怪白名单、罐子白名单等）
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

## 游戏倍速
var time_scale := 1.0

