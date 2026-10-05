## 图鉴中的角色头像卡片；普通僵尸和僵王都通过统一引用取得静态预览。
extends Control
class_name AlmanacPortraitCard

## 裁切静态角色预览的头像背景容器。
@onready var portrait_bg: TextureRect = $PortraitBg

## 当前头像对应的角色引用；必须在加入场景树前初始化。
var card_reference: ResourceCardReference

## 点击头像后传递角色引用，详情面板据此查询资料并创建展示实例。
signal signal_card_click(reference: ResourceCardReference)


## 从目录工厂复制静态预览，并仅调整图鉴头像的展示大小与位置。
func _ready() -> void:
	# 工厂返回的独立静态预览；模板缺失时不向容器添加节点。
	var character_static: Node2D = AllCards.create_static_preview(card_reference)
	if character_static == null:
		return
	portrait_bg.add_child(character_static)
	if card_reference.card_type == ResourceCardReference.CardType.ZombieBoss:
		# 僵王模板包含完整机甲，以较小比例放进头像窗口，不修改模板本身。
		character_static.scale = Vector2(1, 1)
		character_static.position = Vector2(35, 45)
	else:
		character_static.scale = Vector2(1.6, 1.6)
		character_static.position = Vector2(40, 50)


## [param reference] 为头像条目的独立身份，需在本卡片加入场景树之前传入。
func init_almanac_portrait_card(reference: ResourceCardReference) -> void:
	card_reference = reference


## 将当前角色引用发送给详情面板；未初始化引用的头像不响应点击。
func _on_button_pressed() -> void:
	if card_reference != null:
		signal_card_click.emit(card_reference)
