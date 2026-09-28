extends ZB001DoctorState
class_name ZB001DoctorStateDying
## 低头死亡先抬头，随后播放机甲死亡；由方法关键帧启动本体死亡、举旗，举旗完成即进入循环保留阶段。

## 死亡请求时是否处于低头、低头待机、吐球或抬头阶段；在旧技能停止前记录，进入时消费。
var _needs_head_return := false
## 当前是否正在执行死亡前的抬头过渡；只接受相应动画的结束通知。
var _returning_head := false
## 本体死亡序列是否已由机甲关键帧启动，防止重复事件重播动作。
var _driver_death_started := false
## 本体死亡和举旗是否已经完成，防止重复的结束通知再次提交 Dead 状态。
var _driver_finished := false
## 被死亡打断的技能手臂；记录脚本控制的偏移，避免技能退出复位时瞬移。
var _returning_arm: Node2D
## 死亡请求瞬间的手臂局部偏移，作为过渡起点。
var _arm_start_position: Vector2 = Vector2.ZERO
## 旧技能完成清理后的手臂位置；沿用各技能的复位规则，蹦极只复位 X。
var _arm_target_position: Vector2 = Vector2.ZERO
## 手臂复位已消耗的动作秒数，跟随机甲死亡播放倍率。
var _arm_return_elapsed: float = 0.0


## 在旧技能清理前记录头部阶段及手臂偏移；准备阶段尚未低头，不需要抬头过渡。[br]
## [param previous_state] 死亡请求时的主层状态；低头动作先抬头，丢车和蹦极保存手臂偏移。
func prepare_head_return(previous_state: CharacterState) -> void:
	_needs_head_return = false
	_returning_arm = null
	# 在旧技能退出清零偏移之前保存；正常完成技能仍使用原来的立即复位。
	if previous_state is ZB001DoctorStateThrowRV:
		_returning_arm = ((previous_state as ZB001DoctorStateThrowRV).effect_component as ZB001DoctorSkillThrowRV).inner_arm
	elif previous_state is ZB001DoctorStateBungee:
		_returning_arm = ((previous_state as ZB001DoctorStateBungee).effect_component as ZB001DoctorSkillBungee).inner_arm
	if is_instance_valid(_returning_arm):
		_arm_start_position = _returning_arm.position
	if previous_state is ZB001DoctorStateHeadSkill:
		# 死亡瞬间仍在执行的头部子状态，停止子状态机后此引用会被清空。
		var head_phase: CharacterState = (previous_state as ZB001DoctorStateHeadSkill).child_state_machine.current_state
		_needs_head_return = head_phase is ZB001DoctorStateHeadEnter \
			or head_phase is ZB001DoctorStateHeadIdle or head_phase is ZB001DoctorStateHeadAttack \
			or head_phase is ZB001DoctorStateHeadLeave


## 致死伤害的调用尾部可能重新生成控制效果，切换状态时再次整理。
func enter() -> void:
	boss.is_idle = false
	boss.prepare_death_animation()
	_driver_death_started = false
	_driver_finished = false
	_arm_return_elapsed = 0.0
	# 旧技能已经完成清理，在本帧恢复原偏移，随后与死亡姿势同步收回。
	if is_instance_valid(_returning_arm):
		_arm_target_position = _returning_arm.position
		_returning_arm.position = _arm_start_position
		if not is_finite(doctor_state_machine.death_transition_duration) or doctor_state_machine.death_transition_duration <= 0.0:
			_returning_arm.position = _arm_target_position
			_returning_arm = null
	# 本体死亡启动关键帧到达前保持待机，不延续被死亡中断的操纵或吐球动作。
	doctor_state_machine.play_driver_animation(ZB001DoctorStateMachine.DRIVER_IDLE_ANIMATION)
	_returning_head = _needs_head_return
	_needs_head_return = false
	if _returning_head:
		# 若已经开始抬头，则从当前动画秒数继续，避免再次回到低头姿态。
		var resume_position := 0.0
		if state_machine.animation_player.assigned_animation == ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION:
			resume_position = state_machine.animation_player.current_animation_position
		# 抬头可能在死亡请求与状态切换之间结束；此时直接进入死亡动画，不能等待已错过的通知。
		if resume_position < state_machine.animation_player.get_animation(ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION).length:
			if state_machine.animation_player.assigned_animation == ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION:
				# 原抬头动作继续播放，不重新捕获、不重播零秒音效，也不跳过已有关键帧。
				state_machine.animation_player.play(ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION)
			else:
				doctor_state_machine.play_mech_animation(ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION, doctor_state_machine.death_transition_duration)
			return
	_start_death_animation()


