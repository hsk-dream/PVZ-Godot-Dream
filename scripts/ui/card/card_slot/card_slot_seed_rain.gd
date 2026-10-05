## 按统一卡牌引用生成种子雨临时卡，保留随机位置、下落和限时消失。
extends Control
class_name CardSlotSeedRain

## 统一引用的卡牌随机池。
@onready var card_random_pool: CardRandomPool = $CardRandomPool
## 新卡生成计时器。
@onready var create_new_card_timer: Timer = $CreateNewCardTimer
## 卡片生成的全局 x 坐标范围，单位像素。
@export var card_area_x_range: Vector2 = Vector2(100, 700)
## 卡片生成的全局 y 坐标范围，单位像素。
@export var card_area_y_range: Vector2 = Vector2(100, 500)
## 生成序号到完整引用的覆盖表，缺省序号从随机池抽取。
var card_order: Dictionary[int, ResourceCardReference] = {}
## 两次生成的随机间隔范围，单位秒。
@export var card_create_cd_range: Vector2 = Vector2(3, 5)
## 临时卡正常存在时间，结束后另有 5 秒闪烁阶段。
@export var card_exist_time_norm: float = 10.0
## 从零开始累计的已生成卡片数量。
var all_num_card: int = 0

## 从 [param game_para] 获取种子雨的统一有序表和权重条目。
func init_card_slot_seed_rain(game_para: ResourceLevelData) -> void:
	card_random_pool.init_card_random_pool(game_para.seed_rain_weights)
	card_order = game_para.seed_rain_order

## 到期时生成一张卡，并按原有间隔范围安排下一张。
func _on_create_new_card_timer_timeout() -> void:
	_create_new_card()
	create_new_card_timer.start(randf_range(card_create_cd_range.x, card_create_cd_range.y))

## 创建有效出战引用的临时卡；僵王和其他类别不会进入种子雨。
func _create_new_card() -> void:
	# 有序表和权重池使用相同的完整引用。
	var reference: ResourceCardReference = card_order.get(all_num_card) if card_order.has(all_num_card) else card_random_pool.get_random_reference()
	if not AllCards.is_battle_card(reference):
		push_error("CardSlotSeedRain：生成引用不是有效的出战卡。")
		return
	# 保留原有全局随机位置分布。
	var global_pos: Vector2 = Vector2(randf_range(card_area_x_range.x, card_area_x_range.y), randf_range(card_area_y_range.x, card_area_y_range.y))
	# 卡片生命周期由卡片管理器拥有，种子雨只添加下落效果。
	var new_card: Card = Global.main_game.card_manager.create_temp_card(reference, global_pos, card_exist_time_norm)
	if new_card == null:
		return
	seed_rain_card_update(new_card)
	all_num_card += 1

## 为 [param seed_rain_card] 添加原有的一秒、30 像素缓慢下落动画。
func seed_rain_card_update(seed_rain_card: Card) -> void:
	# 卡片专属下落动画，随卡片释放自动结束。
	var tween: Tween = seed_rain_card.create_tween()
	tween.tween_property(seed_rain_card, ^"position:y", seed_rain_card.position.y + 30, 1.0)

## 开始或恢复种子雨生成计时。
func start_seed_rain() -> void:
	if create_new_card_timer.paused:
		create_new_card_timer.paused = false
	if create_new_card_timer.is_stopped():
		create_new_card_timer.start(randf_range(card_create_cd_range.x, card_create_cd_range.y))

## 暂停新卡生成，已有临时卡仍由自己的生命周期管理。
func pause_seed_rain() -> void:
	create_new_card_timer.paused = true

