@abstract
extends Node2D
class_name AnimComponentBase
## 动画组件基类
## 由于部分僵尸可能没有AnimationTree或者AnimationPlayer
## 使用该组件统一进行一些动画速度的控制
## 子类实现具体方法

## 动画结束信号
signal signal_animation_finished(anim_name:StringName)

## 角色动画的初始播放速度；-1 表示尚未初始化，供后续倍率计算使用。
var animation_origin_speed :float = -1


## 获取动画原始速度
func get_animation_origin_speed():
	if animation_origin_speed == -1:
		push_error("动画速度为-1")
	return animation_origin_speed

## 设置初始化速度(伴舞使用)
## [param value] 记录为动画初始速度的数值，后续用于角色倍率换算。
func set_animation_origin_speed(value:float):
	animation_origin_speed = value

## 更新动画速度(根据速度倍率)
@abstract
## [param speed_factor_product] 角色各速度因素的乘积，乘以初始动画速度后得到实际播放速度。
func owner_update_speed(speed_factor_product:float)

## 更新动画速度(动画播放速度)
@abstract
## [param speed_scale] 直接应用到动画系统的播放速度倍率，0 表示停止推进动画。
func update_anim_speed_scale(speed_scale:float)

## 停止动画
func stop_anim():
	pass

## 动画结束时发射信号
## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func _on_animation_finished(anim_name:StringName):
	signal_animation_finished.emit(anim_name)
	#print("当前动画结束")

