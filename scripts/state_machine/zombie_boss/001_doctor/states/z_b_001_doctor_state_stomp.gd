## 脚踩复合状态：锁定区域对应的动画，一次动作完成后沿用 Finish 返回待机。
extends ZB001DoctorSkillState
class_name ZB001DoctorStateStomp


## 无有效植物时不进入主层技能池；只查询目标，不随机选点或改变本轮参数。
func can_be_selected() -> bool:
	# 组件必须有效且映射数量匹配，才能将查询结果对应到实际动作动画。
	var stomp_effect := effect_component as ZB001DoctorSkillStomp
	return is_instance_valid(stomp_effect) \
		and action_animations.size() == stomp_effect.animation_top_left_cells.size() \
		and stomp_effect.has_available_target()


## 同时准备动画与格子快照；植物消失时随机踩空，仅无完整区域或战斗失效时结束本轮。
func prepare_action() -> void:
	selected_animation = &""
	action_parameters.clear()
	# 初始化已校验组件类型，范围选择与合法区域过滤由效果组件负责。
	var stomp_effect := effect_component as ZB001DoctorSkillStomp
	# 运行时编辑映射也不能造成动画越界或把区域与动画错误对应。
	if action_animations.size() != stomp_effect.animation_top_left_cells.size():
		push_error("Stomp：脚踩动画数量必须与区域配置数量一致。")
		return
	action_parameters = stomp_effect.prepare_parameters()
	if action_parameters.is_empty():
		return
	# 准备阶段选出的零起始数组下标，不通过解析动画名称猜测目标行。
	var animation_index: int = action_parameters["animation_index"]
	selected_animation = action_animations[animation_index]


## 通用检查负责非循环动画及释放帧，这里检查脚踩专用流程与区域映射。
func get_configuration_error() -> String:
	# 父类已经就地输出错误，本层只转发检查结果。
	var error: String = super.get_configuration_error()
	if not error.is_empty():
		return error
	if not effect_component is ZB001DoctorSkillStomp:
		push_error("Stomp：必须绑定 ZB001DoctorSkillStomp 效果组件。")
		return "脚踩效果组件类型错误。"
	if not child_state_machine.initial_state is ZB001DoctorStateStompPrepare:
		push_error("Stomp：入口必须使用脚踩专用准备状态。")
		return "脚踩准备状态类型错误。"
	# 类型校验通过后读取动画区域映射，与状态的动画数组一一对应。
	var stomp_effect := effect_component as ZB001DoctorSkillStomp
	if action_animations.size() != stomp_effect.animation_top_left_cells.size():
		push_error("Stomp：脚踩动画数量必须与区域配置数量一致。")
		return "脚踩动画与区域数量不一致。"
	return stomp_effect.get_configuration_error()
