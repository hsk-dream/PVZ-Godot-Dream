extends AnimComponentBase
class_name AnimComponentPlayer
## 只使用AnimationPlayer和自定义状态机处理动画

## 同级主体 AnimationPlayer，负责播放动画并应用角色速度倍率。
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

func _ready() -> void:
	animation_origin_speed = animation_player.speed_scale
	animation_player.animation_finished.connect(_on_animation_finished)

## 更新动画速度
## [param speed_factor_product] 角色各速度因素的乘积，乘以初始动画速度后得到实际播放速度。
func owner_update_speed(speed_factor_product:float):
	animation_player.speed_scale = animation_origin_speed * speed_factor_product

## 更新动画速度(动画播放速度)
## [param speed_scale] 直接应用到动画系统的播放速度倍率，0 表示停止推进动画。
func update_anim_speed_scale(speed_scale:float):
	animation_player.speed_scale = speed_scale

## 停止动画
func stop_anim():
	animation_player.pause()
