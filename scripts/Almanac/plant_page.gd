extends TextureRect
class_name AlmanacPlantPage

## 卡片父节点
@onready var card_grid_container: GridContainer = $CardGridContainer
@onready var almanac_character_show_panel: AlmanacCharacterShowPanel = $AlmanacCharacterShowPanel


func init_almanac_page() -> void:
	## 连接所有植物卡片点击信号
	init_plant_card()
	almanac_character_show_panel.almanac_update_plant_panel(Global.curr_plant[0])

## 植物卡片初始化类型 连接点击信号
func init_plant_card():
	for plant_type in Global.curr_plant:
		var curr_plant_name = Global.character_registry.get_plant_info(plant_type, EnumsCharacter.PlantInfoAttribute.PlantName)
		## 如果有图鉴数据
		if Global.data_almanac["Plant"].has(curr_plant_name):
			var curr_plant_card:Card = AllCards.all_plant_card_prefabs[plant_type].duplicate()
			card_grid_container.add_child(curr_plant_card)
			curr_plant_card.signal_card_click.connect(almanac_character_show_panel.almanac_update_plant_panel.bind(curr_plant_card.card_plant_type))
			curr_plant_card.set_almanac_card()
