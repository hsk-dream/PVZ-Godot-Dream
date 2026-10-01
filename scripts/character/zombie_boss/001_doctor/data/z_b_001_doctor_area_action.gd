## 区域攻击的静态动作配置；运行时目标与格子引用保存在技能实例中。
extends Resource
class_name ZB001DoctorAreaAction

## 对应的非循环机甲动画。
@export var animation_name: StringName
## 该动作对应的部件绝对局部位置；脚踩动画 1、2 应用于 InnerLeg，3、4 应用于 OuterLeg，不叠加上次偏移。
@export var part_position: Vector2 = Vector2.ZERO
## 动画基准左上角，x 为行、y 为列，均从 1 开始。
@export var top_left: Vector2i = Vector2i(1, 1)
## 覆盖的行数和列数，必须均为正数。
@export var size: Vector2i = Vector2i(2, 3)
