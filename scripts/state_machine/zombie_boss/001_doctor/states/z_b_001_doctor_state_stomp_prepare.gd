## 脚踩准备阶段：目标消失时由组件随机选择踩空区域，仅无完整区域或战斗失效时结束。
extends ZB001DoctorStateSkillPrepare
class_name ZB001DoctorStateStompPrepare


## 锁定区域及对应动画后进入 Execute，每轮只播放一段脚踩动作。
func enter() -> void:
	skill_state.prepare_action()
	if skill_state.selected_animation.is_empty():
		skill_state.finish_skill()
		return
	state_machine.change_state(next_state)


## 限定准备状态属于脚踩技能，且后续状态能够处理动画踩踏事件。
func get_configuration_error() -> String:
	if not skill_state is ZB001DoctorStateStomp:
		push_error("StompPrepare：必须位于脚踩技能内。")
		return "脚踩准备状态所属技能错误。"
	if not next_state is ZB001DoctorStateSkillAction:
		push_error("StompPrepare：必须连接技能动作状态。")
		return "脚踩准备状态后续连线错误。"
	return super.get_configuration_error()
