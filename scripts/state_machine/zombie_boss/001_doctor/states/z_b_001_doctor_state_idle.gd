## 普通待机关闭受击；达到最短待机时间后，等当前动画周期结束再选择完整技能。
extends ZB001DoctorState
class_name ZB001DoctorStateIdle

## 最短待机时间的单次动作计时器；到期只申请结束当前周期，倍率和暂停跟随角色。
@onready var idle_wait_timer: SpeedTimer = get_node_or_null("IdleWaitTimer") as SpeedTimer

## 计时已经结束、正在等待本轮动画播完；退出或消费结束通知后清除，防止重复选技能。
var _waiting_for_cycle_end: bool = false


## 通过动画控制器开始本实例循环待机并计时，循环副本由控制器统一管理。
func enter() -> void:
	boss.is_idle = true
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	_waiting_for_cycle_end = false
	doctor_state_machine.animation_controller.play_idle_loop(ZB001DoctorAnimationController.DriverReaction.DRIVE)
	# 先播放再同步实际倍率，保证冻结入场及暂停恢复时计时与动画一致。
	doctor_state_machine.sync_action_timer_speed()
	idle_wait_timer.start_scaled(doctor_state_machine.idle_duration)


## 正常切换、停止及死亡中断都清理计时，并恢复循环，供下次 Idle 或放置间隔使用。
func exit() -> void:
	if is_instance_valid(idle_wait_timer):
		idle_wait_timer.stop()
	_waiting_for_cycle_end = false
	doctor_state_machine.animation_controller.restore_idle_loop()


## 到期后保留当前播放进度，只关闭本实例的循环，等待这一轮自然结束，不立即选技能。
## 已退出、停止、死亡或已经在等待结束时，忽略迟到及重复通知。
func _on_idle_wait_timer_timeout() -> void:
	if not state_machine.is_running or state_machine.current_state != self or boss.is_death or _waiting_for_cycle_end:
		return
	_waiting_for_cycle_end = true
	doctor_state_machine.animation_controller.request_idle_cycle_end()


## [param anim_name] 为已结束的机甲动画；仅消费计时到期后的待机结束通知，随后选择下一技能。
## 没有可用技能时重新循环和计时；死亡中断仍由主状态机立即接管，不等待动画结束。
func on_animation_finished(anim_name: StringName) -> void:
	if anim_name != ZB001DoctorAnimations.IDLE_ANIMATION or not _waiting_for_cycle_end \
		or not state_machine.is_running or state_machine.current_state != self or boss.is_death:
		return
	# 在选择前消费本轮完成标记，避免同一切换周期中的重复通知再次抽取并累计回合。
	_waiting_for_cycle_end = false
	# 本轮实际结束时才选择技能，使目标条件按此刻的场景状态判断；空池不占用回合。
	var selected: ZB001DoctorSkillState = doctor_state_machine.select_skill()
	if selected != null:
		state_machine.change_state(selected)
		return
	# 当前动画已经停止；空池时重新播放循环，而不是只重启计时器后停在待机末帧。
	doctor_state_machine.animation_controller.play_idle_loop(ZB001DoctorAnimationController.DriverReaction.KEEP, 0.0)
	doctor_state_machine.sync_action_timer_speed()
	idle_wait_timer.start_scaled(doctor_state_machine.idle_duration)
