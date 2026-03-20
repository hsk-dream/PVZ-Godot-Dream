extends Control
## 正常卡槽
class_name CardSlotCoin

## 出战卡槽节点
@onready var card_slot_battle_coin: CardSlotBattleCoin = $CardSlotBattleCoin

#endregion
## 初始化出战卡槽，管理器调用
func init_card_slot_coin(game_para:ResourceLevelData):
	card_slot_battle_coin.init_card_slot_battle(game_para.max_choosed_card_num)
	## 初始化预选卡
	if game_para.pre_choosed_card_list_plant or game_para.pre_choosed_card_list_zombie:
		init_pre_choosed_card(game_para.pre_choosed_card_list_plant, game_para.pre_choosed_card_list_zombie)

## 初始化系统预选卡
## 从AllCards中复制一张新卡,隐藏card_slot_candidate的卡片
func init_pre_choosed_card(card_type_list:Array[EnumsCharacter.PlantType], card_type_list_zombie:Array[EnumsCharacter.ZombieType]):
	for i in card_type_list.size():
		var card:Card
		var plant_type:EnumsCharacter.PlantType = card_type_list[i]
		var zombie_type:EnumsCharacter.ZombieType = card_type_list_zombie[i]
		var character_type:EnumsCharacter.CharacterType = GlobalUtils.get_character_type(plant_type, zombie_type)
		match character_type:
			EnumsCharacter.CharacterType.Plant:
				card = AllCards.all_plant_card_prefabs[plant_type].duplicate()
			EnumsCharacter.CharacterType.Zombie:
				card = AllCards.all_zombie_card_prefabs[zombie_type].duplicate()
			EnumsCharacter.CharacterType.Null:
				continue

		card_slot_battle_coin.curr_cards.append(card)
		pre_choosed_card(card, card_slot_battle_coin.cards_placeholder[len(card_slot_battle_coin.curr_cards)-1])

## 系统预选卡
func pre_choosed_card(card:Card, target_parent):
	target_parent.add_child(card)
	card.position = Vector2.ZERO
	#card.card_change_cool_time(0)

## 移动卡槽（出现或隐藏）
func move_card_slot_candidate(is_appeal:bool):
	var tween = create_tween()
	if is_appeal:
		tween.tween_property(card_slot_battle_coin, "position",Vector2(0, 89.0), 0.2) # 时间可以改短点
	else:
		tween.tween_property(card_slot_battle_coin, "position",Vector2(0, 615.0), 0.2) # 时间可以改短点

	await tween.finished

## 移动待选卡槽（出现或隐藏）
func move_card_slot_battle(is_appeal:bool, appeal_time:= 0.2):
	var tween = create_tween()
	if is_appeal:
		tween.tween_property(card_slot_battle_coin, "position",Vector2(0, 0), appeal_time)
	else:
		tween.tween_property(card_slot_battle_coin, "position",Vector2(0, -100.0), appeal_time)
	await tween.finished
