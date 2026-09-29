## 区域攻击的静态动作配置；运行时目标与格子引用保存在技能实例中。
extends Resource
class_name ZB001DoctorAreaAction

## 对应的非循环机甲动画。
@export var animation_name: StringName
## 动画基准左上角，x 为行、y 为列，均从 1 开始。
@export var top_left: Vector2i = Vector2i(1, 1)
## 覆盖的行数和列数，必须均为正数。
@export var size: Vector2i = Vector2i(2, 3)
