extends PanelContainer
## 出战卡槽
class_name CardSlotBattle

@onready var curr_sun_value: Label = $SunLabelControl/CurrSunValue
@onready var card_placeholder_ori: TextureRect = $CardUiList/CardPlaceholder_ori
@onready var card_ui_list: HBoxContainer = $CardUiList
@onready var marker_2d_sun_target: Marker2D = %Marker2DSunTarget

## 出战卡槽占位节点
var cards_placeholder:Array = []
## 出战卡片
var curr_cards : Array[Card]
## 阳光值
var sun_value:
	set(value):
		sun_value = value
		curr_sun_value.text = str(value)

		for card in curr_cards:
			card.judge_sun_enough(value)

func _ready() -> void:
	Global.config_service.signal_change_disappear_spare_card_placeholder.connect(judge_disappear_add_card_bar)
	EventBus.subscribe("test_change_sun_value", func(value): sun_value = value)
	EventBus.subscribe("add_sun_value", func(value): sun_value+=value)
	EventBus.subscribe("update_card_purple_sun_cost", update_card_purple_sun_cost)


## 初始化出战卡槽，管理器调用
func init_card_slot_battle(max_choosed_card_num:int, sun:int):
	self.sun_value = sun
	for i in range(max_choosed_card_num):
		var cloned_card_placeholder = card_placeholder_ori.duplicate()
		card_ui_list.add_child(cloned_card_placeholder)

	card_placeholder_ori.free()		## 立即删除掉该节点，下面获取卡槽占位节点
	cards_placeholder = card_ui_list.get_children()
	## 更新阳光收集位置
	EventBus.push_event("update_marker_2d_sun_target", marker_2d_sun_target)

	return cards_placeholder

## 正式战斗时切换卡片上下文、检查费用并连接一次成功结算信号。
func main_game_refresh_card():
	update_card_purple_sun_cost()
	# 出战卡顺序决定快捷键位置。
	for i: int in range(curr_cards.size()):
		# 当前槽位卡片，由目录能力再次确认不能使用僵王。
		var card: Card = curr_cards[i]
		if not AllCards.is_battle_card(card.card_reference):
			card.set_card_disable()
			continue
		card.card_context = Card.CardContext.Battle
		card.judge_sun_enough(sun_value)
		card.set_shortcut((i+1)%10)
		if not card.signal_card_use_end.is_connected(card_use_end):
			card.signal_card_use_end.connect(card_use_end)
	judge_disappear_add_card_bar()

## 下一轮重选前恢复选择上下文和冷却，解除本轮的使用结算。
func start_next_game_card_slot_battle_update():
	# 本轮保留的卡片顺序不变。
	for i: int in range(curr_cards.size()):
		# 需要恢复为选卡交互的卡片。
		var card: Card = curr_cards[i]
		card.card_context = Card.CardContext.Selection
		## 卡牌冷却结束,可以点击
		card.set_card_cool_end()
		card.card_ready()
		card.set_shortcut_disappear()
		if card.signal_card_use_end.is_connected(card_use_end):
			card.signal_card_use_end.disconnect(card_use_end)

## [param card] 成功使用后扣除当前阳光价格，并开始原有冷却。
func card_use_end(card:Card):
	## 减少阳光，卡片冷却
	sun_value = sun_value - card.sun_cost
	card.card_cool()

#region 控制台相关
## 是否显示多余卡槽
func judge_disappear_add_card_bar():
	## 在游戏进行阶段
	if Global.main_game.main_game_progress == MainGameManager.E_MainGameProgress.MAIN_GAME:
		if Global.config_service.disappear_spare_card_Placeholder:
			if curr_cards.size() < cards_placeholder.size():
				for i in range(curr_cards.size(), cards_placeholder.size()):
					cards_placeholder[i].visible = false
		else:
			for i in range(cards_placeholder.size()):
				cards_placeholder[i].visible = true
	else:
		for i in range(cards_placeholder.size()):
			cards_placeholder[i].visible = true

#endregion

## 植物数量变化一帧后刷新植物紫卡价格，普通僵尸及僵王不查询植物计数。
func update_card_purple_sun_cost():
	await get_tree().process_frame
	# 本次仍在槽中的卡片。
	for card: Card in curr_cards:
		if card.card_reference.card_type != ResourceCardReference.CardType.Plant:
			continue
		# 紫卡的植物内容编号，用于查询本关同种植物数量。
		var plant_type: int = card.card_reference.content_id
		if card.is_purple_card and Global.main_game.plant_cell_manager.curr_plant_num.has(plant_type):
			card.sun_cost = Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.SunCost) + 50 * Global.main_game.plant_cell_manager.curr_plant_num[plant_type]
			card.judge_sun_enough(sun_value)
