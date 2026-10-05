extends Plant000Base
class_name Plant010SunShroom

@onready var create_sun_component: CreateSunComponent = $CreateSunComponent
@onready var grow_timer: SpeedTimer = $GrowTimer

## 成长所需时间
@export var time_grow:float = 100
## 小阳光价值
@export var mini_sun_value := 15
## 正常阳光价值
@export var norm_sun_value := 25

@export_group("动画状态")
## 成长
@export var is_grow:=false

func ready_norm():
	super()
	# 成长与产阳光各自保留基础周期，共同响应角色速度信号。
	update_grow_speed(GlobalUtils.get_dic_product(influence_speed_factors))
	grow_timer.start_scaled(time_grow)
	create_sun_component.change_sun_value(mini_sun_value)

	if is_zombie_mode:
		create_sun_component.disable_component(ComponentNormBase.E_IsEnableFactor.GameMode)


func ready_norm_signal_connect():
	super()
	## 角色速度改变
	signal_update_speed.connect(update_grow_speed)
	signal_update_speed.connect(create_sun_component.owner_update_speed)

## 成长结束
func _on_grow_timer_timeout() -> void:
	self.is_grow = true
	create_sun_component.change_sun_value(norm_sun_value)

## 已停止或尚未开始成长时也保存倍率，进度与零速由计时器处理。
func update_grow_speed(speed_factor:float):
	grow_timer.set_speed_scale(speed_factor)


## 被僵尸啃食一次特殊效果,魅惑\大蒜\我是僵尸生产阳光
func _be_zombie_eat_once_special(_attack_zombie:Zombie000Base):
	if is_zombie_mode:
		create_sun_component._on_be_eat_once()

## 植物死亡
func character_death():
	if is_zombie_mode:
		create_sun_component._on_character_death()
	super()

## 获取植物存档数据
func gat_save_game_data_plant()->Dictionary:
	var save_game_data_plant:Dictionary = super()
	save_game_data_plant["is_grow"] = is_grow

	return save_game_data_plant

## 读档植物数据
func load_game_data_plant(save_game_data_plant:Dictionary):
	super(save_game_data_plant)
	is_grow = save_game_data_plant.get("is_grow", false)
	if is_grow:
		grow_timer.stop()
		create_sun_component.change_sun_value(norm_sun_value)
