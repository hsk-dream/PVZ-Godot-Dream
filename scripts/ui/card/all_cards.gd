## 卡牌源模板目录；统一按身份值注册，实例创建与静态缩略图复制都经过此入口。
extends Control
class_name AllCardsClass

## 编辑器中的源目录，顺序决定同类卡牌的展示顺序，目录名称不推导内容类别。
@onready var _source_directories: Array[GridContainer] = [
	%PlantCards, %PlantCards2, %ZombieCards, %ZombieCards2, %BossCards,
]
## 已注册源模板；键是类别和角色编号，不是 Resource 的对象身份。
var _templates: Dictionary[Vector2i, Card] = {}
## 按源目录顺序保存的引用，用于分类页和候选卡分页。
var _references: Array[ResourceCardReference] = []


## 隐藏运行时目录，并建立唯一模板索引；未配置卡牌保留为空布局节点。
func _ready() -> void:
	hide()
	# 按编辑器中的目录顺序遍历卡牌来源容器。
	for directory: GridContainer in _source_directories:
		# 每个卡牌子节点独立声明身份，不从容器类型推导。
		for child: Node in directory.get_children():
			# 源目录中的实际卡牌；非卡牌布局节点不参与注册。
			var card := child as Card
			if card == null or card.card_reference == null:
				continue
			if not card.card_reference.is_valid() or card.card_reference.is_imitater:
				push_error("AllCards：非法源卡牌引用：%s" % card.get_path())
				continue
			# 基础模板的身份值键，禁止静默覆盖重复注册。
			var key := card.card_reference.get_template_key()
			if _templates.has(key):
				push_error("AllCards：重复卡牌身份：%s" % key)
				continue
			_templates[key] = card
			_references.append(card.card_reference)


## 返回 [param reference] 的源模板；非法或未注册引用返回 null，不回退其他类别。
func get_template(reference: ResourceCardReference) -> Card:
	if reference == null or not reference.is_valid():
		return null
	return _templates.get(reference.get_template_key())


## 创建独立卡牌；[param reference] 描述内容和修饰，[param context] 指定点击用途。
## 返回尚未加入场景树的实例；身份或战斗用途非法时返回 null。
func create_card(reference: ResourceCardReference, context: Card.CardContext = Card.CardContext.Catalog) -> Card:
	# 模板只读，运行时属性与身份引用由新实例独立持有。
	var template := get_template(reference)
	if template == null:
		push_error("AllCards：无法创建未注册卡牌")
		return null
	if (context == Card.CardContext.Battle or context == Card.CardContext.Selection) and not is_battle_card(reference):
		push_error("AllCards：此卡牌不支持选卡或出战用途")
		return null
	# 入树前完成身份与用途设置，让 _ready 使用正确角色参数。
	var card := template.duplicate() as Card
	card.card_reference = reference.copy_reference()
	card.card_context = context
	return card


## 返回 [param reference] 的独立静态缩略图；不会实例化出战角色或启动战斗初始化。
func create_static_preview(reference: ResourceCardReference) -> Node2D:
	# 已注册模板持有美术制作完成的静态节点树。
	var template := get_template(reference)
	if template == null:
		push_error("AllCards：无法创建未注册卡牌的缩略图")
		return null
	# 仅复制静态图像容器，保留模板内部的位置和缩放。
	var preview := template.character_static.duplicate() as Node2D
	if reference.is_imitater:
		preview.material = Card.IMITATER.duplicate()
		# 动画等非图像节点不参与材质继承。
		for child: Node in preview.get_children():
			if child is Node2D:
				GlobalUtils.node_use_parent_material(child as Node2D)
	return preview


## 返回 [param card_type] 的有序引用列表；返回独立引用，调用方不能改写目录身份。
func get_references(card_type: int) -> Array[ResourceCardReference]:
	# 分类页的顺序来自源目录，不保存额外的卡牌位置编号。
	var result: Array[ResourceCardReference] = []
	# 当前基础引用只读使用，分类结果持有独立副本。
	for reference: ResourceCardReference in _references:
		if reference.card_type == card_type:
			result.append(reference.copy_reference())
	return result


## 返回 [param reference] 是否为已注册的可出战卡牌；模仿者选择入口只用于辅助选卡。
## 僵王具有普通卡槽出战能力，具体场景的召唤资格由僵尸管理器确认。
func is_battle_card(reference: ResourceCardReference) -> bool:
	if get_template(reference) == null:
		return false
	match reference.card_type:
		ResourceCardReference.CardType.Plant:
			return reference.content_id != CharacterRegistry.PlantType.P999Imitater
		ResourceCardReference.CardType.Zombie:
			return true
		ResourceCardReference.CardType.ZombieBoss:
			return true
	return false
