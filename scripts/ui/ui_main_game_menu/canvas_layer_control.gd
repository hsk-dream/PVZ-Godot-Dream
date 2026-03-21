extends CanvasLayer
class_name CanvasLayerConsole


@onready var check_box: CheckBox = $OptionBG/HBoxContainer/VBoxContainer/CheckBox
@onready var check_box_2: CheckBox = $OptionBG/HBoxContainer/VBoxContainer/CheckBox2
@onready var check_box_3: CheckBox = $OptionBG/HBoxContainer/VBoxContainer/CheckBox3
@onready var check_box_4: CheckBox = $OptionBG/HBoxContainer/VBoxContainer/CheckBox4
@onready var check_box_5: CheckBox = $OptionBG/HBoxContainer/VBoxContainer/CheckBox5
@onready var check_box_6: CheckBox = $OptionBG/HBoxContainer/VBoxContainer/CheckBox6
@onready var check_box_7: CheckBox = $OptionBG/HBoxContainer/VBoxContainer/CheckBox7
@onready var check_box_8: CheckBox = $OptionBG/HBoxContainer/VBoxContainer/CheckBox8
@onready var check_box_9: CheckBox = $OptionBG/HBoxContainer/VBoxContainer2/CheckBox9
@onready var check_box_10: CheckBox = $OptionBG/HBoxContainer/VBoxContainer2/CheckBox10


func _ready() -> void:
	init_console_panel()
	EventBus.subscribe("on_config_update", on_config_update)


## 初始化控制台
func init_console_panel():
	_update_console_panel()

func on_config_update():
	_update_console_panel()

func _update_console_panel():
	check_box.button_pressed = Global.config_service.auto_collect_sun
	check_box_2.button_pressed = Global.config_service.auto_collect_coin
	check_box_3.button_pressed = Global.config_service.disappear_spare_card_Placeholder
	check_box_4.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	check_box_5.button_pressed = Global.config_service.display_plant_HP_label
	check_box_6.button_pressed = Global.config_service.display_zombie_HP_label
	check_box_7.button_pressed = Global.config_service.card_slot_top_mouse_focus
	check_box_8.button_pressed = Global.config_service.fog_is_static
	check_box_9.button_pressed = Global.config_service.plant_be_shovel_front
	check_box_10.button_pressed = Global.config_service.open_all_level


## 关闭控制台
func _on_texture_button_pressed() -> void:
	visible = false
	EventBus.push_event("change_is_mouse_visibel_on_hammer", false)
	Global.config_service.save_config()

func appear_canvas_layer_control() -> void:
	visible = true
	EventBus.push_event("change_is_mouse_visibel_on_hammer", true)

## 自动收集阳光
func _on_check_box_toggled(toggled_on: bool) -> void:
	Global.config_service.auto_collect_sun = toggled_on

## 自动收集金币
func _on_check_box_2_toggled(toggled_on: bool) -> void:
	Global.config_service.auto_collect_coin = toggled_on

## 隐藏多余卡槽
func _on_check_box_3_toggled(toggled_on: bool) -> void:
	Global.config_service.disappear_spare_card_Placeholder = toggled_on

## 游戏全屏
func _on_check_box_4_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_check_box_5_toggled(toggled_on: bool) -> void:
	Global.config_service.display_plant_HP_label = toggled_on

func _on_check_box_6_toggled(toggled_on: bool) -> void:
	Global.config_service.display_zombie_HP_label = toggled_on

func _on_check_box_7_toggled(toggled_on: bool) -> void:
	Global.config_service.card_slot_top_mouse_focus = toggled_on

func _on_check_box_8_toggled(toggled_on: bool) -> void:
	Global.config_service.fog_is_static = toggled_on

func _on_check_box_9_toggled(toggled_on: bool) -> void:
	Global.config_service.plant_be_shovel_front = toggled_on

func _on_check_box_10_toggled(toggled_on: bool) -> void:
	Global.config_service.open_all_level = toggled_on
