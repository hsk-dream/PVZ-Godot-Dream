## 蹦极单列目标快照；固定手指槽位，空列不会压缩后续槽位。
extends RefCounted
class_name ZB001DoctorBungeeTarget

## 格子的实例 ID；释放时重新解析，避免保存已被释放的强类型节点引用。
var cell_id: int
## 手部连接点下标：0 左、1 中、2 右。
var anchor_index: int

## [param cell] 本列锁定格子；[param slot] 原始手指槽位。
func _init(cell: PlantCell, slot: int) -> void:
	cell_id = cell.get_instance_id()
	anchor_index = slot
