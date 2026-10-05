## 金币卡槽使用统一卡牌引用初始化预选卡，费用和次数仍由出战卡槽结算。
extends Control
class_name CardSlotCoin

## 金币模式的出战卡槽。
@onready var card_slot_battle_coin: CardSlotBattleCoin = $CardSlotBattleCoin

## 依据 [param game_para] 创建金币槽位及其预选卡。
func init_card_slot_coin(game_para: ResourceLevelData) -> void:
	card_slot_battle_coin.init_card_slot_battle(game_para.max_choosed_card_num)
	init_pre_choosed_card(game_para.prechosen_cards)

## 按 [param references] 的顺序创建出战卡；拒绝僵王及其他未支持的类别。
func init_pre_choosed_card(references: Array[ResourceCardReference]) -> void:
	# 每个引用表示一张完整卡片，不再组合植物、僵尸补零数组。
	for reference: ResourceCardReference in references:
		if not AllCards.is_battle_card(reference):
			push_error("CardSlotCoin：预选卡必须是已注册的植物或普通僵尸。")
			continue
		if card_slot_battle_coin.curr_cards.size() >= card_slot_battle_coin.cards_placeholder.size():
			break
		# 挂载前设置合法引用和交互上下文。
		var card: Card = AllCards.create_card(reference, Card.CardContext.Battle)
		if card == null:
			continue
		card_slot_battle_coin.curr_cards.append(card)
		pre_choosed_card(card, card_slot_battle_coin.cards_placeholder[card_slot_battle_coin.curr_cards.size() - 1])

## 将 [param card] 挂到 [param target_parent] 的金币卡槽占位。
func pre_choosed_card(card: Card, target_parent: Control) -> void:
	target_parent.add_child(card)
	card.position = Vector2.ZERO

## 根据 [param is_appeal] 移动卡槽；[param appeal_time] 是等待动画完成的耗时，单位秒。
func move_card_slot_battle(is_appeal: bool, appeal_time: float = 0.2) -> void:
	# 金币卡槽的位移动画。
	var tween: Tween = create_tween()
	tween.tween_property(card_slot_battle_coin, "position", Vector2(0, 0) if is_appeal else Vector2(0, -100.0), appeal_time)
	await tween.finished
