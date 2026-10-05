## 展示已解锁普通僵尸及有图鉴资料的僵王，两个目录共用头像卡片。
extends TextureRect
class_name AlmanacZombiePage

## 普通僵尸和僵王头像卡片的排列容器。
@onready var card_grid_container: GridContainer = $CardGridContainer
## 消费统一角色引用的图鉴详情面板。
@onready var almanac_character_show_panel: AlmanacCharacterShowPanel = $AlmanacCharacterShowPanel

## 图鉴专用头像卡片场景，仅展示静态预览，不承担选卡或出战行为。
const ALMANAC_PORTRAIT_CARD = preload("res://scenes/almanac/almanac_portrait_card.tscn")


## 合并普通僵尸和僵王条目，过滤缺少模板或 JSON 资料的角色后显示首个有效条目。
func init_almanac_page() -> void:
	# 普通僵尸在前、僵王在后的目录引用，保留已有普通僵尸解锁顺序。
	var references: Array[ResourceCardReference] = []
	# 当前已解锁普通僵尸类型，只通过引用加入展示目录。
	for zombie_type: int in Global.global_game_state.curr_zombie:
		references.append(ResourceCardReference.create(ResourceCardReference.CardType.Zombie, zombie_type))
	references.append_array(AllCards.get_references(ResourceCardReference.CardType.ZombieBoss))
	# 首个成功添加的角色，用于默认详情；目录为空时保持 null。
	var first_reference: ResourceCardReference
	# 当前候选目录引用；模板与资料都存在才创建头像。
	for reference: ResourceCardReference in references:
		if not _has_almanac_entry(reference) or AllCards.get_template(reference) == null:
			continue
		# 当前图鉴头像卡片，初始化引用在加入场景树之前完成。
		var portrait_card: AlmanacPortraitCard = ALMANAC_PORTRAIT_CARD.instantiate()
		portrait_card.init_almanac_portrait_card(reference)
		portrait_card.signal_card_click.connect(almanac_character_show_panel.show_card)
		card_grid_container.add_child(portrait_card)
		if first_reference == null:
			first_reference = reference
	if first_reference != null:
		almanac_character_show_panel.show_card(first_reference)


## [param reference] 为普通僵尸或僵王的目录引用；对应 JSON 资料存在时返回 true。
func _has_almanac_entry(reference: ResourceCardReference) -> bool:
	# 资料所在的角色目录，普通僵尸和僵王使用不同 JSON 分组。
	var section: String
	# 注册表名称，作为图鉴资料的查询键。
	var character_key: String
	match reference.card_type:
		ResourceCardReference.CardType.Zombie:
			section = "Zombie"
			character_key = Global.character_registry.get_zombie_info(reference.content_id, CharacterRegistry.ZombieInfoAttribute.ZombieName)
		ResourceCardReference.CardType.ZombieBoss:
			section = "ZombieBoss"
			character_key = Global.character_registry.get_zombie_boss_info(reference.content_id, CharacterRegistry.ZombieBossInfoAttribute.BossName)
		_:
			return false
	return Global.global_read_data.data_almanac.get(section, {}).has(character_key)
