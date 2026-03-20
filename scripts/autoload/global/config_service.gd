extends Node
class_name ConfigService

## 配置服务：只负责 config.ini 的读写、保存当前设置、并对外提供配置值
## 运行态逻辑请直接通过 Global.config_service/<var> 与 <signal> 获取

signal signal_change_disappear_spare_card_placeholder
signal signal_change_display_plant_HP_label(value: bool)
signal signal_change_display_zombie_HP_label(value: bool)
signal signal_change_card_slot_top_mouse_focus
signal signal_fog_is_static

@onready var user_manager: UserManager = %UserManager

const CURRENT_CONFIG_FILE := "config.ini"

## 用户选项（持久化字段）
var auto_collect_sun := false
var auto_collect_coin := false

var disappear_spare_card_Placeholder := false:
	set(value):
		if disappear_spare_card_Placeholder == value:
			return
		disappear_spare_card_Placeholder = value
		signal_change_disappear_spare_card_placeholder.emit()

var display_plant_HP_label := false:
	set(value):
		if display_plant_HP_label == value:
			return
		display_plant_HP_label = value
		signal_change_display_plant_HP_label.emit(display_plant_HP_label)

var display_zombie_HP_label := false:
	set(value):
		if display_zombie_HP_label == value:
			return
		display_zombie_HP_label = value
		signal_change_display_zombie_HP_label.emit(display_zombie_HP_label)

var card_slot_top_mouse_focus := false:
	set(value):
		if card_slot_top_mouse_focus == value:
			return
		card_slot_top_mouse_focus = value
		signal_change_card_slot_top_mouse_focus.emit()

var fog_is_static := false:
	set(value):
		if fog_is_static == value:
			return
		fog_is_static = value
		signal_fog_is_static.emit()

var plant_be_shovel_front := true
var open_all_level := false

func _get_config_path() -> String:
	if user_manager == null or user_manager.curr_user_name.is_empty():
		return ""
	return "user://" + user_manager.curr_user_name + "/" + CURRENT_CONFIG_FILE

func load_and_apply_config() -> void:
	var path := _get_config_path()
	if path.is_empty():
		return

	var config := ConfigFile.new()
	# config 不存在时 load 的返回值可能非 OK，此时仍使用默认值应用（不报错可提升兼容性）
	config.load(path)

	# 音量设置
	SoundManager.set_volume(SoundManager.Bus.MASTER, config.get_value("audio", "master", 1.0))
	SoundManager.set_volume(SoundManager.Bus.BGM, config.get_value("audio", "bgm", 0.5))
	SoundManager.set_volume(SoundManager.Bus.SFX, config.get_value("audio", "sfx", 0.5))

	# 用户选项控制台
	auto_collect_sun = config.get_value("user_control", "auto_collect_sun", false)
	auto_collect_coin = config.get_value("user_control", "auto_collect_coin", false)
	disappear_spare_card_Placeholder = config.get_value("user_control", "disappear_spare_card_Placeholder", false)
	display_plant_HP_label = config.get_value("user_control", "display_plant_HP_label", false)
	display_zombie_HP_label = config.get_value("user_control", "display_zombie_HP_label", false)
	card_slot_top_mouse_focus = config.get_value("user_control", "card_slot_top_mouse_focus", false)
	fog_is_static = config.get_value("user_control", "fog_is_static", false)
	plant_be_shovel_front = config.get_value("user_control", "plant_be_shovel_front", true)
	open_all_level = config.get_value("user_control", "open_all_level", false)

func save_config() -> void:
	var path := _get_config_path()
	if path.is_empty():
		return

	var config := ConfigFile.new()

	# 音乐相关
	config.set_value("audio", "master", SoundManager.get_volum(SoundManager.Bus.MASTER))
	config.set_value("audio", "bgm", SoundManager.get_volum(SoundManager.Bus.BGM))
	config.set_value("audio", "sfx", SoundManager.get_volum(SoundManager.Bus.SFX))

	# 用户选项控制台相关
	config.set_value("user_control", "auto_collect_sun", auto_collect_sun)
	config.set_value("user_control", "auto_collect_coin", auto_collect_coin)
	config.set_value("user_control", "disappear_spare_card_Placeholder", disappear_spare_card_Placeholder)
	config.set_value("user_control", "display_plant_HP_label", display_plant_HP_label)
	config.set_value("user_control", "display_zombie_HP_label", display_zombie_HP_label)
	config.set_value("user_control", "card_slot_top_mouse_focus", card_slot_top_mouse_focus)
	config.set_value("user_control", "fog_is_static", fog_is_static)
	config.set_value("user_control", "plant_be_shovel_front", plant_be_shovel_front)
	config.set_value("user_control", "open_all_level", open_all_level)

	config.save(path)
