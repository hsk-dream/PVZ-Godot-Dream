## 根据统一卡牌引用展示植物、普通僵尸和僵王的图鉴资料与专用展示实例。
extends Panel
class_name AlmanacCharacterShowPanel

## 图鉴 JSON 背景名称对应的静态地面贴图，所有角色共用同一组素材。
const CHARACTER_BG_MAP = {
	"Day": preload("res://assets/image/Almanac/Almanac_GroundDay.jpg"),
	"Ice": preload("res://assets/image/Almanac/Almanac_GroundIce.jpg"),
	"Night": preload("res://assets/image/Almanac/Almanac_GroundNight.jpg"),
	"Pool": preload("res://assets/image/Almanac/Almanac_GroundPool.jpg"),
	"Fog": preload("res://assets/image/Almanac/Almanac_GroundNightPool.jpg"),
	"Roof": preload("res://assets/image/Almanac/Almanac_GroundRoof.jpg")
}

## 角色背景贴图及其展示实例的父容器，窗口大小为 200×200 像素。
@onready var character_bg: TextureRect = $CharacterBg
## 图鉴条目的中文角色名称。
@onready var character_name: Label = $AllBg/CharacterName
## 图鉴条目的基本能力描述。
@onready var character_text_1: Label = $AllBg/ScrollContainer/VBoxContainer/CharacterText1
## 展示韧性、伤害等静态参数的行容器。
@onready var character_text_2_para: VBoxContainer = $AllBg/ScrollContainer/VBoxContainer/CharacterText2Para
## 图鉴条目的可选种植或对战提示。
@onready var character_text_3_hint: Label = $AllBg/ScrollContainer/VBoxContainer/CharacterText3Hint
## 图鉴条目的角色背景介绍。
@onready var character_text_4_introduction: Label = $AllBg/ScrollContainer/VBoxContainer/CharacterText4Introduction
## 植物图鉴专用的阳光消耗行，普通僵尸和僵王不显示。
@onready var cost: HBoxContainer = $AllBg/PlantEndPara/Cost
## 植物图鉴专用的冷却时间行，普通僵尸和僵王不显示。
@onready var cool_time: HBoxContainer = $AllBg/PlantEndPara/CoolTime

## 当前角色的展示实例；切换条目时隐藏并排队释放，不参与战场注册。
var show_character: Character000Base


## [param reference] 指定图鉴角色；非法引用或缺少资料、场景时保持当前详情。[br]
## 有效条目会替换文字、背景和角色展示；只有植物显示阳光与冷却信息。
func show_card(reference: ResourceCardReference) -> void:
	if reference == null or not reference.is_valid():
		return
	# JSON 中的角色分组，由引用种类决定。
	var section: String
	# 注册表中的角色名称，也是 JSON 条目的查询键。
	var character_key: String
	# 角色原始场景，仅用于创建 IsShow 展示实例。
	var character_scene: PackedScene
	match reference.card_type:
		ResourceCardReference.CardType.Plant:
			section = "Plant"
			character_key = Global.character_registry.get_plant_info(reference.content_id, CharacterRegistry.PlantInfoAttribute.PlantName)
			character_scene = Global.character_registry.get_plant_info(reference.content_id, CharacterRegistry.PlantInfoAttribute.PlantScenes)
		ResourceCardReference.CardType.Zombie:
			section = "Zombie"
			character_key = Global.character_registry.get_zombie_info(reference.content_id, CharacterRegistry.ZombieInfoAttribute.ZombieName)
			character_scene = Global.character_registry.get_zombie_info(reference.content_id, CharacterRegistry.ZombieInfoAttribute.ZombieScenes)
		ResourceCardReference.CardType.ZombieBoss:
			section = "ZombieBoss"
			character_key = Global.character_registry.get_zombie_boss_info(reference.content_id, CharacterRegistry.ZombieBossInfoAttribute.BossName)
			character_scene = Global.character_registry.get_zombie_boss_info(reference.content_id, CharacterRegistry.ZombieBossInfoAttribute.BossScenes)
		_:
			return
	# 当前角色的图鉴资料；未编写条目时不创建角色。
	var almanac_entry: Dictionary = Global.global_read_data.data_almanac.get(section, {}).get(character_key, {})
	if almanac_entry.is_empty() or character_scene == null:
		return
	_update_character_data(almanac_entry)
	cost.visible = reference.card_type == ResourceCardReference.CardType.Plant
	cool_time.visible = cost.visible
	if cost.visible:
		cost.get_node("Value").text = str(Global.character_registry.get_plant_info(reference.content_id, CharacterRegistry.PlantInfoAttribute.SunCost))
		cool_time.get_node("Value").text = "%s(秒)" % Global.character_registry.get_plant_info(reference.content_id, CharacterRegistry.PlantInfoAttribute.CoolTime)
	_create_show_character(reference, character_scene)


