## 脚踩复合状态：锁定区域对应的动画，一次动作完成后沿用 Finish 返回待机。
extends ZB001DoctorSkillState
class_name ZB001DoctorStateStomp

## 通用检查负责非循环动画及释放帧，这里检查脚踩专用流程与区域映射。
func get_configuration_error() -> String:
	if not effect_component is ZB001DoctorSkillStomp:
		push_error("%s：必须绑定 ZB001DoctorSkillStomp 效果组件。" % get_path())
		return "技能效果组件类型错误。"
	# 父类已经就地输出错误，本层只转发检查结果。
	var error: String = super.get_configuration_error()
	if not error.is_empty():
		return error
	if not child_state_machine.initial_state is ZB001DoctorStateStompPrepare:
		push_error("Stomp：入口必须使用脚踩专用准备状态。")
		return "脚踩准备状态类型错误。"
	return ""
