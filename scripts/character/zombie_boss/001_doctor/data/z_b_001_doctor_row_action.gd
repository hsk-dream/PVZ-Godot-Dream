## 场景中的一行动作配置；字典键使用从 1 开始的行号，动画可以在多行之间复用。
extends Resource
class_name ZB001DoctorRowAction

## 该行播放的非循环动画，释放事件继续由动画自身的方法轨道提供。
@export var animation_name: StringName
## 技能部件父节点的绝对局部位置，单位为像素；不是叠加到上次动作的偏移。
@export var part_position: Vector2 = Vector2.ZERO
