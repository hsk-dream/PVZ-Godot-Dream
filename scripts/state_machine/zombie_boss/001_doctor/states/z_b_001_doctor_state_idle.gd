## 普通待机关闭受击；达到最短待机时间后，等当前动画周期结束再选择完整技能。
extends ZB001DoctorState
class_name ZB001DoctorStateIdle

## 最短待机时间的单次动作计时器；到期只申请结束当前周期，倍率和暂停跟随角色。
@onready var idle_wait_timer: SpeedTimer = get_node_or_null("IdleWaitTimer") as SpeedTimer

## 计时已经结束、正在等待本轮动画播完；退出或消费结束通知后清除，防止重复选技能。
var _waiting_for_cycle_end: bool = false
## 动画控制器复制后的当前博士实例待机动画；仅在 Idle 活动期间保存，退出时恢复循环。
var _idle_animation: Animation


## 开始循环待机并计时；只修改当前实例动画副本，保持共享资源及其他博士的播放规则。
func enter() -> void:
	boss.is_idle = true
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	_waiting_for_cycle_end = false
	_idle_animation = state_machine.animation_player.get_animation(ZB001DoctorAnimations.IDLE_ANIMATION)
	_idle_animation.loop_mode = Animation.LOOP_LINEAR
	doctor_state_machine.animation_controller.play_mech_action(ZB001DoctorAnimations.IDLE_ANIMATION, ZB001DoctorAnimationController.DriverReaction.DRIVE)
	# 先播放再同步实际倍率，保证冻结入场及暂停恢复时计时与动画一致。
	doctor_state_machine.sync_action_timer_speed()
	idle_wait_timer.start_scaled(doctor_state_machine.idle_duration)


## 正常切换、停止及死亡中断都清理计时，并恢复循环，供下次 Idle 或放置间隔使用。
func exit() -> void:
	if is_instance_valid(idle_wait_timer):
		idle_wait_timer.stop()
	_waiting_for_cycle_end = false
	if is_instance_valid(_idle_animation):
		_idle_animation.loop_mode = Animation.LOOP_LINEAR
	_idle_animation = null


## 到期后保留当前播放进度，只关闭本实例的循环，等待这一轮自然结束，不立即选技能。
## 已退出、停止、死亡或已经在等待结束时，忽略迟到及重复通知。
func _on_idle_wait_timer_timeout() -> void:
	if not state_machine.is_running or state_machine.current_state != self or boss.is_death or _waiting_for_cycle_end:
		return
	_waiting_for_cycle_end = true
	_idle_animation.loop_mode = Animation.LOOP_NONE


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
	_idle_animation.loop_mode = Animation.LOOP_LINEAR
	doctor_state_machine.animation_controller.play_mech_action(ZB001DoctorAnimations.IDLE_ANIMATION, ZB001DoctorAnimationController.DriverReaction.KEEP, 0.0)
	doctor_state_machine.sync_action_timer_speed()
	idle_wait_timer.start_scaled(doctor_state_machine.idle_duration)


## 默认不释放技能；如扩展待机表现事件，应与攻击事件分开处理。
## [param _event_name] 收到的动画事件名；当前状态不处理技能释放事件。
func on_animation_event(_event_name: StringName) -> void:
	pass
