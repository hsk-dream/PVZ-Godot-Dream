## 砸车效果：准备时锁定格子并平移整条内侧手臂，落地关键帧碾压目标区域。
extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillThrowRV

## 博士的 Body/BodyCorrect/InnerArm，默认位置为零，动画继续控制其子节点。
@export var inner_arm: Node2D
## 原始动画落点对应的左上角；x 为行、y 为列，均从 1 开始。
@export var reference_top_left: Vector2i = Vector2i(2, 2)
## 攻击范围的行数和列数，默认覆盖 2 行、3 列。
@export var attack_size: Vector2i = Vector2i(2, 3)
## 候选左上角的最小行列，包含边界且从 1 开始。
@export var target_top_left_min: Vector2i = Vector2i(1, 1)
## 候选左上角的最大行列，包含边界；无法容纳完整范围的位置不参与抽取。
@export var target_top_left_max: Vector2i = Vector2i(4, 3)


## 锁定本轮区域但不保存植物；返回空字典时由准备状态结束本轮技能。
func prepare_parameters() -> Dictionary:
	reset_visual_offset()
	# 本博士所在活动关卡的格子管理器，防止展示或死亡实例准备攻击。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or not get_configuration_error().is_empty():
		return {}
	# 行顺序沿用管理器，每行按画面从左到右排序，不改变公共数组。
	var grid: Array[Array] = _get_visual_grid(manager)
	# 基准使用同一种种植定位点，零偏移时完整保留原动画。
	var reference_cells: Array[PlantCell] = _get_region(grid, reference_top_left, Vector2i.ONE)
	if reference_cells.is_empty():
		push_error("ThrowRVSkill：当前关卡不存在配置的基准格子。")
		return {}
	# 仅保存能完整容纳攻击区域的候选；空格子与有植物的格子权重相同。
	var candidates: Array[Dictionary] = []
	# 当前候选的显示行号，上界受实际地图行数约束。
	for row: int in range(target_top_left_min.x, mini(target_top_left_max.x, grid.size()) + 1):
		# 当前候选的显示列号，上界受该行实际列数约束。
		for column: int in range(target_top_left_min.y, mini(target_top_left_max.y, grid[row - 1].size()) + 1):
			# 此次检查的左上角行列，从 1 开始。
			var top_left := Vector2i(row, column)
			if not _get_region(grid, top_left, attack_size).is_empty():
				candidates.append({"data": top_left, "weight": 1.0})
	if candidates.is_empty():
		return {}
	# 使用项目统一选择器，各合法区域具有相同概率。
	var picker := RandomPicker.new(candidates, false)
	# 本次选中的显示行列，整段动画期间保持不变。
	var selected: Vector2i = picker.get_random_item()
	# 锁定格子引用而非植物；落地时再读取格子中的最新植物。
	var cells: Array[PlantCell] = _get_region(grid, selected, attack_size)
	# 初始种植点不随花盆/睡莲的容器位移改变，已包含格子在屋顶上的布局。
	var reference_global: Vector2 = reference_cells[0].plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 目标使用与基准相同的定位点，避免重复添加斜坡高度。
	var target_global: Vector2 = cells[0].plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 在手臂父节点的局部空间求差，兼容博士父级的缩放和旋转。
	var arm_parent := inner_arm.get_parent() as Node2D
	inner_arm.position = arm_parent.to_local(target_global) - arm_parent.to_local(reference_global)
	return {"top_left": selected, "attack_size": attack_size, "cells": cells}


## [param parameters] 准备阶段锁定的区域；在落地时读取植物，一次碾压所有种植层。
func execute(parameters: Dictionary) -> void:
	# 当前关卡用于确认目标仍属于本次战斗，防止离树后的延迟事件执行。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or not parameters.has("cells"):
		return
	# 先收集所有目标植物，再执行可能同步释放其他植物的死亡逻辑。
	var plants: Array = []
	# 用实例 ID 去重，防止跨格植物或共享引用被同一次砸车重复处理。
	var seen_ids: Dictionary[int, bool] = {}
	# 格子也可能已经释放，先保留 Variant，检查后才转换类型。
	for cell_reference: Variant in parameters["cells"]:
		if not is_instance_valid(cell_reference):
			continue
		# 本次目标格子；只读取仍属于当前关卡的有效节点。
		var cell := cell_reference as PlantCell
		if cell == null or cell.is_queued_for_deletion() or not manager.main_game.is_ancestor_of(cell):
			continue
		# 字典中可能含有已释放引用，禁止在有效性检查前赋给植物类型变量。
		for plant_reference: Variant in cell.plant_in_cell.values():
			if not is_instance_valid(plant_reference):
				continue
			# 同一次区域攻击中的植物唯一标识。
			var instance_id: int = plant_reference.get_instance_id()
			if not seen_ids.has(instance_id):
				seen_ids[instance_id] = true
				plants.append(plant_reference)
	# 死亡回调可能释放后续目标，执行前必须再次验证 Variant 引用。
	for plant_reference: Variant in plants:
		if _get_active_manager() != manager:
			return
		if not is_instance_valid(plant_reference):
			continue
		# 有效引用才转换为植物；已死亡、待释放或展示实例不重复碾压。
		var plant := plant_reference as Plant000Base
		if plant != null and plant.is_inside_tree() and not plant.is_queued_for_deletion() \
			and not plant.is_death and plant.character_init_type == Character000Base.E_CharacterInitType.IsNorm:
			plant.be_flattened()


