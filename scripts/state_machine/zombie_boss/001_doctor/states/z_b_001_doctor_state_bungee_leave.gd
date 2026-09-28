## 蹦极离开阶段只播放收尾动画；不再次处理进入段的技能释放事件。
extends ZB001DoctorState
class_name ZB001DoctorStateBungeeLeave

## 离开动画结束后的同层状态，场景中绑定 Finish。
@export var next_state: CharacterState
## 本次进入时锁定的离开动画名称，用于忽略其他动画的完成通知。
var _animation: StringName
## 避免重复完成通知多次请求切换，进入本状态时重置。
var _finished: bool = false


## 等待返回结束后从离开动画的零秒继续，零秒姿态对应进入动画的末帧。
func enter() -> void:
	_finished = false
	_animation = (skill_state as ZB001DoctorStateBungee).leave_animation
	doctor_state_machine.play_mech_animation(_animation)
	doctor_state_machine.sync_action_timer_speed()


## [param anim_name] 当前完成的动画名称，只有本段完成且技能仍活动时才进入收尾状态。
func on_animation_finished(anim_name: StringName) -> void:
	if anim_name == _animation and not _finished and skill_state.is_active_skill():
		_finished = true
		state_machine.change_state(next_state)


## 校验离开段独立存在且非循环，不要求它具有进入段的释放关键帧。
func get_configuration_error() -> String:
	if not skill_state is ZB001DoctorStateBungee:
		push_error("BungeeLeave：必须位于蹦极技能内。")
		return "蹦极离开状态所属技能错误。"
	if not is_instance_valid(next_state) or next_state.get_parent() != state_machine or next_state == self:
		push_error("BungeeLeave：必须绑定有效的同层后续状态。")
		return "蹦极离开状态后续连线错误。"
	# 复合技能提供单独的离开动画名，与进入动画的可选列表分离。
	var bungee_state := skill_state as ZB001DoctorStateBungee
	if bungee_state.leave_animation.is_empty() or not state_machine.animation_player.has_animation(bungee_state.leave_animation):
		push_error("BungeeLeave：缺少配置的离开动画。")
		return "蹦极离开动画不存在。"
	# 离开动画必须能发出结束通知，随后由 Finish 完成整轮技能。
	var animation: Animation = state_machine.animation_player.get_animation(bungee_state.leave_animation)
	if animation.loop_mode != Animation.LOOP_NONE:
		push_error("BungeeLeave：离开动画必须为非循环。")
		return "蹦极离开动画循环模式错误。"
	return ""
