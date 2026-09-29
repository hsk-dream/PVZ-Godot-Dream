## 蹦极准备阶段锁定整组范围和目标；目标清空时结束本轮，不播放空的进入动画。
extends ZB001DoctorStateSkillPrepare
class_name ZB001DoctorStateBungeePrepare


## 只在此处随机一次并定位手臂，进入动画播放期间不重新选点。
func enter() -> void:
	skill_state.prepare_action()
	if skill_state.selected_animation.is_empty():
		skill_state.finish_skill()
		return
	state_machine.change_state(next_state)


## 入口必须属于蹦极技能，并连接负责播放进入动画的动作状态。
func get_configuration_error() -> String:
	if not skill_state is ZB001DoctorStateBungee:
		push_error("BungeePrepare：必须位于蹦极技能内。")
		return "蹦极准备状态所属技能错误。"
	if not next_state is ZB001DoctorStateSkillAction:
		push_error("BungeePrepare：必须连接进入动画状态。")
		return "蹦极准备状态后续连线错误。"
	return super.get_configuration_error()
