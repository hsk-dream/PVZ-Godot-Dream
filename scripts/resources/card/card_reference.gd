## 卡牌身份与植物模仿修饰；模板和关卡中的引用按只读使用，不保存费用或运行状态。
@tool
extends Resource
class_name ResourceCardReference

## 卡牌内容类别；编号用于选卡记录，新增类别时保持已有编号不变。
enum CardType {
	Null = 0, ## 编辑器中尚未配置的引用，不参与注册。
	Plant = 1, ## 植物卡牌。
	Zombie = 2, ## 普通僵尸卡牌。
	ZombieBoss = 3, ## 僵王卡牌，当前只用于展示。
}

## 内容类别；切换类别时清空角色编号，要求重新选择该类别的角色。
@export var card_type: CardType = CardType.Null:
	set(value):
		if card_type == value:
			return
		card_type = value
		content_id = 0
		if card_type != CardType.Plant:
			is_imitater = false
		notify_property_list_changed()
## 所选类别的角色枚举编号；0 表示未配置，不能用于生成卡牌。
@export var content_id: int = 0
## 植物模仿修饰；编号仍指向被模仿植物，不另注册模板。
@export var is_imitater: bool = false


## 创建一份独立引用；[param type] 为卡牌类别，[param id] 为角色编号。
## [param imitater] 仅适用于具体植物；非法组合可由 [method is_valid] 检出。
static func create(type: int, id: int, imitater: bool = false) -> ResourceCardReference:
	# 新引用不与模板或关卡共享可写属性。
	var reference := ResourceCardReference.new()
	reference.card_type = type
	reference.content_id = id
	reference.is_imitater = imitater
	return reference


## 返回独立身份副本；显式构造确保类别先于角色编号赋值，不依赖 Resource 属性复制顺序。
func copy_reference() -> ResourceCardReference:
	return create(card_type, content_id, is_imitater)


## 返回是否为已定义的非空角色，模仿修饰不能用于其他类别或模仿者选择入口。
func is_valid() -> bool:
	if content_id <= 0:
		return false
	if is_imitater and (card_type != CardType.Plant or content_id == CharacterRegistry.PlantType.P999Imitater):
		return false
	match card_type:
		CardType.Plant:
			return CharacterRegistry.PlantType.values().has(content_id)
		CardType.Zombie:
			return CharacterRegistry.ZombieType.values().has(content_id)
		CardType.ZombieBoss:
			return CharacterRegistry.ZombieBossType.values().has(content_id)
	return false


## 返回模板身份的值键；普通卡和模仿卡共用目标植物模板。
func get_template_key() -> Vector2i:
	return Vector2i(card_type, content_id)


## 返回包含模仿修饰的选卡值键，用于区分同一植物的两张备选卡。
func get_selection_key() -> Vector3i:
	return Vector3i(card_type, content_id, int(is_imitater))


## 返回可直接写入 JSON 的选卡数据，不将 Resource 对象交给 JSON 编码器。
func to_dict() -> Dictionary:
	return {"card_type": card_type, "content_id": content_id, "is_imitater": is_imitater}


## 从当前格式还原引用；[param data] 必须包含三个字段，旧格式或非法值返回 null。
static func from_dict(data: Dictionary) -> ResourceCardReference:
	# 逐个检查类别和角色编号字段；JSON 数字只接受有限整数，避免截断错误编号。
	for field: String in ["card_type", "content_id"]:
		# 当前字段的原始 JSON 值。
		var value: Variant = data.get(field)
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			return null
		if typeof(value) == TYPE_FLOAT and (not is_finite(value) or value != floor(value)):
			return null
	if typeof(data.get("is_imitater")) != TYPE_BOOL:
		return null
	# 已通过字段类型检查的新引用。
	var reference := create(int(data["card_type"]), int(data["content_id"]), data["is_imitater"])
	return reference if reference.is_valid() else null


## 为 [param property] 中的角色编号提供当前类别的枚举选项；不依赖运行中的 Global。
func _validate_property(property: Dictionary) -> void:
	if property.name != "content_id":
		return
	# 当前类别的角色枚举，包含空编号以便编辑未完成的配置。
	var content_types: Dictionary = {}
	match card_type:
		CardType.Plant:
			content_types = CharacterRegistry.PlantType
		CardType.Zombie:
			content_types = CharacterRegistry.ZombieType
		CardType.ZombieBoss:
			content_types = CharacterRegistry.ZombieBossType
	# 带显式数值的枚举文本，支持 999、1001 等非连续编号。
	var options := PackedStringArray()
	# 当前类别的角色名称用作选项标签，实际保存对应数字编号。
	for content_name: String in content_types:
		options.append("%s:%s" % [content_name, content_types[content_name]])
	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = ",".join(options)
