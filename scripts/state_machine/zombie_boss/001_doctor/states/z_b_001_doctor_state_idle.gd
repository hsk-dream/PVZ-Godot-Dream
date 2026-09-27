extends ZB001DoctorState
class_name ZB001DoctorStateIdle
## 普通待机关闭受击；等待结束后从五个完整技能中选择，不参与其内部收尾。

## 选择下一项技能前的单次动作计时器，跟随角色动画速度和暂停状态。
@onready var idle_wait_timer: SpeedTimer = get_node_or_null("IdleWaitTimer") as SpeedTimer


## 动画资源自身负责循环，每帧重播会让动画一直停在开头。
func enter() -> void:
	boss.is_idle = true
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	state_machine.animation_player.play(ZB001DoctorStateMachine.IDLE_ANIMATION)
	# 先播放再同步实际倍率，保证冻结入场及暂停恢复时计时与动画一致。
	doctor_state_machine.sync_action_timer_speed()
	idle_wait_timer.start_scaled(doctor_state_machine.idle_duration)


## 清理局部计时，下一次进入会使用当前配置重新开始。
func exit() -> void:
	if is_instance_valid(idle_wait_timer):
		idle_wait_timer.stop()


## 超时只提交请求；已退出、停止或死亡时不能被迟到通知重新拉回战斗。
func _on_idle_wait_timer_timeout() -> void:
	if state_machine.is_running and state_machine.current_state == self and not boss.is_death:
		# 本轮选中的技能；null 表示没有可用技能，继续待机并定时重试。
		var selected := doctor_state_machine.select_skill()
		if selected != null:
			state_machine.change_state(selected)
		else:
			# 没有任何可用技能时继续待机；定时重试允许后续权重调整生效，避免忙循环。
			idle_wait_timer.start_scaled(doctor_state_machine.idle_duration)


## 待机动画通常循环，不依赖其结束通知推进战斗；下一招由决策条件决定。
## [param _anim_name] 收到的动画完成名称；当前状态不依赖该通知推进流程。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 默认不释放技能；如扩展待机表现事件，应与攻击事件分开处理。
## [param _event_name] 收到的动画事件名；当前状态不处理技能释放事件。
func on_animation_event(_event_name: StringName) -> void:
	pass
