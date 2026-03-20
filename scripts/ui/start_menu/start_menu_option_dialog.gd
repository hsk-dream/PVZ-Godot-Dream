extends TextureRect
class_name StartMenuOptionDialog


@onready var music_h_slider: HSlider = $Option/Music/HSlider
@onready var sound_h_slider: HSlider = $Option/SoundEffect/HSlider

## 全屏按钮
@onready var check_button: CheckButton = $Option/FullScreen/CheckButton


func _ready() -> void:
	## 为按钮添加音效
	SoundManager.setup_ui_main_game_sound(self)
	music_sound_signal(music_h_slider, AudioServer.get_bus_index("BGM"))
	music_sound_signal(sound_h_slider, AudioServer.get_bus_index("SFX"))

	check_button.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func music_sound_signal(h_slider: HSlider, bus_index):
	h_slider.value = SoundManager.get_volum(bus_index)
	h_slider.value_changed.connect(func (v:float):
		SoundManager.set_volume(bus_index, v)
		Global.config_service.save_config()
	)


## 出现菜单
func appear_menu():
	await get_tree().create_timer(0.1).timeout

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP


## 关闭菜单
func return_button_pressed():
	await get_tree().create_timer(0.1).timeout

	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
