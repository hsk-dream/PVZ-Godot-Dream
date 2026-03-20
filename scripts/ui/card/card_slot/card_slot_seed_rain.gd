extends Control
class_name CardSlotSeedRain

@onready var card_random_pool: CardRandomPool = $CardRandomPool
@onready var create_new_card_timer: Timer = $CreateNewCardTimer

## 卡片范围
@export var card_area_x_range:Vector2 = Vector2(100,700)
@export var card_area_y_range:Vector2 = Vector2(100,500)
## 按顺序出现的卡片植物
@export var card_order_plant:Dictionary[int, EnumsCharacter.PlantType] = {}
## 按顺序出现的卡片僵尸(若重复,则使用植物的卡片)
@export var card_order_zombie:Dictionary[int, EnumsCharacter.ZombieType] = {}
## 创建卡片的时间
@export var card_create_cd_range:Vector2 = Vector2(3,5)
## 卡片正常存在时间,存在时间结束后闪烁5秒后消失
@export var card_exist_time_norm:float = 10.0
## 当前生成的卡片总数量
var all_num_card :int = 0

## 管理器初始化调用
func init_card_slot_seed_rain(game_para:ResourceLevelData):
	var card_random_pool_init_para = {
		CardRandomPool.E_CardRandomPoolInitParaAttr.AllCardPlantProbability: game_para.all_card_plant_type_probability_seed_rain,
		CardRandomPool.E_CardRandomPoolInitParaAttr.AllCardZombieProbability: game_para.all_card_zombie_type_probability_seed_rain,
	}
	print("种子雨卡槽初始化随机卡片生成器")
	card_random_pool.init_card_random_pool(card_random_pool_init_para)

	self.card_order_plant = game_para.card_order_plant_seed_rain
	self.card_order_zombie = game_para.card_order_zombie_seed_rain

func _on_create_new_card_timer_timeout() -> void:
	_create_new_card()
	create_new_card_timer.start(randf_range(card_create_cd_range.x, card_create_cd_range.y))

enum E_TempCardParaAttr{
	PlantType,
	ZombieType,
	GlobalPos,
	ExistTime,	## 存在时间，若没有，则永久存在
}
## 生成一张新卡片
func _create_new_card():
	var temp_card_para:Dictionary = {}
	if card_order_plant.has(all_num_card):
		temp_card_para[CardManager.E_TempCardParaAttr.PlantType] = card_order_plant[all_num_card]
	elif card_order_zombie.has(all_num_card):
		temp_card_para[CardManager.E_TempCardParaAttr.ZombieType] = card_order_zombie[all_num_card]
	else:
		var card_random_info = card_random_pool.get_random_card_info()
		temp_card_para[CardManager.E_TempCardParaAttr.PlantType] = card_random_info["plant_type"]
		temp_card_para[CardManager.E_TempCardParaAttr.ZombieType] = card_random_info["zombie_type"]

	temp_card_para[CardManager.E_TempCardParaAttr.GlobalPos] = Vector2(randf_range(card_area_x_range.x, card_area_x_range.y),randf_range(card_area_y_range.x, card_area_y_range.y))
	temp_card_para[CardManager.E_TempCardParaAttr.ExistTime] = card_exist_time_norm
	var new_card = Global.main_game.card_manager.create_temp_card(temp_card_para)

	seed_rain_card_update(new_card)
	all_num_card += 1

## 种子雨卡片更新: 缓慢下落,时间限制
func seed_rain_card_update(seed_rain_card:Card):
	var tween:Tween = seed_rain_card.create_tween()
	tween.tween_property(seed_rain_card, ^"position:y", seed_rain_card.position.y+30, 1.0)

## 开始种子雨
func start_seed_rain():
	if create_new_card_timer.paused:
		create_new_card_timer.paused = false
	if create_new_card_timer.is_stopped():
		create_new_card_timer.start(randf_range(card_create_cd_range.x, card_create_cd_range.y))

func pause_seed_rain():
	create_new_card_timer.paused = true

