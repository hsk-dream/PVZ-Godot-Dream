## 备选卡的占位背景，卡片移走后保留相同内容与费用预览。
extends Control
class_name CardCandidateContainer

## 与本容器关联的可选卡实例；选择时可移到出战卡槽。
var card: Card
## 与真实卡片保持一致的占位背景。
@onready var card_bg: TextureRect = $CardBg
## 显示真实卡片当前费用的占位标签。
@onready var cost: Label = $CardBg/Cost

## 子卡已完成初始化，复制其当前费用与静态缩略图到占位背景。
func _ready() -> void:
	cost.text = str(card.sun_cost)
	card_bg.texture = card.card_bg.texture
	# 占位预览与卡片互不共享节点，移动卡片不会带走背景。
	var static_preview: Node2D = AllCards.create_static_preview(card.card_reference)
	if static_preview != null:
		card_bg.add_child(static_preview)

## 入树前绑定 [param curr_card] 并设置返回位置，然后挂载子卡；占位不拥有卡牌身份。
func init_card_in_seed_chooser(curr_card: Card) -> void:
	card = curr_card
	curr_card.card_candidate_container = self
	add_child(curr_card)
