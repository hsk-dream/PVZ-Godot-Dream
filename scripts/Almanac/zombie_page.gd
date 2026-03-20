extends TextureRect
class_name AlmanacZombiePage

## 卡片父节点
@onready var card_grid_container: GridContainer = $CardGridContainer
@onready var almanac_character_show_panel: AlmanacCharacterShowPanel = $AlmanacCharacterShowPanel

## 图鉴僵尸卡牌场景
const ALMANAC_ZOMBIE_CARD = preload("res://scenes/almanac/almanac_zombie_card.tscn")

func init_almanac_page() -> void:
	## 连接所有僵尸卡片点击信号
	init_zombie_card()
	almanac_character_show_panel.almanac_update_zombie_panel(Global.curr_zombie[0])
#
## 植物卡片初始化类型 连接点击信号
func init_zombie_card():
	for zombie_type in Global.curr_zombie:
		var curr_zombie_name = Global.character_registry.get_zombie_info(zombie_type, EnumsCharacter.ZombieInfoAttribute.ZombieName)
		if Global.data_almanac["Zombie"].has(curr_zombie_name):
			var curr_zombie_card:AlmanacZombieCard = ALMANAC_ZOMBIE_CARD.instantiate()
			curr_zombie_card.init_almanac_zombie_card(zombie_type)
			card_grid_container.add_child(curr_zombie_card)
			curr_zombie_card.signal_card_click.connect(almanac_character_show_panel.almanac_update_zombie_panel.bind(curr_zombie_card.zombie_type))
