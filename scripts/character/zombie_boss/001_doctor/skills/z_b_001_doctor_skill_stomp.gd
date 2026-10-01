## 脚踩触发要求有植物；准备时目标全部消失则随机踩空，关键帧仍按锁定区域处理碾压。
extends ZB001DoctorSkillAreaCrush
class_name ZB001DoctorSkillStomp

## 脚踩动画 1、2 的内侧腿控制器；动画 3、4 使用基类 part_motion 绑定的外侧腿控制器。
@export var inner_leg_motion: ZB001DoctorPartMotion


## 分别保存两条腿的待机位置；控制器目标固定，不在切换脚踩动画时重新绑定或采集位置。
func initialize_skill() -> void:
	super.initialize_skill()
	inner_leg_motion.initialize_motion((owner as ZB001Doctor).state_machine.animation_player)


## [param animation_name] 为准备或校验的动作名；动画 1、2 移动内侧腿，其余动作使用外侧腿。
## 只返回引用，实际开始平移仍等待 0 秒关键帧，校验调用不会改变当前动作。
func get_part_motion_for_animation(animation_name: StringName) -> ZB001DoctorPartMotion:
	if animation_name == &"Zombie_boss_stomp_1" or animation_name == &"Zombie_boss_stomp_2":
		return inner_leg_motion
	return super.get_part_motion_for_animation(animation_name)


## 只查询有无目标，不抽取随机数、不锁定参数，供主状态机过滤脚踩技能。
func can_start() -> bool:
	return not _get_candidates().is_empty()


## 优先选择有植物的完整区域；目标全部消失时从所有完整区域中随机选择，允许踩空。
## 战斗结束、配置无效或没有完整区域时返回空动画名，由准备状态收尾。
func prepare_action() -> StringName:
	_arm_action(&"")
	target_cells.clear()
	# 选择技能与进入准备状态之间植物可能已被移除，不能复用之前的可用性结果。
	var candidates: Array[Dictionary] = _get_candidates()
	if candidates.is_empty():
		# 技能已经选中，目标消失不取消动作；仍保留区域越界与关卡生命周期检查。
		candidates = _get_candidates(false)
	if candidates.is_empty():
		return &""
	# 项目统一随机选择器；区域内植物数量不影响区域被抽中的概率。
	var picker := RandomPicker.new(candidates, false)
	# 当前候选在组件内消费，不把内部候选字典传给状态。
	var selected: Dictionary = picker.get_random_item()
	target_cells.assign(selected["cells"])
	# 动作配置只读；运行时区域由实例保存。
	var action: ZB001DoctorAreaAction = selected["action"]
	target_top_left = action.top_left
	# 动画同时决定内侧腿或外侧腿；基类缓存本次控制器，准备期间不写入任何腿部位置。
	return _arm_position_action(action.animation_name, action.part_position)


## 当前场地的腿部平移参数；攻击区域已经锁定，平移期间不重新选择格子。
func get_part_motion_config() -> ZB001DoctorPartMotionConfig:
	return scene_config.stomp_part_motion if scene_config != null else null


## 可用性查询和动作准备共用区域检查，仅收集候选，不产生随机选择或攻击副作用。
## [param require_plant] 默认要求区域内有有效植物；仅准备阶段的踩空回退传入 false。
func _get_candidates(require_plant: bool = true) -> Array[Dictionary]:
	# 无法准备攻击时返回元素类型明确的空候选池。
	var empty_candidates: Array[Dictionary] = []
	# 当前有效战斗的格子管理器，展示、死亡或退出后的实例不准备攻击。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or not get_configuration_error().is_empty():
		return empty_candidates
	# 只在副本内调整列顺序，避免场景的倒序节点编号改变技能的视觉列号。
	var grid: Array[Array] = ZB001DoctorCellQuery.get_visual_grid(manager)
	# 每个候选同时绑定动画和范围，不先选动画再裁剪越界区域。
	var candidates: Array[Dictionary] = []
	# 每个动作资源同时决定完整矩形与播放动画，过滤时不会失去两者的对应关系。
	for action: ZB001DoctorAreaAction in scene_config.stomp_actions:
		# 当前完整区域；只在技能已经选中后的回退中允许无植物。
		var cells: Array[PlantCell] = ZB001DoctorCellQuery.get_region(grid, action.top_left, action.size)
		if not cells.is_empty() and (not require_plant or _has_living_plant(cells)):
			candidates.append({"data": {"action": action, "cells": cells}, "weight": 1.0})
	return candidates


