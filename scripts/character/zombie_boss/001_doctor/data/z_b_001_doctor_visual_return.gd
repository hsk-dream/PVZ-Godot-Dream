## 死亡打断时的局部位置恢复快照，由技能提供，由动画控制器消费。
extends RefCounted
class_name ZB001DoctorVisualReturn

## 待恢复节点的实例 ID，节点提前释放时控制器跳过该项。
var node_id: int
## 技能被打断瞬间的局部位置。
var start_position: Vector2
## 技能定义的复位位置，不由死亡状态猜测。
var target_position: Vector2

## [param node] 被技能移动的节点；[param target] 清理后应恢复的局部位置。
func _init(node: Node2D, target: Vector2) -> void:
	node_id = node.get_instance_id()
	start_position = node.position
	target_position = target
