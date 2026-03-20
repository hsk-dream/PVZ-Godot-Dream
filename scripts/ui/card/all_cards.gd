@tool
extends Control
## 所有的卡片
class_name AllCardsClass

@onready var all_plant_cards_parent_node_root: Array[GridContainer] = [
	%PlantCards, %PlantCards2
]
@onready var all_zombie_cards_parent_node_root: Array[GridContainer] = [
	%ZombieCards, %ZombieCards2
]

@export var all_plant_card_prefabs:Dictionary[EnumsCharacter.PlantType, Card]
@export var all_zombie_card_prefabs:Dictionary[EnumsCharacter.ZombieType, Card]

@export var plant_card_ids :Dictionary[EnumsCharacter.PlantType, int]
@export var zombie_card_ids :Dictionary[EnumsCharacter.ZombieType, int]

var frame_num := 0


## 更新每个已经制作的卡片（卡片类型不为空）
func _ready() -> void:
	## 非编辑器中运行隐藏(游戏中)
	if not Engine.is_editor_hint():
		visible = false
	var plant_i = -1
	all_plant_card_prefabs.clear()
	for plant_cards_parent_node in all_plant_cards_parent_node_root:
		for i in range(plant_cards_parent_node.get_children().size()):
			var card:Card = plant_cards_parent_node.get_children()[i]
			if card.card_plant_type != 0:
				plant_i += 1
				var card_para:Dictionary[Card.E_CInitAttr, Variant] = {
					Card.E_CInitAttr.CardId:plant_i,
					Card.E_CInitAttr.CoolTime:Global.character_registry.PlantInfo[card.card_plant_type][EnumsCharacter.PlantInfoAttribute.CoolTime],
					Card.E_CInitAttr.SunCost:Global.character_registry.PlantInfo[card.card_plant_type][EnumsCharacter.PlantInfoAttribute.SunCost]
				}
				#card.init_card(card_para)
				init_card(card, card_para)
				all_plant_card_prefabs[card.card_plant_type] = card
				plant_card_ids[card.card_plant_type] = plant_i

	var zombie_i = -1
	all_zombie_card_prefabs.clear()
	for zombie_cards_parent_node in all_zombie_cards_parent_node_root:
		for i in range(zombie_cards_parent_node.get_children().size()):
			var card:Card = zombie_cards_parent_node.get_children()[i]
			if card.card_zombie_type != 0:
				zombie_i += 1
				card.card_id = zombie_i
				card.cool_time = Global.character_registry.ZombieInfo[card.card_zombie_type][EnumsCharacter.ZombieInfoAttribute.CoolTime]
				card.sun_cost = Global.character_registry.ZombieInfo[card.card_zombie_type][EnumsCharacter.ZombieInfoAttribute.SunCost]
				all_zombie_card_prefabs[card.card_zombie_type] = card
				zombie_card_ids[card.card_zombie_type] = zombie_i

func init_card(card:CardBase, card_init_para:Dictionary):
	card.card_id = card_init_para[CardBase.E_CInitAttr.CardId]
	card.cool_time = card_init_para[CardBase.E_CInitAttr.CoolTime]
	card.sun_cost = card_init_para[CardBase.E_CInitAttr.SunCost]

#### 该部分物理帧实际运行时删除
#func _physics_process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#frame_num += 1
		#if frame_num % 100 == 0:
			#print("更新一次")
			#frame_num = 0
			#for card in all_plant_card_prefabs.values():
				#for card_child_node in card.get_children():
					#if card_child_node is Character000Base:
						#card_child_node.script = null   # 解绑脚本
						#var character = card_child_node
						### 植物
						#character.scale = Vector2(0.5, 0.5)
						#character.position = Vector2(25, 44)
						#### 僵尸
						##character.scale = Vector2(0.3, 0.3)
						##character.position = Vector2(2, 15)
#
						### 删除角色非body和非动画其子节点
						#for character_child_node in character.get_children():
							#if character_child_node.name not in ["Body", "AnimationPlayer"]:
								#if character_child_node.name == "Shadow":
									#character_child_node.visible = false
								#else:
									#character_child_node.queue_free()
#
							#elif character_child_node.name == "Body":
								#character_child_node.script = null   # 解绑脚本
								#for body_child_node in character_child_node.get_children():
									#if body_child_node.name != "BodyCorrect":
										#body_child_node.queue_free()
#
	#else:
		#printerr("将该部分注释掉")
#####
#func _physics_process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#frame_num += 1
		#if frame_num % 100 == 0:
			#print("更新一次")
			#frame_num = 0
			#for card in all_zombie_card_prefabs.values():
				#for card_child_node in card.get_children():
					#if card_child_node is Character000Base:
						#card_child_node.script = null   # 解绑脚本
						#var character = card_child_node
						### 植物
						##character.scale = Vector2(0.5, 0.5)
						##character.position = Vector2(25, 44)
						### 僵尸
						#character.scale = Vector2(0.3, 0.3)
						#character.position = Vector2(26, 47)
#
						### 删除角色非body和非动画其子节点
						#for character_child_node in character.get_children():
							#if character_child_node.name not in ["Body", "AnimationPlayer"]:
								#character_child_node.queue_free()
#
							#elif character_child_node.name == "Body":
								#character_child_node.script = null   # 解绑脚本
#
#
	#else:
		#printerr("将该部分注释掉")
#