## [param cells] 待检查的完整攻击区域；任意种植层有正常出战的存活植物即返回 true。
func _has_living_plant(cells: Array[PlantCell]) -> bool:
	# 查询期间不触发死亡回调；格子仍检查生命周期，避免使用待卸载区域。
	for cell: PlantCell in cells:
		if not is_instance_valid(cell) or cell.is_queued_for_deletion() or not cell.is_inside_tree():
			continue
		# 字典可能残留已释放的植物引用，先用 Variant 接收并验证，再转换类型。
		for plant_reference: Variant in cell.plant_in_cell.values():
			if not is_instance_valid(plant_reference):
				continue
			# 与区域碾压执行阶段使用相同的存活与出战类型条件。
			var plant := plant_reference as Plant000Base
			if plant != null and plant.is_inside_tree() and not plant.is_queued_for_deletion() \
				and not plant.is_death and plant.character_init_type == Character000Base.E_CharacterInitType.IsNorm:
				return true
	return false


## 静态参数错误在检测分支报告；具体地图上区域越界时由准备阶段过滤。
func get_configuration_error() -> String:
	# 共享场地配置和技能定位节点先校验，再检查每项脚踩区域。
	var placement_error: String = super.get_configuration_error()
	if not placement_error.is_empty():
		return placement_error
	if not is_instance_valid(inner_leg_motion) or inner_leg_motion == part_motion:
		push_error("%s：脚踩动画 1、2 必须绑定独立的内侧腿平移控制器。" % get_path())
		return "内侧腿平移控制器缺失或重复。"
	# 内侧腿节点的归属与位置有效性由控制器自身报告，外侧腿已经由基类校验。
	var inner_leg_error: String = inner_leg_motion.get_configuration_error(owner)
	if not inner_leg_error.is_empty():
		return inner_leg_error
	if inner_leg_motion.target_node == part_motion.target_node:
		push_error("%s：内侧腿与外侧腿平移控制器必须绑定不同的部件节点。" % get_path())
		return "脚踩腿部平移目标重复。"
	if scene_config.stomp_actions.is_empty():
		push_error("StompSkill：必须配置至少一个区域动作。")
		return "脚踩动作配置为空。"
	# 每项必须完整，不允许缺少资源或非正行列；地图越界由准备阶段排除。
	for action: ZB001DoctorAreaAction in scene_config.stomp_actions:
		if action == null or action.animation_name.is_empty() or not action.part_position.is_finite() \
			or action.top_left.x < 1 or action.top_left.y < 1 or action.size.x < 1 or action.size.y < 1:
			push_error("StompSkill：每项动作必须具有有效动画、有限位置、从 1 开始的左上角和正数范围。")
			return "脚踩动作区域无效。"
	return ""


## 从动作配置返回动画列表，供状态检查释放帧。
func get_action_animations() -> Array[StringName]:
	# 只读副本，配置中缺失项交给组件校验报告。
	var animations: Array[StringName] = []
	# 每项动作的动画名称与范围来自同一资源。
	if scene_config != null:
		# 相同行为动画可以用于多个起始行，释放事件仅按唯一动画校验。
		for action: ZB001DoctorAreaAction in scene_config.stomp_actions:
			if action != null and not animations.has(action.animation_name):
				animations.append(action.animation_name)
	return animations
