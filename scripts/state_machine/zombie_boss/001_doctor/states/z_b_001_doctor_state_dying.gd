extends ZB001DoctorState
class_name ZB001DoctorStateDying
## 低头期间死亡先取消吐球并抬头，再播放死亡动画；奖杯仍由死亡动画方法轨道请求。

## 死亡请求时是否处于低头、低头待机、吐球或抬头阶段；在旧技能停止前记录，进入时消费。
var _needs_head_return := false
## 当前是否正在执行死亡前的抬头过渡；只接受相应动画的结束通知。
var _returning_head := false


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


## 抬头完成后才启动主体和驾驶员死亡演出，过渡期间不播放死亡动画或请求奖杯。
func _start_death_animation() -> void:
	_returning_head = false
	state_machine.animation_player.play(ZB001DoctorStateMachine.DEATH_ANIMATION)
	# 驾驶舱博士的独立动画播放器，用于同步死亡演出及主体播放倍率。
	var driver := doctor_state_machine.driver_animation_player
	driver.speed_scale = state_machine.animation_player.speed_scale
	driver.play(ZB001DoctorStateMachine.DRIVER_DEATH_ANIMATION)


## 抬头结束只推进死亡演出；只有主体死亡动画结束才能清理尸体。[br]
## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func on_animation_finished(anim_name: StringName) -> void:
	if _returning_head:
		if anim_name == ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION:
			_start_death_animation()
		return
	if anim_name == ZB001DoctorStateMachine.DEATH_ANIMATION:
		state_machine.change_state(doctor_state_machine.dead_state)
