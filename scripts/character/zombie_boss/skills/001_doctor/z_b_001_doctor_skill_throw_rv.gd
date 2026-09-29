## 砸车效果：准备时锁定格子并平移整条内侧手臂，落地关键帧碾压目标区域。
extends ZB001DoctorSkillAreaCrush
class_name ZB001DoctorSkillThrowRV

## 博士的 Body/BodyCorrect/InnerArm，默认位置为零，动画继续控制其子节点。
@export var inner_arm: Node2D
## 同时配置基准动画、基准左上角和范围；本轮随机目标保存在组件实例中。
@export var action: ZB001DoctorAreaAction
## 候选左上角的最小行列，包含边界且从 1 开始。
@export var target_top_left_min: Vector2i = Vector2i(1, 1)
## 候选左上角的最大行列，包含边界；无法容纳完整范围的位置不参与抽取。
@export var target_top_left_max: Vector2i = Vector2i(4, 3)


## 锁定区域并定位手臂；返回动画名，失败时返回空名称，由状态收尾。
func prepare_action() -> StringName:
	_arm_action(&"")
	target_cells.clear()
	reset_visual_offset()
	# 本博士所在活动关卡的格子管理器，防止展示或死亡实例准备攻击。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or not get_configuration_error().is_empty():
		return &""
	# 行顺序沿用管理器，每行按画面从左到右排序，不改变公共数组。
	var grid: Array[Array] = _get_visual_grid(manager)
	# 基准使用同一种种植定位点，零偏移时完整保留原动画。
	var reference_cells: Array[PlantCell] = _get_region(grid, action.top_left, Vector2i.ONE)
	if reference_cells.is_empty():
		push_error("ThrowRVSkill：当前关卡不存在配置的基准格子。")
		return &""
	# 仅保存能完整容纳攻击区域的候选；空格子与有植物的格子权重相同。
	var candidates: Array[Dictionary] = []
	# 当前候选的显示行号，上界受实际地图行数约束。
	for row: int in range(target_top_left_min.x, mini(target_top_left_max.x, grid.size()) + 1):
		# 当前候选的显示列号，上界受该行实际列数约束。
		for column: int in range(target_top_left_min.y, mini(target_top_left_max.y, grid[row - 1].size()) + 1):
			# 此次检查的左上角行列，从 1 开始。
			var top_left := Vector2i(row, column)
			if not _get_region(grid, top_left, action.size).is_empty():
				candidates.append({"data": top_left, "weight": 1.0})
	if candidates.is_empty():
		return &""
	# 使用项目统一选择器，各合法区域具有相同概率。
	var picker := RandomPicker.new(candidates, false)
	# 本次选中的显示行列，整段动画期间保持不变。
	var selected: Vector2i = picker.get_random_item()
	# 锁定格子引用而非植物；落地时再读取格子中的最新植物。
	var cells: Array[PlantCell] = _get_region(grid, selected, action.size)
	# 初始种植点不随花盆/睡莲的容器位移改变，已包含格子在屋顶上的布局。
	var reference_global: Vector2 = reference_cells[0].plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 目标使用与基准相同的定位点，避免重复添加斜坡高度。
	var target_global: Vector2 = cells[0].plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 在手臂父节点的局部空间求差，兼容博士父级的缩放和旋转。
	var arm_parent := inner_arm.get_parent() as Node2D
	inner_arm.position = arm_parent.to_local(target_global) - arm_parent.to_local(reference_global)
	target_top_left = selected
	target_cells = cells
	return _arm_action(action.animation_name)


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
	if action == null:
		push_error("ThrowRVSkill：必须配置区域动作。")
		return "砸车动作配置为空。"
	if action.top_left.x < 1 or action.top_left.y < 1 \
		or action.size.x < 1 or action.size.y < 1 \
		or target_top_left_min.x < 1 or target_top_left_min.y < 1 \
		or target_top_left_max.x < target_top_left_min.x or target_top_left_max.y < target_top_left_min.y:
		push_error("ThrowRVSkill：行列从 1 开始，攻击大小必须为正，候选上限不能小于下限。")
		return "砸车格子范围配置无效。"
	return ""


## 正常收尾和死亡取消都恢复手臂；死亡过渡由取消前取得的位置快照完成。
func cancel_skill() -> void:
	super.cancel_skill()
	reset_visual_offset()


## 返回动作资源中的动画，不再与状态中的另一个数组重复配置。
func get_action_animations() -> Array[StringName]:
	# 显式创建类型化数组，避免三元表达式将数组字面量推导为普通 Array。
	var animations: Array[StringName] = []
	if action != null:
		animations.append(action.animation_name)
	return animations


## 砸车恢复整个手臂局部位置，动画子节点的姿势仍由动画控制器捕获。
func capture_visual_returns() -> Array[ZB001DoctorVisualReturn]:
	# 有效与空结果使用相同的元素类型，供死亡状态直接接收。
	var snapshots: Array[ZB001DoctorVisualReturn] = []
	if is_instance_valid(inner_arm):
		snapshots.append(ZB001DoctorVisualReturn.new(inner_arm, Vector2.ZERO))
	return snapshots
