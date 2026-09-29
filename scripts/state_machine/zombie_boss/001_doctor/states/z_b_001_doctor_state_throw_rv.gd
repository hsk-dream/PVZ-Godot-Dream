## 砸车复合状态：锁定攻击区域，沿用单次动作流程，所有退出路径都恢复手臂位置。
extends ZB001DoctorSkillState
class_name ZB001DoctorStateThrowRV

## 除通用动画校验外，检查砸车专用准备状态、单段动作与效果组件。
func get_configuration_error() -> String:
	if not effect_component is ZB001DoctorSkillThrowRV:
		push_error("%s：必须绑定 ZB001DoctorSkillThrowRV 效果组件。" % get_path())
		return "技能效果组件类型错误。"
	# 父级已就地报告通用配置错误，这里只传递结果。
	var error: String = super.get_configuration_error()
	if not error.is_empty():
		return error
	if not child_state_machine.initial_state is ZB001DoctorStateThrowRVPrepare:
		push_error("ThrowRV：入口必须使用砸车专用准备状态。")
		return "砸车准备状态类型错误。"
	return ""
