## 蹦极在进入动画第 1 秒召唤；播完进入动画后等待本批结束，再播放离开动画。
extends ZB001DoctorSkillState
class_name ZB001DoctorStateBungee

## 通用检查验证进入动画及释放关键帧，专用检查保证准备入口和效果组件匹配。
func get_configuration_error() -> String:
	if not effect_component is ZB001DoctorSkillBungee:
		push_error("%s：必须绑定 ZB001DoctorSkillBungee 效果组件。" % get_path())
		return "技能效果组件类型错误。"
	# 通用检查已在错误位置输出信息，这里只传递结果。
	var error: String = super.get_configuration_error()
	if not error.is_empty():
		return error
	if not child_state_machine.initial_state is ZB001DoctorStateBungeePrepare:
		push_error("Bungee：入口必须使用蹦极专用准备状态。")
		return "蹦极准备状态类型错误。"
	return ""
