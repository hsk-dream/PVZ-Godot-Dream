## 蹦极在进入动画第 1 秒召唤；播完进入动画后等待本批结束，再播放离开动画。
extends ZB001DoctorSkillState
class_name ZB001DoctorStateBungee

## 本批全部死亡或结束偷取后播放的离开动画，不参与 action_animations 的随机选择。
@export var leave_animation: StringName = &"Anim_bungee_1_leave"


## 主层选技能时只检查目标，不消耗随机数或修改手臂位置。
func can_be_selected() -> bool:
	return is_instance_valid(effect_component) and effect_component is ZB001DoctorSkillBungee \
		and (effect_component as ZB001DoctorSkillBungee).has_available_target()


## 准备时锁定连续三列和每列的目标，之后只播放固定进入动画。
func prepare_action() -> void:
	selected_animation = &""
	action_parameters = (effect_component as ZB001DoctorSkillBungee).prepare_parameters()
	if not action_parameters.is_empty():
		selected_animation = action_animations[0]


## 所有退出路径均断开本批监听并复位手臂；已生成的僵尸继续自身行为。
func exit() -> void:
	super.exit()
	if is_instance_valid(effect_component) and effect_component is ZB001DoctorSkillBungee:
		(effect_component as ZB001DoctorSkillBungee).cancel_batch_tracking()
		(effect_component as ZB001DoctorSkillBungee).reset_visual_offset()


## 通用检查验证进入动画及释放关键帧，专用检查保证准备入口和效果组件匹配。
func get_configuration_error() -> String:
	# 通用检查已在错误位置输出信息，这里只传递结果。
	var error: String = super.get_configuration_error()
	if not error.is_empty():
		return error
	if not effect_component is ZB001DoctorSkillBungee:
		push_error("Bungee：必须绑定 ZB001DoctorSkillBungee 效果组件。")
		return "蹦极效果组件类型错误。"
	if not child_state_machine.initial_state is ZB001DoctorStateBungeePrepare:
		push_error("Bungee：入口必须使用蹦极专用准备状态。")
		return "蹦极准备状态类型错误。"
	if action_animations.size() != 1 or action_animations[0] == leave_animation:
		push_error("Bungee：action_animations 只配置进入动画，离开动画必须单独绑定。")
		return "蹦极进入与离开动画配置错误。"
	return (effect_component as ZB001DoctorSkillBungee).get_configuration_error()
