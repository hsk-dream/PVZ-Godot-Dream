## 脚踩触发要求有植物；准备时目标全部消失则随机踩空，关键帧仍按锁定区域处理碾压。
extends ZB001DoctorSkillAreaCrush
class_name ZB001DoctorSkillStomp

## 攻击范围的行数和列数，默认覆盖 2 行、3 列。
@export var attack_size: Vector2i = Vector2i(2, 3)
## 与状态的动作动画按顺序对应；x 为行、y 为列，均从 1 开始，列按画面从左向右。
@export var animation_top_left_cells: Array[Vector2i] = [
	Vector2i(1, 7),
	Vector2i(2, 7),
	Vector2i(3, 7),
	Vector2i(4, 7),
]


## 只查询有无目标，不抽取随机数、不锁定参数，供主状态机过滤脚踩技能。
func has_available_target() -> bool:
	return not _get_candidates().is_empty()


## 优先选择有植物的完整区域；目标全部消失时从所有完整区域中随机选择，允许踩空。
## 仅战斗已结束、配置无效或没有完整区域时返回空字典，由准备状态结束本轮。
func prepare_parameters() -> Dictionary:
	# 选择技能与进入准备状态之间植物可能已被移除，不能复用之前的可用性结果。
	var candidates: Array[Dictionary] = _get_candidates()
	if candidates.is_empty():
		# 技能已经选中，目标消失不取消动作；仍保留区域越界与关卡生命周期检查。
		candidates = _get_candidates(false)
	if candidates.is_empty():
		return {}
	# 项目统一随机选择器；区域内植物数量不影响区域被抽中的概率。
	var picker := RandomPicker.new(candidates, false)
	return picker.get_random_item()


## 可用性查询和动作准备共用区域检查，仅收集候选，不产生随机选择或攻击副作用。
## [param require_plant] 默认要求区域内有有效植物；仅准备阶段的踩空回退传入 false。
func _get_candidates(require_plant: bool = true) -> Array[Dictionary]:
	# 当前有效战斗的格子管理器，展示、死亡或退出后的实例不准备攻击。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or not get_configuration_error().is_empty():
		return []
	# 只在副本内调整列顺序，避免场景的倒序节点编号改变技能的视觉列号。
	var grid: Array[Array] = _get_visual_grid(manager)
	# 每个候选同时绑定动画和范围，不先选动画再裁剪越界区域。
	var candidates: Array[Dictionary] = []
	# 本次检查的动画数组下标，对应同下标的区域配置。
	for animation_index: int in range(animation_top_left_cells.size()):
		# 当前动画对应的显示行列，左上角坐标从 1 开始。
		var top_left: Vector2i = animation_top_left_cells[animation_index]
		# 始终要求完整矩形；正常筛选还要求有植物，准备阶段回退才允许空区域。
		var cells: Array[PlantCell] = _get_region(grid, top_left, attack_size)
		if not cells.is_empty() and (not require_plant or _has_living_plant(cells)):
			candidates.append({"data": {
				"animation_index": animation_index,
				"animation_variant": animation_index + 1,
				"top_left": top_left,
				"attack_size": attack_size,
				"cells": cells,
			}, "weight": 1.0})
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
	if attack_size.x < 1 or attack_size.y < 1:
		push_error("StompSkill：攻击范围的行数和列数必须为正数。")
		return "脚踩攻击大小无效。"
	if animation_top_left_cells.is_empty():
		push_error("StompSkill：必须配置动画对应的攻击区域。")
		return "脚踩动画区域映射为空。"
	# 当前校验的显示行列坐标；数组索引转换只在格子查询内部进行。
	for top_left: Vector2i in animation_top_left_cells:
		if top_left.x < 1 or top_left.y < 1:
			push_error("StompSkill：攻击区域的左上角行列必须从 1 开始。")
			return "脚踩区域左上角无效。"
	return ""
