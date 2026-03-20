extends Control
class_name StoreManager

@onready var crazy_dave: CrazyDave = $CrazyDave
@export var all_goods :Array[Goods]
@onready var coin_bank_bank: CoinBankLabel = $CoinBankLabel
@onready var confirm_goods: ConfirmGoods = $ConfirmGoods

## 原始金币label
var ori_coin_value_label
## 离开商店页信号
signal siganl_exit_store

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.save_service.save_now()
	if is_instance_valid(Global.coin_value_label):
		ori_coin_value_label = Global.coin_value_label
		Global.coin_value_label = coin_bank_bank

	for goods in all_goods:
		goods.look_goods_signal.connect(crazy_dave.external_trigger_dialog)
		goods.look_end_goods_signal.connect(crazy_dave.external_trigger_dialog_end)
		## 确认购买页面
		goods.signal_pressed_this_goods.connect(confirm_goods.appear_canvas_layer.bind(goods))

## 离开商店
func _on_store_main_menu_button_pressed() -> void:
	siganl_exit_store.emit()
	Global.save_service.save_now()
	if is_instance_valid(ori_coin_value_label):
		Global.coin_value_label = ori_coin_value_label
		Global.coin_value_label.update_label()

	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(Global.main_scene_registry.MainScenesMap[EnumsMainScene.MainScenes.StartMenu])
	else:
		queue_free()

