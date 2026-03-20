extends Panel
class_name AlmanacCharacterShowPanel
## 图鉴植物信息描述

const CharacterBgMap = {
	"Day": preload("res://assets/image/Almanac/Almanac_GroundDay.jpg"),
	"Ice":preload("res://assets/image/Almanac/Almanac_GroundIce.jpg"),
	"Night": preload("res://assets/image/Almanac/Almanac_GroundNight.jpg"),
	"Pool": preload("res://assets/image/Almanac/Almanac_GroundPool.jpg"),
	"Fog": preload("res://assets/image/Almanac/Almanac_GroundNightPool.jpg"),
	"Roof": preload("res://assets/image/Almanac/Almanac_GroundRoof.jpg")
}

## 背景
@onready var character_bg: TextureRect = $CharacterBg
## 角色名字
@onready var character_name: Label = $AllBg/CharacterName
## 描述
@onready var character_text_1: Label = $AllBg/ScrollContainer/VBoxContainer/CharacterText1
## 参数列表容器
@onready var character_text_2_para: VBoxContainer = $AllBg/ScrollContainer/VBoxContainer/CharacterText2Para
## 提示
@onready var character_text_3_hint: Label = $AllBg/ScrollContainer/VBoxContainer/CharacterText3Hint
## 介绍
@onready var character_text_4_introduction: Label = $AllBg/ScrollContainer/VBoxContainer/CharacterText4Introduction
##　花费
@onready var cost: HBoxContainer = $AllBg/PlantEndPara/Cost
## 冷却
@onready var cool_time: HBoxContainer = $AllBg/PlantEndPara/CoolTime

## 正在展示的角色
var show_character:Character000Base

## 更新图鉴植物信息
func almanac_update_plant_panel(curr_plant_type:EnumsCharacter.PlantType):
	var curr_plant_name = Global.character_registry.get_plant_info(curr_plant_type, EnumsCharacter.PlantInfoAttribute.PlantName)
	almanac_update_character_panel_common(Global.global_read_data.data_almanac["Plant"][curr_plant_name])

	## 花费
	cost.get_node("Value").text = str(Global.character_registry.get_plant_info(curr_plant_type,  EnumsCharacter.PlantInfoAttribute.SunCost))
	## 冷却时间
	cool_time.get_node("Value").text = str(Global.character_registry.get_plant_info(curr_plant_type,  EnumsCharacter.PlantInfoAttribute.CoolTime))
	cool_time.get_node("Value").text += "(秒)"
	## 展示植物
	create_plant(curr_plant_type)

func create_plant(curr_plant_type:EnumsCharacter.PlantType):
	var plant_scene = Global.character_registry.get_plant_info(curr_plant_type, EnumsCharacter.PlantInfoAttribute.PlantScenes)
	var new_show_plant:Plant000Base = plant_scene.instantiate()
	var plant_init_para:Dictionary = {Plant000Base.E_PInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsShow}
	new_show_plant.init_plant(plant_init_para)
	character_bg.add_child(new_show_plant)
	new_show_plant.position = Vector2(100,120)

	special_plant_update_pos(new_show_plant)

	if is_instance_valid(show_character):
		show_character.queue_free()

	show_character = new_show_plant

## 生成的特殊植物修改位置
func special_plant_update_pos(new_show_plant:Plant000Base):
	match new_show_plant.plant_type:
		EnumsCharacter.PlantType.P048CobCannon:
			new_show_plant.position = Vector2(60,130)


## 更新图鉴僵尸信息
func almanac_update_zombie_panel(curr_zombie_type:EnumsCharacter.ZombieType):
	var curr_zombie_name = Global.character_registry.get_zombie_info(curr_zombie_type, EnumsCharacter.ZombieInfoAttribute.ZombieName)
	almanac_update_character_panel_common(Global.global_read_data.data_almanac["Zombie"][curr_zombie_name])
	create_zombie(curr_zombie_type)

func create_zombie(curr_zombie_type:EnumsCharacter.ZombieType):
	var zombie_scene = Global.character_registry.get_zombie_info(curr_zombie_type, EnumsCharacter.ZombieInfoAttribute.ZombieScenes)
	var new_show_zombie:Zombie000Base = zombie_scene.instantiate()
	var zombie_init_para:Dictionary = {Zombie000Base.E_ZInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsShow}
	new_show_zombie.init_zombie(zombie_init_para)
	character_bg.add_child(new_show_zombie)
	new_show_zombie.position = Vector2(100,166)
	special_zombie_update_pos(new_show_zombie)
	if is_instance_valid(show_character):
		show_character.queue_free()
	show_character = new_show_zombie

## 生成的特殊僵尸修改位置
func special_zombie_update_pos(new_show_zombie:Zombie000Base):
	match new_show_zombie.zombie_type:
		EnumsCharacter.ZombieType.Z024Gargantuar:
			new_show_zombie.position = Vector2(100,200)


## 更新通用数据
func almanac_update_character_panel_common(data_almanac_character:Dictionary):
	character_bg.texture = CharacterBgMap[data_almanac_character["背景"]]
	## 名字
	character_name.text = data_almanac_character["名字"]
	## 描述
	character_text_1.text = data_almanac_character["描述"]
	var num_para = data_almanac_character["参数"].size()
	## 参数
	for i in range(num_para):
		var curr_plant_para = character_text_2_para.get_child(i)
		var curr_key = data_almanac_character["参数"].keys()[i]
		curr_plant_para.get_node("Key").text = curr_key
		curr_plant_para.get_node("Value").text = data_almanac_character["参数"][curr_key]
		curr_plant_para.visible = true
	for i in range(num_para, character_text_2_para.get_children().size()):
		character_text_2_para.get_child(i).visible = false
	## 提示
	if data_almanac_character.has("提示"):
		character_text_3_hint.text = data_almanac_character["提示"]
		character_text_3_hint.visible = true
	else:
		character_text_3_hint.visible = false
	## 简介
	character_text_4_introduction.text = data_almanac_character["简介"]


#endregion