## [param reference] 决定展示初始化方式及图鉴专用布局；[param character_scene] 为注册场景。[br]
## 所有实例均在入树前设为 IsShow，不创建出战状态、主游戏连接或战场注册。
func _create_show_character(reference: ResourceCardReference, character_scene: PackedScene) -> void:
	# 当前创建的角色展示实例，三类角色都继承公共角色基类。
	var next_character: Character000Base = character_scene.instantiate()
	match reference.card_type:
		ResourceCardReference.CardType.Plant:
			# 植物展示实例保留统一引用中的模仿者材质标记。
			var plant := next_character as Plant000Base
			plant.init_plant({
				Plant000Base.E_PInitAttr.CharacterInitType: Character000Base.E_CharacterInitType.IsShow,
				Plant000Base.E_PInitAttr.IsImitaterMaterial: reference.is_imitater
			})
		ResourceCardReference.CardType.Zombie:
			# 普通僵尸沿用自己的展示初始化接口，禁用移动与攻击。
			var zombie := next_character as Zombie000Base
			zombie.init_zombie({Zombie000Base.E_ZInitAttr.CharacterInitType: Character000Base.E_CharacterInitType.IsShow})
		ResourceCardReference.CardType.ZombieBoss:
			# 僵王没有普通僵尸的初始化字典；入树前设置类型以避开 ready_norm。
			next_character.character_init_type = Character000Base.E_CharacterInitType.IsShow
	_apply_show_layout(reference, next_character)
	if is_instance_valid(show_character):
		show_character.hide()
		show_character.queue_free()
	show_character = next_character
	character_bg.add_child(show_character)


## [param reference] 为角色身份；[param character] 为尚未入树的展示实例。[br]
## 仅调整当前图鉴实例的缩放与位置，保持原有普通角色布局，不写回角色场景或战斗数据。
func _apply_show_layout(reference: ResourceCardReference, character: Character000Base) -> void:
	match reference.card_type:
		ResourceCardReference.CardType.Plant:
			character.position = Vector2(100, 120)
			if reference.content_id == CharacterRegistry.PlantType.P048CobCannon:
				character.position = Vector2(60, 130)
		ResourceCardReference.CardType.Zombie:
			character.position = Vector2(100, 166)
			if reference.content_id == CharacterRegistry.ZombieType.Z024Gargantuar:
				character.position = Vector2(100, 200)
		ResourceCardReference.CardType.ZombieBoss:
			# 博士动画使用战场绝对部件坐标；只缩放、平移根节点以适配图鉴窗口。
			character.scale = Vector2(1, 1)
			character.position = Vector2(-590, -115)


## [param almanac_entry] 包含背景、名字、描述、参数、简介及可选提示，更新通用资料区域。
func _update_character_data(almanac_entry: Dictionary) -> void:
	character_bg.texture = CHARACTER_BG_MAP[almanac_entry["背景"]]
	character_name.text = almanac_entry["名字"]
	character_text_1.text = almanac_entry["描述"]
	# 静态参数表，按 JSON 的原始键顺序填入现有参数行。
	var parameters: Dictionary = almanac_entry["参数"]
	# 可展示参数数量，限制在场景已有行数内，避免新增资料使容器索引越界。
	var parameter_count: int = mini(parameters.size(), character_text_2_para.get_child_count())
	# 当前参数行下标，小于 parameter_count 的行显示对应键值。
	for index: int in character_text_2_para.get_child_count():
		# 当前复用的参数行，每次切换时重新设置显隐状态。
		var parameter_row: Control = character_text_2_para.get_child(index) as Control
		parameter_row.visible = index < parameter_count
		if index < parameter_count:
			# 当前参数名称及其说明，显示文本保持图鉴资料原样。
			var parameter_key: String = parameters.keys()[index]
			parameter_row.get_node("Key").text = parameter_key
			parameter_row.get_node("Value").text = parameters[parameter_key]
	character_text_3_hint.visible = almanac_entry.has("提示")
	if character_text_3_hint.visible:
		character_text_3_hint.text = almanac_entry["提示"]
	character_text_4_introduction.text = almanac_entry["简介"]
