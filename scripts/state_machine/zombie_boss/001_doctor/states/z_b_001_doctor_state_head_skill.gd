extends ZB001DoctorSkillState
class_name ZB001DoctorStateHeadSkill
## 一次技能依次准备、低头、吐球前待机、吐一个球、吐球后待机、抬头。
## 低头动作子状态；Prepare 完成后进入，第 2 秒的动画关键帧开启受击。
@export var head_enter_state: ZB001DoctorStateHeadEnter
## 吐球前的低头待机，具有独立的等待时长与计时器。
@export var before_spit_idle_state: ZB001DoctorStateHeadIdle
## 单次吐球子状态；继承受击窗口，并在释放关键帧调用一次技能效果。
@export var head_attack_state: ZB001DoctorStateHeadAttack
## 吐球后的低头待机，等待完成后才开始抬头收尾。
@export var after_spit_idle_state: ZB001DoctorStateHeadIdle
## 抬头收尾子状态；第 0.6667 秒关闭受击，动画结束后完成整轮技能。
@export var head_leave_state: ZB001DoctorStateHeadLeave
## 与 action_animations 下标一一对应的场景行号，从 0 开始；不存在的行不参与选取。
@export var animation_lanes: Array[int] = [0, 1, 2, 3, 4]

## 先确定目标行和冰火类型，再查找对应动画；整个低头动作沿用同一份参数。
func prepare_action() -> void:
	selected_animation = &""
	action_parameters.clear()
	# 已通过配置检查的吐球效果组件，负责选择场景中的有效行。
	var ball_skill: ZB001DoctorSkillIceFireBall = effect_component as ZB001DoctorSkillIceFireBall
	action_parameters = ball_skill.prepare_parameters(animation_lanes)
	if action_parameters.is_empty():
		return
	# 准备结果锁定的行号，与释放时使用的目标行保持一致。
	var lane: int = action_parameters["lane"]
	# 当前行在动画映射中的下标，独立于动画名称末尾的数字。
	var animation_index: int = animation_lanes.find(lane)
	if animation_index < 0 or animation_index >= action_animations.size():
		action_parameters.clear()
		return
	selected_animation = action_animations[animation_index]
	action_parameters["animation_variant"] = animation_index + 1

## 正常完成或中断均关闭角色受击因素；父类负责停止子状态和全部技能计时器。
func exit() -> void:
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	super.exit()


## 检查完整阶段链、循环动画及受击关键帧，防止缺失配置后遗留受击窗口。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	# 父类通用技能配置检查返回的错误信息；空字符串表示已通过。
	var error := super.get_configuration_error()
	if not error.is_empty():
		return error
	if not child_state_machine.initial_state is ZB001DoctorStateHeadPrepare:
		detected_error = "低头技能必须使用 HeadPrepare 锁定行号并处理无目标的情况。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not effect_component is ZB001DoctorSkillIceFireBall:
		detected_error = "低头技能必须绑定 IceFireBallSkill。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if animation_lanes.size() != action_animations.size():
		detected_error = "吐球动画与目标行数组必须一一对应。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 已验证的行号集合，避免一行配置多个动画后产生选择歧义。
	var seen_lanes: Array[int] = []
	# 当前动画对应的零起始行号；场景不存在的行在准备时排除。
	for lane: int in animation_lanes:
		if lane < 0 or seen_lanes.has(lane):
			detected_error = "吐球动画行号必须非负且不能重复。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		seen_lanes.append(lane)
	error = (effect_component as ZB001DoctorSkillIceFireBall).get_configuration_error()
	if not error.is_empty():
		return error
	# 当前待检查的头部阶段节点，必须存在且直属本技能的子状态机。
	for state: CharacterState in [head_enter_state, before_spit_idle_state, head_attack_state, after_spit_idle_state, head_leave_state]:
		if not is_instance_valid(state) or state.get_parent() != child_state_machine:
			detected_error = "低头、两段待机、吐球和抬头必须绑定直属子状态。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	if before_spit_idle_state == after_spit_idle_state:
		detected_error = "吐球前后必须使用两个独立的低头待机节点。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if (child_state_machine.initial_state as ZB001DoctorStateSkillPrepare).next_state != head_enter_state \
		or before_spit_idle_state.next_state != head_attack_state \
		or head_attack_state.next_state != after_spit_idle_state or after_spit_idle_state.next_state != head_leave_state:
		detected_error = "低头技能必须按 Prepare、LowerHead、BeforeSpitIdle、SpitBall、AfterSpitIdle、RaiseHead 连接。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not state_machine.animation_player.has_animation(ZB001DoctorStateMachine.HEAD_IDLE_ANIMATION):
		detected_error = "缺少低头待机动画 Zombie_boss_head_idle。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if state_machine.animation_player.get_animation(ZB001DoctorStateMachine.HEAD_IDLE_ANIMATION).loop_mode != Animation.LOOP_LINEAR:
		detected_error = "低头待机动画必须为线性循环。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not _has_hurt_keyframe(ZB001DoctorStateMachine.HEAD_ENTER_ANIMATION, &"hurt_enable", 2.0):
		detected_error = "低头动画必须在第 2 秒配置唯一的 hurt_enable 事件。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not _has_hurt_keyframe(ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION, &"hurt_disable", 0.6667):
		detected_error = "抬头动画必须在第 0.6667 秒配置唯一的 hurt_disable 事件。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""


## 复用主状态机检查事件唯一性，再确认关键帧位于约定的动画时间。[br]
## [param animation_name] 待检查的低头或抬头动画名称。[br]
## [param event_name] 方法轨道传入的受击开关事件名。[br]
## [param expected_time] 约定的动画秒数；仅容忍资源浮点序列化带来的微小误差。
func _has_hurt_keyframe(animation_name: StringName, event_name: StringName, expected_time: float) -> bool:
	if not state_machine.animation_player.has_animation(animation_name):
		return false
	# 需要校验方法轨道的动画资源，只读取关键帧，不修改动画。
	var animation: Animation = state_machine.animation_player.get_animation(animation_name)
	if not doctor_state_machine.has_skill_keyframe(animation, animation_name, event_name):
		return false
	# 动画轨道下标，只检查指向博士主状态机且已启用的方法轨道。
	for track: int in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_METHOD or not animation.track_is_enabled(track) \
			or animation.track_get_path(track) != NodePath("StateMachine"):
			continue
		# 当前方法关键帧下标，用于读取事件及其动画时间。
		for key: int in animation.track_get_key_count(track):
			# 方法轨道的调用字典，包含事件入口和动画名、事件名参数。
			var event: Dictionary = animation.track_get_key_value(track, key)
			if event.get("method") == &"notify_skill_event" and event.get("args") == [animation_name, event_name]:
				return absf(animation.track_get_key_time(track, key) - expected_time) <= 0.00001
	return false
