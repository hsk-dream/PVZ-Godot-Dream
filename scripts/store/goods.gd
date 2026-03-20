extends Control
class_name Goods
## 商品
@export_group("商品属性")
## 商品价格
@export var price :int = 0
## 是否还有该商品
@export var is_have_goods:bool = true
@onready var is_not_have_goods_label: Label = $VBoxContainer/PanelContainer/IsNotHaveGoodsLabel

## 价格标签
@onready var price_tag_label: Label = $VBoxContainer/PriceTag/Label
@onready var button: Button = $VBoxContainer/PanelContainer/Button

@export_group("戴夫交流相关")
## 该商品的戴夫对话细节描述
@export var dialog_detail:CrazyDaveDialogDetailResource
var curr_dialog_detail:CrazyDaveDialogDetailResource
var original_dialog_text :String

## 查看商品信号
signal look_goods_signal
## 取消查看商品信号
signal look_end_goods_signal
## 点击当前商品信号
signal signal_pressed_this_goods

func _ready() -> void:
	price_tag_label.text = "$" + GlobalUtils.format_number_with_commas(price)
	is_not_have_goods_label.visible = not is_have_goods
	curr_dialog_detail = dialog_detail.duplicate(true)
	judge_can_get_goods()
	## 连接金币改变信号
	Global.global_game_state.coin_value_changed.connect(func(_new_value: int): judge_can_get_goods())

## 判断是否卖的起,是否有商品
func judge_can_get_goods():
	## 如果当前金币买不起
	if Global.global_game_state.coin_value < price:
		curr_dialog_detail.text = "**你现在还卖不起这个商品**\n" + dialog_detail.text
		button.disabled = true
	else:
		curr_dialog_detail.text = dialog_detail.text
		button.disabled = false

	## 如果没有该商品
	if not is_have_goods:
		button.disabled = true

## 鼠标进入
func _on_mouse_entered() -> void:
	look_goods_signal.emit(curr_dialog_detail)

## 鼠标移出
func _on_mouse_exited() -> void:
	look_end_goods_signal.emit()

## 点击商品
func _on_button_pressed() -> void:
	## 连接时将自身绑定了
	signal_pressed_this_goods.emit()

## 确认购买该商品
func comfirm_get_this_goods():
	if Global.global_game_state.coin_value < price:
		print("买不起，不应该出现该语句，因为按钮已经被禁用")
		return
	else:
		Global.global_game_state.coin_value -= price
		get_one_goods()

## 获得该商品的作用，子类重写
func get_one_goods():
	pass
