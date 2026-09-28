extends ZB001DoctorState
class_name ZB001DoctorStateDying
## 低头死亡先抬头，随后播放机甲死亡；由方法关键帧启动本体死亡、举旗，全部完成后进入保留阶段。

## 死亡请求时是否处于低头、低头待机、吐球或抬头阶段；在旧技能停止前记录，进入时消费。
var _needs_head_return := false
## 当前是否正在执行死亡前的抬头过渡；只接受相应动画的结束通知。
var _returning_head := false
## 本体死亡序列是否已由机甲关键帧启动，防止重复事件重播动作。
var _driver_death_started := false
## 机甲死亡动画是否已结束；需与本体举旗动作全部完成后再进入 Dead。
var _mech_finished := false
## 本体死亡和举旗两个单次动作是否已经完成。
var _driver_finished := false


## 在技能子状态被清空之前记录姿态需求，准备阶段尚未低头，不需要抬头过渡。[br]
## [param previous_state] 死亡请求时的主层状态；只有低头技能的动作阶段需要先抬头。
func prepare_head_return(previous_state: CharacterState) -> void:
	_needs_head_return = false
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
	_mech_finished = false
	_driver_finished = false
	# 本体死亡启动关键帧到达前保持待机，不延续被死亡中断的操纵或吐球动作。
	doctor_state_machine.driver_animation_player.play(ZB001DoctorStateMachine.DRIVER_IDLE_ANIMATION)
	_returning_head = _needs_head_return
	_needs_head_return = false
	if _returning_head:
		# 若已经开始抬头，则从当前动画秒数继续，避免再次回到低头姿态。
		var resume_position := 0.0
		if state_machine.animation_player.assigned_animation == ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION:
			resume_position = state_machine.animation_player.current_animation_position
		# 抬头可能在死亡请求与状态切换之间结束；此时直接进入死亡动画，不能等待已错过的通知。
		if resume_position < state_machine.animation_player.get_animation(ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION).length:
			state_machine.animation_player.play(ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION)
			if resume_position > 0.0:
				state_machine.animation_player.seek(resume_position, true)
			return
	_start_death_animation()


## 抬头完成后仅启动机甲死亡动画，本体等待轨道中配置的死亡启动关键帧。
func _start_death_animation() -> void:
	_returning_head = false
	state_machine.animation_player.play(ZB001DoctorStateMachine.DEATH_ANIMATION)


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
	driver.play(ZB001DoctorStateMachine.DRIVER_DEATH_ANIMATION)


## 本体单次动作依次播放死亡、举旗；完成后交给 Dead 播放循环并启动保留计时。[br]
## [param anim_name] 本体已结束的动画名；死亡序列尚未启动时不接收普通动作的结束事件。
func on_driver_animation_finished(anim_name: StringName) -> void:
	if not _driver_death_started or _driver_finished:
		return
	if anim_name == ZB001DoctorStateMachine.DRIVER_DEATH_ANIMATION:
		doctor_state_machine.driver_animation_player.play(ZB001DoctorStateMachine.DRIVER_FLAG_ANIMATION)
	elif anim_name == ZB001DoctorStateMachine.DRIVER_FLAG_ANIMATION:
		_driver_finished = true
		_try_finish_death()


## 机甲和本体各自完成后才能进入最终循环，避免机甲先结束就把本体死亡动作截断。
func _try_finish_death() -> void:
	if _mech_finished and _driver_finished:
		state_machine.change_state(doctor_state_machine.dead_state)


## 抬头结束推进机甲死亡；机甲结束后等待本体序列，不立即删除角色。[br]
## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func on_animation_finished(anim_name: StringName) -> void:
	if _returning_head:
		if anim_name == ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION:
			_start_death_animation()
		return
	if anim_name == ZB001DoctorStateMachine.DEATH_ANIMATION:
		_mech_finished = true
		_try_finish_death()
