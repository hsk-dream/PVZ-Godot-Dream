## 蹦极在进入动画第 1 秒召唤；播完进入动画后等待本批结束，再播放离开动画。
extends ZB001DoctorSkillState
class_name ZB001DoctorStateBungee

## 通用检查验证进入动画及释放关键帧，本技能检查准备入口归属、进入动作类型和效果组件。
func get_configuration_error() -> String:
	if not effect_component is ZB001DoctorSkillBungee:
		push_error("%s：必须绑定 ZB001DoctorSkillBungee 效果组件。" % get_path())
		return "技能效果组件类型错误。"
	# 通用检查已在错误位置输出信息，这里只传递结果。
	var error: String = super.get_configuration_error()
	if not error.is_empty():
		return error
	# 本技能的通用准备入口；准备完成后必须进入处理释放关键帧的动作状态。
	var prepare_state: ZB001DoctorStateSkillPrepare = child_state_machine.initial_state as ZB001DoctorStateSkillPrepare
	if prepare_state == null or prepare_state.skill_state != self:
		push_error("Bungee：入口必须使用自身的通用准备状态。")
		return "蹦极准备状态类型错误。"
	if not prepare_state.next_state is ZB001DoctorStateSkillAction:
		push_error("Bungee：准备入口必须连接进入动画状态。")
		return "蹦极准备状态后续连线错误。"
	return ""
