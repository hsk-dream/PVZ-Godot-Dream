extends AnimComponentBase
class_name AnimComponentNorm
## 普通动画组件,使用AnimationTree的角色使用

## 同级 AnimationTree 引用，用于读取初始动画速度并更新混合树的速度参数。
@onready var animation_tree: AnimationTree = $"../AnimationTree"

func _ready() -> void:
	animation_origin_speed = animation_tree.get("parameters/TimeScale/scale")
	animation_tree.animation_finished.connect(_on_animation_finished)

## 更新动画速度
## [param speed_factor_product] 角色各速度因素的乘积，乘以初始动画速度后得到实际播放速度。
func owner_update_speed(speed_factor_product:float):
	animation_tree.set("parameters/TimeScale/scale", animation_origin_speed * speed_factor_product)

## 更新动画速度(动画播放速度)
## [param speed_scale] 直接应用到动画系统的播放速度倍率，0 表示停止推进动画。
func update_anim_speed_scale(speed_scale:float):
	animation_tree.set("parameters/TimeScale/scale", speed_scale)

## 停止动画
func stop_anim():
	animation_tree.active = false
