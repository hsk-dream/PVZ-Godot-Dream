extends Control
class_name CardBase

@onready var card_bg: TextureRect = $CardBg
@onready var cost: Label = $CardBg/Cost
@onready var _cool_mask: ProgressBar = $ProgressBar

enum E_CardBg{
	CB01Norm,	## 普通卡片背景
	CB02Purple,	## 紫卡背景
	CB03Gray,	## 灰卡背景
}

## 卡片背景对应资源
var CradBgMap:Dictionary[E_CardBg, Resource] = {
	E_CardBg.CB01Norm:load("res://resources/card_bg/01Norm.tres"),
	E_CardBg.CB02Purple:load("res://resources/card_bg/02Purple.tres"),
	E_CardBg.CB03Gray:load("res://resources/card_bg/03Gray.tres")
}

## 卡片索引位置,用于在备选卡槽时确定位置
@export var card_id :int = -1
## 植物卡片类型，植物卡片类型为EnumsCharacter.PlantType.Null时为僵尸卡片
@export var card_plant_type: EnumsCharacter.PlantType
## 僵尸卡片类型
@export var card_zombie_type: EnumsCharacter.ZombieType
## 是否为紫卡
var is_purple_card := false
## 卡片背景,紫卡会自动更换背景
@export var curr_card_gb :E_CardBg = E_CardBg.CB01Norm
## 该植物种植条件,紫卡使用内部方法判断是否可以种植
var plant_condition:ResourcePlantCondition
## 卡片冷却时间
@export var cool_time: float = 7.5:
	set(value):
		cool_time = value
		if _cool_mask:
			_cool_mask.max_value = value

## 卡片阳光消耗
@export var sun_cost: int = 100:
	set(value):
		sun_cost = value
		if cost:
			cost.text = str(int(value))

## 是否为模仿者
@export var is_imitater := false

func _ready() -> void:
	## 如果是植物,根据是否为紫卡更新背景
	if card_plant_type != 0:
		plant_condition = Global.character_registry.get_plant_info(card_plant_type, EnumsCharacter.PlantInfoAttribute.PlantConditionResource)
		is_purple_card = plant_condition.is_purple_card
		if is_purple_card:
			curr_card_gb = E_CardBg.CB02Purple
		if is_imitater:
			curr_card_gb = E_CardBg.CB03Gray


		card_bg.texture = CradBgMap[curr_card_gb]

## 卡片初始化参数
enum E_CInitAttr{
	CardId,	## 卡片id,目前没有用到,植物卡片和僵尸卡片单独使用
	SunCost,
	CoolTime,
}

func init_card(card_init_para:Dictionary):
	card_id = card_init_para[E_CInitAttr.CardId]
	cool_time = card_init_para[E_CInitAttr.CoolTime]
	sun_cost = card_init_para[E_CInitAttr.SunCost]

