extends ZB001DoctorSkillState
class_name ZB001DoctorStateHeadSkill
## 一次技能依次准备、低头、吐球前待机、吐一个球、吐球后待机、抬头。

## 低头动作子状态；Prepare 完成后进入，由动画中的 hurt_enable 关键帧开启受击。
@export var head_enter_state: ZB001DoctorStateHeadEnter
## 吐球前的低头待机，具有独立的等待时长与计时器。
@export var before_spit_idle_state: ZB001DoctorStateHeadIdle
## 单次吐球子状态；继承受击窗口，并在释放关键帧调用一次技能效果。
@export var head_attack_state: ZB001DoctorStateHeadAttack
## 吐球后的低头待机，等待完成后才开始抬头收尾。
@export var after_spit_idle_state: ZB001DoctorStateHeadIdle
## 抬头收尾子状态；由动画中的 hurt_disable 关键帧关闭受击，动作结束后完成整轮技能。
@export var head_leave_state: ZB001DoctorStateHeadLeave


## 正常完成或中断均关闭受击；父类负责退出子状态、结束组件生命周期和停止计时器。
func exit() -> void:
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	super.exit()


## 检查完整阶段链、循环动画及受击关键帧，防止缺失配置后遗留受击窗口。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	if not effect_component is ZB001DoctorSkillIceFireBall:
		push_error("%s：必须绑定 ZB001DoctorSkillIceFireBall 效果组件。" % get_path())
		return "技能效果组件类型错误。"
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
	if not _has_unique_hurt_keyframe(ZB001DoctorAnimations.HEAD_ENTER_ANIMATION, &"hurt_enable"):
		detected_error = "低头动画必须在动画内部配置唯一的 hurt_enable 事件，时刻由轨道决定。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not _has_unique_hurt_keyframe(ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION, &"hurt_disable"):
		detected_error = "抬头动画必须在动画内部配置唯一的 hurt_disable 事件，时刻由轨道决定。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""


## 只要求受击开关事件唯一且位于动画内部，具体秒数直接在方法轨道调整。[br]
## [param animation_name] 待检查的低头或抬头动画名称。[br]
## [param event_name] 方法轨道传入的受击开关事件名。[br]
## 起止边界不作为有效开关帧，避免动作切换和延迟方法调用在边界发生竞争。
func _has_unique_hurt_keyframe(animation_name: StringName, event_name: StringName) -> bool:
	# 基础动画已由控制器校验，查询只读取方法事件，不改变资源。
	var animation: Animation = state_machine.animation_player.get_animation(animation_name)
	# 保留唯一性和时长范围检查，不再用固定秒数限制动画编辑。
	var times: Array[float] = AnimationMethodQuery.get_times(animation, NodePath("StateMachine"), &"notify_skill_event", [animation_name, event_name], false)
	return times.size() == 1


## 子状态停止前查询当前头部姿态，死亡状态不再识别具体头部阶段类型。
func needs_head_return() -> bool:
	# 当前内部阶段；准备阶段尚未低头，其余头部动作均需先抬头。
	var phase: CharacterState = child_state_machine.current_state
	return phase is ZB001DoctorStateHeadEnter or phase is ZB001DoctorStateHeadIdle \
		or phase is ZB001DoctorStateHeadAttack or phase is ZB001DoctorStateHeadLeave
