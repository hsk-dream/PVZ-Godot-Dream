extends ZB001DoctorSkillState
class_name ZB001DoctorStateSpawn
## 一轮技能放置若干只僵尸，两次放置之间播放待机动画；总数只在父技能进入时取样。
## 单轮最少执行次数；每段放置动画的释放关键帧最多创建一只僵尸。
@export_range(1, 20, 1) var spawn_count_min: int = 4
## 单轮最大次数必须不小于最小次数；初始化时拒绝错误配置，不自动交换上下限。
@export_range(1, 20, 1) var spawn_count_max: int = 6
## 两次放置之间的等待时间，单位为正常动作速度下的秒；首轮前与最后一轮后不等待。
@export_range(0.1, 60.0, 0.1) var spawn_interval_duration: float = 1.0
## 与 action_animations 下标一一对应的目标行号，从 0 开始；当前场景不存在的行不参与选择。
@export var animation_lanes: Array[int] = [0, 1, 2, 3, 4]

## 计划次数与已完成动画次数描述动作流程，实际僵尸数量只由管理器登记。
## 本轮计划播放的放置次数，仅在进入父技能时随机一次，退出时清零。
var planned_count := 0
## 本轮已完整结束的放置动画次数，用于决定继续准备下一只还是收尾。
var completed_count := 0

func enter() -> void:
	planned_count = randi_range(spawn_count_min, spawn_count_max)
	completed_count = 0
	super.enter()

## 每次先准备行号与类型，再选择对应动画；空结果表示本轮已无可放置目标。
func prepare_action() -> void:
	selected_animation = &""
	action_parameters.clear()
	# 已在配置检查中确认类型的放置效果组件，负责筛选可用行与随机僵尸类型。
	var spawn_effect: ZB001DoctorSkillSpawn = effect_component as ZB001DoctorSkillSpawn
	action_parameters = spawn_effect.prepare_parameters(animation_lanes)
	if action_parameters.is_empty():
		return
	# 准备阶段锁定的行号，释放关键帧与动画选择共用同一份数据。
	var lane: int = action_parameters["lane"]
	# 行号对应的动画数组下标，不假定动画名称末尾编号就是场景行号。
	var animation_index: int = animation_lanes.find(lane)
	if animation_index < 0 or animation_index >= action_animations.size():
		action_parameters.clear()
		return
	selected_animation = action_animations[animation_index]
	action_parameters["animation_variant"] = animation_index + 1
	action_parameters["spawn_index"] = completed_count + 1
	action_parameters["spawn_total"] = planned_count

func exit() -> void:
	super.exit()
	planned_count = 0
	completed_count = 0

## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	# 父类技能配置检查的结果；非空时直接返回，不继续验证放置专属参数。
	var error := super.get_configuration_error()
	if not error.is_empty():
		return error
	if spawn_count_min < 1 or spawn_count_max < spawn_count_min:
		detected_error = "放置次数必须满足 1 <= spawn_count_min <= spawn_count_max。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_finite(spawn_interval_duration) or spawn_interval_duration <= 0.0:
		detected_error = "放置间隔必须为有限正数。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not child_state_machine.initial_state is ZB001DoctorStateSpawnPrepare:
		detected_error = "放置技能入口必须使用专用 SpawnPrepare，处理无可用目标的情况。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not effect_component is ZB001DoctorSkillSpawn:
		detected_error = "放置技能必须绑定 SpawnSkill 效果组件。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if animation_lanes.size() != action_animations.size():
		detected_error = "放置动画与目标行数组必须一一对应。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 已配置行号的集合，用于拒绝同一行配置多段动画导致的选择歧义。
	var seen_lanes: Array[int] = []
	# 当前配置的零起始行号；场景不具有该行时由效果组件在准备阶段排除。
	for lane: int in animation_lanes:
		if lane < 0 or seen_lanes.has(lane):
			detected_error = "放置动画对应的行号必须非负且不能重复。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		seen_lanes.append(lane)
	return (effect_component as ZB001DoctorSkillSpawn).get_configuration_error()
