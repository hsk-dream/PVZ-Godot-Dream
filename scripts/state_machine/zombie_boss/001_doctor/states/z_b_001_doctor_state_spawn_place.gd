extends ZB001DoctorStateSkillAction
class_name ZB001DoctorStateSpawnPlace
## 单次放置复用关键帧释放与去重；只在完整动画结束后增加本轮完成次数。

## 尚有放置次数时进入的同层间隔状态；最后一次完成后仍进入 next_state 收尾。
@export var interval_state: ZB001DoctorStateSpawnInterval

## 动画完整结束后累计次数；只有需要继续放置时才插入等待。
func get_next_state() -> CharacterState:
	# 所属放置技能的类型化引用，用于累计已完成次数并读取本轮目标次数。
	var spawn := skill_state as ZB001DoctorStateSpawn
	spawn.completed_count += 1
	if spawn.completed_count < spawn.planned_count:
		return interval_state
	return next_state

## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not skill_state is ZB001DoctorStateSpawn:
		detected_error = "Place 必须属于放置僵尸技能。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(interval_state) or interval_state.get_parent() != state_machine:
		detected_error = "Place 必须绑定同层的 Interval 间隔状态。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return super.get_configuration_error()
