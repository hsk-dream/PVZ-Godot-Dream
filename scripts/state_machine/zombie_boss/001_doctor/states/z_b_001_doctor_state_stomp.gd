## 脚踩复合状态：锁定区域对应的动画，一次动作完成后沿用 Finish 返回待机。
extends ZB001DoctorSkillState
class_name ZB001DoctorStateStomp

## 通用检查负责非循环动画及释放帧，这里检查准备入口归属、动作类型与脚踩效果组件。
func get_configuration_error() -> String:
	if not effect_component is ZB001DoctorSkillStomp:
		push_error("%s：必须绑定 ZB001DoctorSkillStomp 效果组件。" % get_path())
		return "技能效果组件类型错误。"
	# 父类已经就地输出错误，本层只转发检查结果。
	var error: String = super.get_configuration_error()
	if not error.is_empty():
		return error
	# 本技能的通用准备入口；首条边必须连接处理踩踏关键帧的动作状态。
	var prepare_state: ZB001DoctorStateSkillPrepare = child_state_machine.initial_state as ZB001DoctorStateSkillPrepare
	if prepare_state == null or prepare_state.skill_state != self:
		push_error("Stomp：入口必须使用自身的通用准备状态。")
		return "脚踩准备状态类型错误。"
	if not prepare_state.next_state is ZB001DoctorStateSkillAction:
		push_error("Stomp：准备入口必须连接技能动作状态。")
		return "脚踩准备状态后续连线错误。"
	return ""