## 抬头完成后仅启动机甲死亡动画，本体等待轨道中配置的死亡启动关键帧。
func _start_death_animation() -> void:
	# 完整抬头后的姿势已经对齐；其余动作中途死亡从当前姿势过渡。
	var transition_duration: float = 0.0 if _returning_head else doctor_state_machine.death_transition_duration
	_returning_head = false
	doctor_state_machine.play_mech_animation(ZB001DoctorStateMachine.DEATH_ANIMATION, transition_duration)


## 平滑收回丢车、蹦极通过代码设置的手臂偏移；[param delta] 为状态机传入的游戏秒。
## 这些父节点属性不在动画轨道中，需要单独处理；角色倍率为零时同样停止推进。
func update(delta: float) -> void:
	if not is_instance_valid(_returning_arm):
		return
	# 当前配置的过渡动作秒数，允许运行时调为零以立即完成。
	var duration: float = doctor_state_machine.death_transition_duration
	if not is_finite(duration) or duration <= 0.0:
		_returning_arm.position = _arm_target_position
		_returning_arm = null
		return
	_arm_return_elapsed += delta * absf(state_machine.animation_player.get_playing_speed())
	# 与捕获过渡一致使用线性插值，结束后准确落在技能的复位位置。
	var progress: float = clampf(_arm_return_elapsed / duration, 0.0, 1.0)
	_returning_arm.position = _arm_start_position.lerp(_arm_target_position, progress)
	if progress >= 1.0:
		_returning_arm = null


## 死亡状态提前停止或正常结束时清理剩余手臂偏移，不遗留未完成的插值。
func exit() -> void:
	if is_instance_valid(_returning_arm):
		_returning_arm.position = _arm_target_position
	_returning_arm = null


## 接收机甲轨道中的本体死亡事件；使用动画时间触发，使死亡加速后仍与机甲姿态对齐。[br]
## [param event_name] 方法轨道的事件名；仅接受本阶段的本体死亡启动事件，重复或迟到事件忽略。
func on_animation_event(event_name: StringName) -> void:
	if event_name != &"driver_death" or _returning_head or _driver_death_started \
		or state_machine.animation_player.assigned_animation != ZB001DoctorStateMachine.DEATH_ANIMATION:
		return
	_driver_death_started = true
	# 本体播放器独立于机甲；后续动作依靠自身的结束信号串联。
	var driver := doctor_state_machine.driver_animation_player
	driver.speed_scale = state_machine.animation_player.speed_scale
	doctor_state_machine.play_driver_animation(ZB001DoctorStateMachine.DRIVER_DEATH_ANIMATION)


## 本体单次动作依次播放死亡、举旗；举旗完成即交给 Dead 播放循环并计时，不等待机甲结束。[br]
## [param anim_name] 本体已结束的动画名；死亡序列尚未启动时不接收普通动作的结束事件。
func on_driver_animation_finished(anim_name: StringName) -> void:
	if not _driver_death_started or _driver_finished:
		return
	if anim_name == ZB001DoctorStateMachine.DRIVER_DEATH_ANIMATION:
		doctor_state_machine.play_driver_animation(ZB001DoctorStateMachine.DRIVER_FLAG_ANIMATION)
	elif anim_name == ZB001DoctorStateMachine.DRIVER_FLAG_ANIMATION:
		_driver_finished = true
		# Dead 只切换本体播放器，尚未播完的机甲动画及其奖杯方法轨道继续运行。
		state_machine.change_state(doctor_state_machine.dead_state)


## 只在抬头结束时推进机甲死亡；机甲死亡动画的结束不参与本体循环切换。[br]
## [param anim_name] 本次结束的机甲动画名称，只有死亡前抬头的结束通知需要处理。
func on_animation_finished(anim_name: StringName) -> void:
	if _returning_head:
		if anim_name == ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION:
			_start_death_animation()
		return
