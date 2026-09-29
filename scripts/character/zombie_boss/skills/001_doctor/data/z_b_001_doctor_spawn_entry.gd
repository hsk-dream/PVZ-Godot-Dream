## 放置批次中的一只僵尸；由技能持有，不保存临时候选或动画下标。
extends RefCounted
class_name ZB001DoctorSpawnEntry

## 已解析雪橇替换后的实际生成类型。
var zombie_type: CharacterRegistry.ZombieType
## 零起始目标行，同时决定生成 Y 和放置动画。
var lane: int

## [param type] 实际僵尸类型；[param target_lane] 零起始目标行。
func _init(type: CharacterRegistry.ZombieType, target_lane: int) -> void:
	zombie_type = type
	lane = target_lane
