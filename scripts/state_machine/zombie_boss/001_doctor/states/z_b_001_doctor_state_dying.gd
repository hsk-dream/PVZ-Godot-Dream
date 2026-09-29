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
## 技能取消前取得的视觉复位数据，进入死亡后交给动画控制器。
var _visual_returns: Array[ZB001DoctorVisualReturn] = []


## [param previous_state] 为尚未清理的旧主状态；只读取技能统一接口，不识别具体技能类型。
func prepare_interruption(previous_state: CharacterState) -> void:
	_needs_head_return = false
	_visual_returns.clear()
	if previous_state is ZB001DoctorSkillState:
		# 通用技能状态提供头部要求，组件提供其代码控制的部件复位信息。
		var skill: ZB001DoctorSkillState = previous_state as ZB001DoctorSkillState
		_needs_head_return = skill.needs_head_return()
		_visual_returns = skill.effect_component.capture_visual_returns()


## 致死伤害的调用尾部可能重新生成控制效果，切换状态时再次整理。
func enter() -> void:
	boss.is_idle = false
	boss.prepare_death_animation()
	_driver_death_started = false
	_driver_finished = false
	doctor_state_machine.animation_controller.begin_visual_returns(_visual_returns)
	_visual_returns.clear()
	# 本体死亡启动关键帧到达前保持待机，不延续被死亡中断的操纵或吐球动作。
	doctor_state_machine.animation_controller.play_driver_animation(ZB001DoctorAnimations.DRIVER_IDLE_ANIMATION)
	_returning_head = _needs_head_return
	_needs_head_return = false
	if _returning_head:
		# 若已经开始抬头，则从当前动画秒数继续，避免再次回到低头姿态。
		var resume_position := 0.0
		if state_machine.animation_player.assigned_animation == ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION:
			resume_position = state_machine.animation_player.current_animation_position
		# 抬头可能在死亡请求与状态切换之间结束；此时直接进入死亡动画，不能等待已错过的通知。
		if resume_position < state_machine.animation_player.get_animation(ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION).length:
			if state_machine.animation_player.assigned_animation == ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION:
				# 原抬头动作继续播放，不重新捕获、不重播零秒音效，也不跳过已有关键帧。
				state_machine.animation_player.play(ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION)
			else:
				doctor_state_machine.animation_controller.play_mech_action(ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION, ZB001DoctorAnimationController.DriverReaction.KEEP, doctor_state_machine.animation_controller.death_transition_duration)
			return
	_start_death_animation()


## 抬头完成后仅启动机甲死亡动画，本体等待轨道中配置的死亡启动关键帧。
func _start_death_animation() -> void:
	# 完整抬头后的姿势已经对齐；其余动作中途死亡从当前姿势过渡。
	var transition_duration: float = 0.0 if _returning_head else doctor_state_machine.animation_controller.death_transition_duration
	_returning_head = false
	doctor_state_machine.animation_controller.play_mech_action(ZB001DoctorAnimations.DEATH_ANIMATION, ZB001DoctorAnimationController.DriverReaction.KEEP, transition_duration)


## 死亡阶段提前退出时结束剩余视觉复位，避免留下技能偏移。
func exit() -> void:
	doctor_state_machine.animation_controller.finish_visual_returns()
	_visual_returns.clear()


## 接收机甲轨道中的本体死亡事件；使用动画时间触发，使死亡加速后仍与机甲姿态对齐。[br]
## [param event_name] 方法轨道的事件名；仅接受本阶段的本体死亡启动事件，重复或迟到事件忽略。
func on_animation_event(event_name: StringName) -> void:
	if event_name != &"driver_death" or _returning_head or _driver_death_started \
		or state_machine.animation_player.assigned_animation != ZB001DoctorAnimations.DEATH_ANIMATION:
		return
	_driver_death_started = true
	# 在关键帧当下同步倍率，后续动作由本体结束信号推进。
	doctor_state_machine.animation_controller.sync_driver_speed()
	doctor_state_machine.animation_controller.play_driver_animation(ZB001DoctorAnimations.DRIVER_DEATH_ANIMATION)


## 本体单次动作依次播放死亡、举旗；举旗完成即交给 Dead 播放循环并计时，不等待机甲结束。[br]
## [param anim_name] 本体已结束的动画名；死亡序列尚未启动时不接收普通动作的结束事件。
func on_driver_animation_finished(anim_name: StringName) -> void:
	if not _driver_death_started or _driver_finished:
		return
	if anim_name == ZB001DoctorAnimations.DRIVER_DEATH_ANIMATION:
		doctor_state_machine.animation_controller.play_driver_animation(ZB001DoctorAnimations.DRIVER_FLAG_ANIMATION)
	elif anim_name == ZB001DoctorAnimations.DRIVER_FLAG_ANIMATION:
		_driver_finished = true
		# Dead 只切换本体播放器，尚未播完的机甲动画及其奖杯方法轨道继续运行。
		state_machine.change_state(doctor_state_machine.dead_state)


## 只在抬头结束时推进机甲死亡；机甲死亡动画的结束不参与本体循环切换。[br]
## [param anim_name] 本次结束的机甲动画名称，只有死亡前抬头的结束通知需要处理。
func on_animation_finished(anim_name: StringName) -> void:
	if _returning_head:
		if anim_name == ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION:
			_start_death_animation()
		return


## 检查机甲死亡轨道能启动本体死亡；允许起止关键帧，具体时机完全由轨道决定。
func get_configuration_error() -> String:
	# 基础动画已由控制器校验，此处只负责死亡序列所需的方法事件。
	var animation: Animation = state_machine.animation_player.get_animation(ZB001DoctorAnimations.DEATH_ANIMATION)
	if AnimationMethodQuery.get_times(animation, NodePath("StateMachine"), &"notify_animation_event", [&"driver_death"]).is_empty():
		push_error("%s：机甲死亡动画必须具有有效的 driver_death 方法事件。" % get_path())
		return "缺少本体死亡启动事件。"
	return ""
