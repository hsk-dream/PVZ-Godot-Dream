## 展示已解锁植物的图鉴卡片，并把统一角色引用交给详情面板。
extends TextureRect
class_name AlmanacPlantPage

## 已解锁植物卡片的排列容器。
@onready var card_grid_container: GridContainer = $CardGridContainer
## 根据角色引用显示植物介绍和展示实例的详情面板。
@onready var almanac_character_show_panel: AlmanacCharacterShowPanel = $AlmanacCharacterShowPanel


## 创建有图鉴资料的植物卡片，并默认显示第一个可用条目；空目录不创建展示实例。
func init_almanac_page() -> void:
	# 首个成功创建的图鉴卡片引用，用于初始化详情；无可用条目时保持 null。
	var first_reference: ResourceCardReference
	# 当前已解锁植物类型，沿用游戏状态中的显示顺序。
	for plant_type: int in Global.global_game_state.curr_plant:
		# 注册表中的资料键，图鉴只显示 JSON 中已编写的条目。
		var plant_name: String = Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.PlantName)
		if not Global.global_read_data.data_almanac.get("Plant", {}).has(plant_name):
			continue
		# 植物条目的统一引用；图鉴目录展示原植物，不采用模仿者变体。
		var reference := ResourceCardReference.create(ResourceCardReference.CardType.Plant, plant_type)
		# 工厂在入树前应用 Almanac 上下文，点击直接进入图鉴详情。
		var plant_card: Card = AllCards.create_card(reference, Card.CardContext.Almanac)
		if plant_card == null:
			continue
		plant_card.signal_card_click.connect(_on_plant_card_clicked)
		card_grid_container.add_child(plant_card)
		if first_reference == null:
			first_reference = reference
	if first_reference != null:
		almanac_character_show_panel.show_card(first_reference)


## [param card] 为被点击的植物图鉴卡；详情通过其引用选择角色与资料。
func _on_plant_card_clicked(card: Card) -> void:
	almanac_character_show_panel.show_card(card.card_reference)