## 正常结束、死亡中断和下一轮准备共用复位入口，不累加上次定位偏移。
func reset_visual_offset() -> void:
	if is_instance_valid(inner_arm):
		inner_arm.position = Vector2.ZERO


## 静态配置在状态机启动时检查；基准格子是否存在则在实际战斗准备时检查。
func get_configuration_error() -> String:
	if not is_instance_valid(inner_arm) or not is_instance_valid(owner) \
		or not owner.is_ancestor_of(inner_arm) or not inner_arm.get_parent() is Node2D:
		push_error("ThrowRVSkill：必须绑定博士自身的 InnerArm，且其父节点为 Node2D。")
		return "砸车手臂绑定无效。"
	if reference_top_left.x < 1 or reference_top_left.y < 1 \
		or attack_size.x < 1 or attack_size.y < 1 \
		or target_top_left_min.x < 1 or target_top_left_min.y < 1 \
		or target_top_left_max.x < target_top_left_min.x or target_top_left_max.y < target_top_left_min.y:
		push_error("ThrowRVSkill：行列从 1 开始，攻击大小必须为正，候选上限不能小于下限。")
		return "砸车格子范围配置无效。"
	return ""


## [param manager] 当前关卡格子管理器；返回独立排序的行数组，不改写公共行列信息。
func _get_visual_grid(manager: PlantCellManager) -> Array[Array]:
	# 行从上到下沿用管理器的顺序，列在副本中按世界 X 排序。
	var grid: Array[Array] = []
	# 当前待复制的原始行数组，不直接在其上排序。
	for source_row: Array in manager.all_plant_cells:
		# 本行有效格子副本；出现失效格子时终止，避免压缩列号导致错位。
		var row: Array[PlantCell] = []
		# 未转换类型的格子引用，保证失效实例不会在赋值时抛错。
		for cell_reference: Variant in source_row:
			if not is_instance_valid(cell_reference) or not cell_reference is PlantCell:
				return []
			# 此格子的原始种植点必须已初始化，不能用动态容器坐标代替。
			var cell := cell_reference as PlantCell
			if cell.is_queued_for_deletion() or not cell.is_inside_tree() \
				or not cell.plant_postion_node_ori_global_position.has(CharacterRegistry.PlacePlantInCell.Norm):
				return []
			row.append(cell)
		row.sort_custom(_is_cell_left_of)
		grid.append(row)
	return grid


## [param left] 待比较的第一个格子。[br]
## [param right] 待比较的第二个格子；返回前者是否在画面左侧。
func _is_cell_left_of(left: PlantCell, right: PlantCell) -> bool:
	return left.global_position.x < right.global_position.x


## [param grid] 按画面行列排序的格子数组。[br]
## [param top_left] 从 1 开始的左上角行列。[br]
## [param size] 区域行数和列数；仅返回完整矩形，越界时返回空数组。
func _get_region(grid: Array[Array], top_left: Vector2i, size: Vector2i) -> Array[PlantCell]:
	# 参数进入数组访问前统一转换为零起始索引。
	var start: Vector2i = top_left - Vector2i.ONE
	# 当前完整区域的格子，只有所有行列均存在时才返回。
	var cells: Array[PlantCell] = []
	if start.x < 0 or start.y < 0 or size.x < 1 or size.y < 1 or start.x + size.x > grid.size():
		return []
	# 本次区域内的零起始行下标。
	for row: int in range(start.x, start.x + size.x):
		if start.y + size.y > grid[row].size():
			return []
		# 本次区域内的零起始列下标。
		for column: int in range(start.y, start.y + size.y):
			cells.append(grid[row][column])
	return cells


## 仅返回本博士所属的有效战斗管理器；展示、死亡、退出及战斗结束后取消技能效果。
func _get_active_manager() -> PlantCellManager:
	# 场景 owner 指向博士，避免依赖 Skills 的固定父子层级。
	var doctor := owner as ZB001Doctor
	if not is_instance_valid(doctor) or doctor.is_death or doctor.is_queued_for_deletion() \
		or not doctor.is_inside_tree() or doctor.character_init_type != Character000Base.E_CharacterInitType.IsNorm:
		return null
	if not is_instance_valid(Global.main_game) or Global.main_game.is_queued_for_deletion() \
		or not Global.main_game.is_ancestor_of(doctor) \
		or Global.main_game.main_game_progress != MainGameManager.E_MainGameProgress.MAIN_GAME:
		return null
	# 当前关卡的格子管理器，离树或正在释放时不再使用。
	var manager: PlantCellManager = Global.main_game.plant_cell_manager
	return manager if is_instance_valid(manager) and manager.is_inside_tree() and not manager.is_queued_for_deletion() else null
