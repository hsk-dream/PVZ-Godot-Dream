## 卡牌共有外观与战斗参数；身份由引用提供，费用和冷却由角色注册表初始化。
extends Control
class_name CardBase

## 卡牌背景与缩略图容器。
@onready var card_bg: TextureRect = $CardBg
## 当前费用文字；没有战斗参数的内容隐藏此节点。
@onready var cost: Label = $CardBg/Cost
## 冷却及不可用状态遮罩。
@onready var _cool_mask: ProgressBar = $ProgressBar

## 卡牌背景样式。
enum E_CardBg {
	CB01Norm, ## 普通背景。
	CB02Purple, ## 紫卡背景。
	CB03Gray, ## 模仿卡背景。
}

## 背景样式的共享纹理，不存入卡牌身份数据。
const CARD_BG_MAP: Dictionary[E_CardBg, Resource] = {
	E_CardBg.CB01Norm: preload("res://resources/card_bg/01Norm.tres"),
	E_CardBg.CB02Purple: preload("res://resources/card_bg/02Purple.tres"),
	E_CardBg.CB03Gray: preload("res://resources/card_bg/03Gray.tres"),
}

## 唯一卡牌身份；源模板及关卡引用不应被运行状态改写。
@export var card_reference: ResourceCardReference
## 根据植物条件推导的紫卡标记，其他类型始终为 false。
var is_purple_card: bool = false
## 当前背景；紫卡和模仿修饰在初始化时覆盖默认样式。
@export var curr_card_gb: E_CardBg = E_CardBg.CB01Norm
## 植物专用种植条件；其他卡牌不访问此字段。
var plant_condition: ResourcePlantCondition
## 当前实例的冷却时长，单位为游戏秒；模式可在初始化后覆盖。
var cool_time: float = 0.0:
	set(value):
		cool_time = value
		if is_instance_valid(_cool_mask):
			_cool_mask.max_value = value
## 当前实例的基础阳光费用；金币模式在结算处应用倍率。
var sun_cost: int = 0:
	set(value):
		sun_cost = value
		if is_instance_valid(cost):
			cost.text = str(value)


## 根据已配置的身份初始化参数与外观；空模板仅供编辑器布局，不参与注册。
## 引用合法性确认后，将通用整数编号按类别显式转换为枚举，再查询角色注册表。
func _ready() -> void:
	if card_reference == null or not card_reference.is_valid():
		cost.hide()
		return
	match card_reference.card_type:
		ResourceCardReference.CardType.Plant:
			# 在植物边界解释角色编号，不能依靠其他类别的空字段推导。
			var plant_type: CharacterRegistry.PlantType = card_reference.content_id as CharacterRegistry.PlantType
			sun_cost = Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.SunCost)
			cool_time = Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.CoolTime)
			plant_condition = Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.PlantConditionResource)
			is_purple_card = plant_condition.is_purple_card
			if is_purple_card:
				curr_card_gb = E_CardBg.CB02Purple
			if card_reference.is_imitater:
				curr_card_gb = E_CardBg.CB03Gray
		ResourceCardReference.CardType.Zombie:
			# 普通僵尸的费用和冷却沿用角色注册表。
			var zombie_type: CharacterRegistry.ZombieType = card_reference.content_id as CharacterRegistry.ZombieType
			sun_cost = Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.SunCost)
			cool_time = Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.CoolTime)
		ResourceCardReference.CardType.ZombieBoss:
			# 每张僵王卡独立维护费用和冷却，实际召唤实例不共享卡片运行状态。
			var boss_type: CharacterRegistry.ZombieBossType = card_reference.content_id as CharacterRegistry.ZombieBossType
			sun_cost = Global.character_registry.get_zombie_boss_info(boss_type, CharacterRegistry.ZombieBossInfoAttribute.SunCost)
			cool_time = Global.character_registry.get_zombie_boss_info(boss_type, CharacterRegistry.ZombieBossInfoAttribute.CoolTime)
	card_bg.texture = CARD_BG_MAP[curr_card_gb]
