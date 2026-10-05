## 砸车效果：准备时锁定格子并平移整条内侧手臂，落地关键帧碾压目标区域。
extends ZB001DoctorSkillAreaCrush
class_name ZB001DoctorSkillThrowRV

## 锁定区域并定位手臂；返回动画名，失败时返回空名称，由状态收尾。
## 初始化已验证固定手臂绑定与场地参数，此处只重新检查战斗及当前地图上的完整区域。
func prepare_action() -> StringName:
	_arm_action(&"")
	target_cells.clear()
	reset_visual_offset()
	# 本博士所在活动关卡的格子管理器，防止展示或死亡实例准备攻击。
	var manager: PlantCellManager = _get_active_plant_cell_manager()
	if manager == null:
		return &""
	# 行顺序沿用管理器，每行按画面从左到右排序，不改变公共数组。
	var grid: Array[Array] = ZB001DoctorCellQuery.get_visual_grid(manager)
	# 第 1 行第 1 列与目标使用同一种定位点，资源基准位置已标定原动画的落点。
	var reference_cells: Array[PlantCell] = ZB001DoctorCellQuery.get_region(grid, Vector2i.ONE, Vector2i.ONE)
	if reference_cells.is_empty():
		push_error("ThrowRVSkill：当前关卡不存在第 1 行第 1 列的基准格子。")
		return &""
	# 仅保存能完整容纳攻击区域的候选；空格子与有植物的格子权重相同。
	var candidates: Array[Dictionary] = []
	# 资源中包含边界的候选范围，x 为行、y 为列，均从 1 开始。
	var target_top_left_min: Vector2i = scene_config.throw_rv_top_left_min
	# 越界候选在读取格子前过滤，不能把攻击区域裁剪为不足配置大小。
	var target_top_left_max: Vector2i = scene_config.throw_rv_top_left_max
	# 完整攻击覆盖的行数、列数，默认 2 行 3 列。
	var attack_size: Vector2i = scene_config.throw_rv_size
	# 当前候选的显示行号，上界受实际地图行数约束。
	for row: int in range(target_top_left_min.x, mini(target_top_left_max.x, grid.size()) + 1):
		# 当前候选的显示列号，上界受该行实际列数约束。
		for column: int in range(target_top_left_min.y, mini(target_top_left_max.y, grid[row - 1].size()) + 1):
			# 此次检查的左上角行列，从 1 开始。
			var top_left := Vector2i(row, column)
			if not ZB001DoctorCellQuery.get_region(grid, top_left, attack_size).is_empty():
				candidates.append({"data": top_left, "weight": 1.0})
	if candidates.is_empty():
		return &""
	# 使用项目统一选择器，各合法区域具有相同概率。
	var picker := RandomPicker.new(candidates, false)
	# 本次选中的显示行列，整段动画期间保持不变。
	var selected: Vector2i = picker.get_random_item()
	# 锁定格子引用而非植物；落地时再读取格子中的最新植物。
	var cells: Array[PlantCell] = ZB001DoctorCellQuery.get_region(grid, selected, attack_size)
	# 初始种植点不随花盆/睡莲的容器位移改变，已包含格子在屋顶上的布局。
	var reference_global: Vector2 = reference_cells[0].plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 目标使用与基准相同的定位点，避免重复添加斜坡高度。
	var target_global: Vector2 = cells[0].plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 在手臂父节点的局部空间求差，兼容博士父级的缩放和旋转。
	var arm_parent := position_node.get_parent() as Node2D
	apply_visual_position(scene_config.throw_rv_cell_one_position + arm_parent.to_local(target_global) - arm_parent.to_local(reference_global))
	target_cells = cells
	return _arm_action(ZB001DoctorAnimations.THROW_RV_ANIMATION)


## 静态配置在状态机启动时检查；基准格子是否存在则在实际战斗准备时检查。
func get_configuration_error() -> String:
	# 动画为固定常量；静态场地配置和节点先由基类校验。
	var placement_error: String = super.get_configuration_error()
	if not placement_error.is_empty():
		return placement_error
	if not scene_config.throw_rv_cell_one_position.is_finite() \
		or scene_config.throw_rv_size.x < 1 or scene_config.throw_rv_size.y < 1 \
		or scene_config.throw_rv_top_left_min.x < 1 or scene_config.throw_rv_top_left_min.y < 1 \
		or scene_config.throw_rv_top_left_max.x < scene_config.throw_rv_top_left_min.x \
		or scene_config.throw_rv_top_left_max.y < scene_config.throw_rv_top_left_min.y:
		push_error("ThrowRVSkill：行列从 1 开始，攻击大小必须为正，候选上限不能小于下限。")
		return "砸车格子范围配置无效。"
	return ""


## 砸车只有一个动作，直接返回共享动画常量；场地资源不保存重复动画配置。
func get_action_animations() -> Array[StringName]:
	# 显式创建类型化数组，避免三元表达式将数组字面量推导为普通 Array。
	var animations: Array[StringName] = []
	animations.append(ZB001DoctorAnimations.THROW_RV_ANIMATION)
	return animations
