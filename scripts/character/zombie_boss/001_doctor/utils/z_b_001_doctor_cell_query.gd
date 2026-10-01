## 博士技能共用的格子查询；只返回本次调用的网格副本，不缓存植物、不修改管理器数组。
extends RefCounted
class_name ZB001DoctorCellQuery


## 返回从上到下、从左到右的画面网格；任一格子失效或种植点未初始化时返回空网格。[br]
## [param manager] 当前关卡的格子管理器；保留原始行顺序，仅在行副本中按世界 X 排序。
static func get_visual_grid(manager: PlantCellManager) -> Array[Array]:
	# 失败时返回类型明确的空结果，不能用不完整网格压缩原有行列编号。
	var empty_grid: Array[Array] = []
	if not is_instance_valid(manager) or not manager.is_inside_tree() or manager.is_queued_for_deletion():
		return empty_grid
	# 当前查询的行副本；场地或植物变化后，下一次调用重新构建。
	var grid: Array[Array] = []
	# 管理器中的原始行只读，禁止直接排序。
	for source_row: Array in manager.all_plant_cells:
		# 当前行的有效格子副本，格子自身仍属于原场景。
		var row: Array[PlantCell] = []
		# 先检查未转换的引用，避免已释放实例在类型赋值时抛错。
		for cell_reference: Variant in source_row:
			if not is_instance_valid(cell_reference) or not cell_reference is PlantCell:
				return empty_grid
			# 原始种植点用于手臂定位；不能用动态植物容器位置替代。
			var cell := cell_reference as PlantCell
			if not cell.is_inside_tree() or cell.is_queued_for_deletion() \
				or not cell.plant_postion_node_ori_global_position.has(CharacterRegistry.PlacePlantInCell.Norm):
				return empty_grid
			row.append(cell)
		row.sort_custom(_is_cell_left_of)
		grid.append(row)
	return grid


## 返回完整矩形的格子副本；区域越界或引用失效时返回空数组，不返回部分区域。[br]
## [param grid] 本次查询的画面网格；[param top_left] 从 1 开始的左上角行列。[br]
## [param size] 区域行数和列数，均须为正数。
static func get_region(grid: Array[Array], top_left: Vector2i, size: Vector2i) -> Array[PlantCell]:
	# 失败结果与成功结果携带相同的元素类型，避免普通 Array 赋值错误。
	var empty_cells: Array[PlantCell] = []
	# 画面行列转为零起始数组索引；Vector2i.x 为行，y 为列。
	var start: Vector2i = top_left - Vector2i.ONE
	if start.x < 0 or start.y < 0 or size.x < 1 or size.y < 1 or start.x + size.x > grid.size():
		return empty_cells
	# 仅所有格子均有效时返回收集结果。
	var cells: Array[PlantCell] = []
	# 本次区域内的零起始行下标。
	for row: int in range(start.x, start.x + size.x):
		if start.y + size.y > grid[row].size():
			return empty_cells
		# 本次区域内的零起始列下标。
		for column: int in range(start.y, start.y + size.y):
			# 网格快照不延长节点寿命，访问前重新确认引用有效。
			var cell_reference: Variant = grid[row][column]
			if not is_instance_valid(cell_reference) or not cell_reference is PlantCell \
				or not cell_reference.is_inside_tree() or cell_reference.is_queued_for_deletion():
				return empty_cells
			cells.append(cell_reference)
	return cells


## 返回指定画面列从上到下的完整格子列表；空网格或任一行缺少该列时返回空数组。[br]
## [param grid] 本次查询的画面网格；[param column] 从 1 开始的列号，不裁剪缺失行。
static func get_column(grid: Array[Array], column: int) -> Array[PlantCell]:
	return get_region(grid, Vector2i(1, column), Vector2i(grid.size(), 1))


## 按世界 X 比较两格的画面顺序；[param left] 和 [param right] 均为已验证的有效格子。
static func _is_cell_left_of(left: PlantCell, right: PlantCell) -> bool:
	return left.global_position.x < right.global_position.x
