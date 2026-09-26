extends ComponentNormBase
class_name CreateCoinComponent

@onready var create_coin_timer: SpeedTimer = $CreateCoinTimer

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
## 金币生产间隔，始终保存正常速度下的动作时间。
var create_interval :float

func _ready() -> void:
	# 先保存基础周期与角色倍率，停止期间的倍率更新也能应用于下次启用。
	create_interval = randf_range(create_time_range_first.x, create_time_range_first.y)
	create_coin_timer.base_wait_time = create_interval
	owner_update_speed(GlobalUtils.get_dic_product(owner.influence_speed_factors))
	if not get_tree().current_scene is MainGameManager:
		return
	create_coin_timer.start_scaled()


func _on_create_coin_timer_timeout() -> void:
	drop_coin()
	change_production_interval()

## 生产后、改变生产时间，重新启动计时器
func change_production_interval():
	create_interval = randf_range(create_time_range_other.x, create_time_range_other.y)
	create_coin_timer.start_scaled(create_interval)

## 掉落金银钻
func drop_coin():
	Global.create_coin()
	EventBus.push_event("create_coin", [
			drop_coin_silver_glod_diamond_rate, marker_2d_create_coin.global_position
		])

## 启用组件
func enable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)
	# 其他禁用因素尚未解除时，不能因一次 enable 调用重新启动生产。
	if is_enabling:
		create_coin_timer.start_scaled()

## 禁用组件
func disable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)
	if not is_enabling:
		create_coin_timer.stop()

## 仅传递倍率，进度换算和零速暂停统一交给计时器。
func owner_update_speed(speed_product:float):
	create_coin_timer.set_speed_scale(speed_product)
