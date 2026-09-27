## 砸车与脚踩共用的区域碾压：锁定格子，关键帧读取植物并安全处理各种植层。
extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillAreaCrush


## [param parameters] 准备阶段锁定的区域；在落地时读取植物，一次碾压所有种植层。
func execute(parameters: Dictionary) -> void:
	# 当前关卡用于确认目标仍属于本次战斗，防止离树后的延迟事件执行。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or not parameters.has("cells"):
		return
	# 先收集所有目标植物，再执行可能同步释放其他植物的死亡逻辑。
	var plants: Array = []
	# 用实例 ID 去重，防止跨格植物或共享引用被同一次区域攻击重复处理。
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
