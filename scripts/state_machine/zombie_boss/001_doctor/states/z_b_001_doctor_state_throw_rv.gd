## 砸车复合状态：锁定攻击区域，沿用单次动作流程，所有退出路径都恢复手臂位置。
extends ZB001DoctorSkillState
class_name ZB001DoctorStateThrowRV


## 先锁定区域并定位 InnerArm，再交给 Execute 播放动画；无有效区域时保持空参数。
func prepare_action() -> void:
	selected_animation = &""
	action_parameters.clear()
	# 配置校验已保证组件类型，目标选择与视觉定位均由组件完成。
	var throw_effect := effect_component as ZB001DoctorSkillThrowRV
	action_parameters = throw_effect.prepare_parameters()
	if action_parameters.is_empty():
		return
	selected_animation = action_animations[0]
	action_parameters["animation_variant"] = 1


## 先停止子状态，再恢复定位；死亡中断也必须复位，防止偏移污染后续动画。
func exit() -> void:
	super.exit()
	if is_instance_valid(effect_component) and effect_component is ZB001DoctorSkillThrowRV:
		(effect_component as ZB001DoctorSkillThrowRV).reset_visual_offset()


## 除通用动画校验外，检查砸车专用准备状态、单段动作与效果组件。
func get_configuration_error() -> String:
	# 父级已就地报告通用配置错误，这里只传递结果。
	var error: String = super.get_configuration_error()
	if not error.is_empty():
		return error
	if not effect_component is ZB001DoctorSkillThrowRV:
		push_error("ThrowRV：必须绑定 ZB001DoctorSkillThrowRV 效果组件。")
		return "砸车效果组件类型错误。"
	if not child_state_machine.initial_state is ZB001DoctorStateThrowRVPrepare:
		push_error("ThrowRV：入口必须使用砸车专用准备状态。")
		return "砸车准备状态类型错误。"
	if action_animations.size() != 1:
		push_error("ThrowRV：使用一段基准动画，通过 InnerArm 偏移选择落点。")
		return "砸车必须配置一段动作动画。"
	return (effect_component as ZB001DoctorSkillThrowRV).get_configuration_error()
