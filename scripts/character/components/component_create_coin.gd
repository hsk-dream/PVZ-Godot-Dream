extends ComponentNormBase
class_name CreateCoinComponent

@onready var create_coin_timer: Timer = $CreateCoinTimer

@export_group("掉落相关")
## 掉落银币、金币、钻石的比例（要求和为1）
@export var drop_coin_silver_glod_diamond_rate := [0.5,0.4,0.1]
## 生产位置
@export var marker_2d_create_coin: Marker2D

@export_group("生产间隔时间")
## 第一个生产时间范围
@export var create_time_range_first:Vector2 = Vector2(3, 12.5)
## 后续生产的时间范围
@export var create_time_range_other:Vector2 = Vector2(23.5,25)
## 阳光生产速度
var create_speed := 1.0
## 阳光生产间隔
var create_interval :float

func _ready() -> void:
	#if get_tree().current_scene != MainGameManager:
	if not get_tree().current_scene is MainGameManager:
		return
	create_interval = randf_range(create_time_range_first.x, create_time_range_first.y)
	create_coin_timer.start(create_interval)


func _on_create_coin_timer_timeout() -> void:
	drop_coin()
	change_production_interval()

## 生产后、改变生产时间，重新启动计时器
func change_production_interval():
	create_interval = randf_range(create_time_range_other.x / create_speed, create_time_range_other.y / create_speed)
	create_coin_timer.start(create_interval)

## 掉落金银钻
func drop_coin():
	Global.create_coin()
	EventBus.push_event("create_coin", [
			drop_coin_silver_glod_diamond_rate, marker_2d_create_coin.global_position
		])

## 启用组件
func enable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)
	create_coin_timer.start(create_coin_timer.wait_time / create_speed)

## 禁用组件
func disable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)
	create_coin_timer.stop()

func owner_update_speed(speed_product:float):
	if is_enabling:
		if not create_coin_timer.is_stopped():
			if speed_product == 0:
				create_coin_timer.paused = true
			else:
				create_coin_timer.paused = false

				create_coin_timer.start(create_coin_timer.time_left / speed_product)

	create_speed = speed_product

