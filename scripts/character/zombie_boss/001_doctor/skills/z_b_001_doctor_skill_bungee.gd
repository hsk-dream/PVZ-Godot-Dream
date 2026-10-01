## 蹦极技能按场地资源选择连续列组并管理整批实例；默认覆盖三列，状态机等待整批结束。
extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillBungee

## 本轮固定列组起始列，从 1 开始；取消后为 0。
var selected_start_column: int = 0
## 每列锁定一个格子和原始手指槽位，组件独占此运行时清单。
var targets: Array[ZB001DoctorBungeeTarget] = []

## 本批所有实例均死亡或结束偷取时发出一次，零只生成也立即完成。
signal batch_finished()

## 本轮批次的生命周期；完成状态保留到技能退出，让稍后进入的 Wait 也能读取结果。
enum BatchState {
	## 已准备但尚未收到动画释放关键帧。
	NOT_STARTED,
	## 正在逐个创建实例，此时不能提前宣布整批完成。
	SPAWNING,
	## 创建结束，仍有实例尚未死亡或结束偷取。
	WAITING,
	## 本批已经全部结束，包含释放时没有成功创建任何实例的情况。
	COMPLETED,
}

## 本轮第一列对应的左侧手部连接点，空列跳过后也不改变对应关系。
@export var anchor_left: Marker2D
## 本轮第二列对应的中间手部连接点。
@export var anchor_middle: Marker2D
## 本轮第三列对应的右侧手部连接点。
@export var anchor_right: Marker2D
## 尚未结束偷取的实例，使用 ID 作为键，信号回调不携带可能已释放的角色引用。
var _pending_zombies: Dictionary[int, Zombie021Bungi] = {}
## 每次准备或取消批次都会递增，旧批次回调不能影响新批次。
var _batch_id: int = 0
## 当前批次阶段；只有 NOT_STARTED 可以响应召唤，取消后恢复为 NOT_STARTED。
var batch_state: BatchState = BatchState.NOT_STARTED


## 技能选择条件只读取目标，不消耗随机数，也不改变手臂位置。
func can_start() -> bool:
	return not _collect_ranges().is_empty()


## 抽取配置宽度的连续列组后逐列锁定一个目标；返回固定进入动画，无目标返回空名称。
func prepare_action() -> StringName:
	_arm_action(&"")
	targets.clear()
	cancel_batch_tracking()
	reset_visual_offset()
	# 每项包含整组范围与按列分开的目标快照，权重统一为 1。
	var ranges: Array[Dictionary] = _collect_ranges()
	if ranges.is_empty():
		return &""
	# 项目统一选择器，每轮只抽一次整组范围，不逐列拼凑范围。
	var range_picker := RandomPicker.new(ranges, false)
	# 此轮范围从准备到收尾保持不变。
	var selected: Dictionary = range_picker.get_random_item()
	# 当前列在三列范围内的固定槽位：0 左、1 中、2 右。
	for anchor_index: int in range(scene_config.bungee_column_count):
		# 当前槽位对应的有效格子候选，不依赖最终生成数量。
		var column_cells: Array = selected["columns"][anchor_index]
		if column_cells.is_empty():
			continue
		# 当前列的格子全部等权，与同格植物层数无关。
		var items: Array[Dictionary] = []
		# 此次准备期间仍有效的列内目标引用。
		for cell: PlantCell in column_cells:
			items.append({"data": cell, "weight": 1.0})
		# 每列独立选一个格子，空列不会由其他列补足。
		var cell_picker := RandomPicker.new(items, false)
		targets.append(ZB001DoctorBungeeTarget.new(cell_picker.get_random_item(), anchor_index))
	# 原动画与目标范围的第一行格子，仅用于计算横向差值。
	var reference_cell: PlantCell = selected["reference_cell"]
	# 选中范围的首列格子，屋顶高度不会被应用到手臂 Y。
	var start_cell: PlantCell = selected["start_cell"]
	# 使用相同的初始种植点，避免花盆容器移动改变对齐结果。
	var reference_position: Vector2 = reference_cell.plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 目标定位点转换到手臂父级的局部坐标后只取 X。
	var target_position: Vector2 = start_cell.plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 手臂父级坐标空间兼容博士自身的缩放，不硬编码单列像素宽度。
	var arm_parent := position_node.get_parent() as Node2D
	# 第一列标定位置加横向列差，Y 来自场地配置，不叠加屋顶高度。
	var arm_position: Vector2 = scene_config.bungee_first_column_position
	arm_position.x += arm_parent.to_local(target_position).x - arm_parent.to_local(reference_position).x
	apply_visual_position(arm_position)
	selected_start_column = selected["start_column"]
	return _arm_action(ZB001DoctorAnimations.BUNGEE_ENTER_ANIMATION)


## 消费本轮格子与手指槽位；仅由进入动画第 1 秒关键帧释放。
## 生成前复查目标，空格跳过且不重新随机；重复释放不能清理并重建同一批僵尸。
func _release_action() -> void:
	if batch_state != BatchState.NOT_STARTED:
		return
	batch_state = BatchState.SPAWNING
	# 本次调用对应的批次，用于发现生成过程中发生的死亡或场景中断。
	var executing_batch: int = _batch_id
	# 角色和格子必须属于当前仍在战斗的关卡。
	var manager: PlantCellManager = _get_active_manager()
	if manager != null:
		# 固定的连接点顺序；先保留未转换类型的引用，以便安全跳过已经释放的定位点。
		var anchors: Array = [anchor_left, anchor_middle, anchor_right]
		# 每条快照保存目标格子和原始槽位；其中的节点可能已释放。
		for target: ZB001DoctorBungeeTarget in targets.duplicate():
			if executing_batch != _batch_id or batch_state != BatchState.SPAWNING:
				return
			if _get_active_manager() != manager:
				break
			# 先使用 Variant 验证格子，避免给类型变量赋入已释放实例。
			var cell_reference: Variant = instance_from_id(target.cell_id)
			if not is_instance_valid(cell_reference) or not cell_reference is PlantCell:
				continue
			# 准备时记录的固定槽位，生成失败或空列不会使后面的连接点前移。
			var anchor_index: int = target.anchor_index
			if anchor_index < 0 or anchor_index >= anchors.size() or not is_instance_valid(anchors[anchor_index]):
				continue
			# 本次生成对应的手部定位点，入树前交给蹦极自身持续跟随。
			var anchor: Marker2D = anchors[anchor_index]
			if not anchor.is_inside_tree() or anchor.is_queued_for_deletion():
				continue
			# 每列最多一个锁定格子，生成失败不会补充其他格子。
			var cell := cell_reference as PlantCell
			if cell.is_queued_for_deletion() or not cell.is_inside_tree() \
				or not manager.main_game.is_ancestor_of(cell) or cell.get_bungi_target() == null:
				continue
			manager.main_game.zombie_manager.create_skill_bungi(cell, _track_bungee.bind(executing_batch, anchor))
	if executing_batch != _batch_id or batch_state != BatchState.SPAWNING:
		return
	batch_state = BatchState.WAITING
	_try_finish_batch()


## [param zombie] 尚未入树的实例，先登记再连接，避免遗漏初始化期间的完成事件。[br]
## [param generation] 创建该实例时的批次编号，已取消的批次不再接收实例。[br]
## [param anchor] 该列对应的手部定位点，入树前注入以避免首帧显示完整绳子。
func _track_bungee(zombie: Zombie021Bungi, generation: int, anchor: Marker2D) -> void:
	if batch_state != BatchState.SPAWNING or generation != _batch_id:
		return
	zombie.bungee_anchor = anchor
	# 完成通知统一按实例 ID 去重，不让回调保存角色参数。
	var instance_id: int = zombie.get_instance_id()
	_pending_zombies[instance_id] = zombie
	# 死亡、偷取结束与离树兜底共用相同的幂等处理函数。
	var callback: Callable = _on_bungee_finished.bind(instance_id, generation)
	zombie.signal_steal_finished.connect(callback)
	zombie.signal_character_death.connect(callback)
	zombie.tree_exiting.connect(callback)


## [param instance_id] 发出结束通知的实例 ID。[br]
## [param generation] 通知所属批次；旧批次或重复通知直接忽略。
func _on_bungee_finished(instance_id: int, generation: int) -> void:
	if batch_state not in [BatchState.SPAWNING, BatchState.WAITING] \
		or generation != _batch_id or not _pending_zombies.has(instance_id):
		return
	_disconnect_bungee(instance_id, generation)
	_pending_zombies.erase(instance_id)
	_try_finish_batch()


## 只有整批创建结束后才允许完成；先保存结果再发信号，Wait 可读取提前结束的批次。
func _try_finish_batch() -> void:
	if batch_state != BatchState.WAITING or not _pending_zombies.is_empty():
		return
	batch_state = BatchState.COMPLETED
	batch_finished.emit()


## [param instance_id] 待取消监听的实例 ID。[br]
## [param generation] 连接时的批次，用来重建原 Callable，不影响管理器自身连接。
func _disconnect_bungee(instance_id: int, generation: int) -> void:
	# 字典可能保存已释放引用，必须先以 Variant 检查。
	var zombie_reference: Variant = _pending_zombies.get(instance_id)
	if not is_instance_valid(zombie_reference):
		return
	# 此函数仅处理本批完成连接，不移除僵尸也不提前扣减场上数量。
	var zombie := zombie_reference as Zombie021Bungi
	# 连接和断开使用相同参数，精确匹配该批次的回调。
	var callback: Callable = _on_bungee_finished.bind(instance_id, generation)
	if zombie.signal_steal_finished.is_connected(callback):
		zombie.signal_steal_finished.disconnect(callback)
	if zombie.signal_character_death.is_connected(callback):
		zombie.signal_character_death.disconnect(callback)
	if zombie.tree_exiting.is_connected(callback):
		zombie.tree_exiting.disconnect(callback)


## 中断仅清理监听，已经生成的僵尸继续自身行为；不发出整批完成信号。
func cancel_batch_tracking() -> void:
	batch_state = BatchState.NOT_STARTED
	# 清理上一批全部实例的连接，避免技能退出后旧事件切换博士状态。
	for instance_id: int in _pending_zombies.keys():
		_disconnect_bungee(instance_id, _batch_id)
	_pending_zombies.clear()
	_batch_id += 1


## 场景卸载同样清除对外连接，不将卸载当作整批完成。
func _exit_tree() -> void:
	cancel_skill()


## 返回配置宽度的等权完整列组；默认三列，空范围排除，范围中允许存在空列。
func _collect_ranges() -> Array[Dictionary]:
	# 所有提前退出路径共用的类型化空结果，不返回已经收集的局部网格。
	var empty_ranges: Array[Dictionary] = []
	# 当前角色所属的有效格子管理器。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or scene_config == null:
		return empty_ranges
	# 共用画面行列查询；每次重建网格，植物目标仍在本技能内实时筛选。
	var grid: Array[Array] = ZB001DoctorCellQuery.get_visual_grid(manager)
	if grid.is_empty() or grid[0].is_empty():
		return empty_ranges
	# 每个候选只保存一个起始列，天然不会出现非连续的组合。
	var ranges: Array[Dictionary] = []
	# 从 1 开始的范围起始列，默认遍历 1、2、3。
	for start_column: int in range(scene_config.bungee_start_column_range.x, scene_config.bungee_start_column_range.y + 1):
		# 当前范围各列分别存储目标，后续每列只选一个。
		var columns: Array[Array] = []
		# 任一列不完整时排除整组，不能将地图边缘裁剪为不足配置宽度。
		var complete: bool = true
		# 整组至少要有一个有效目标。
		var has_target: bool = false
		# 当前列使用一起始展示列号，访问数组时减一。
		for column: int in range(start_column, start_column + scene_config.bungee_column_count):
			# 共用查询保持完整列，空列目标与地图缺少该列是两种不同情况。
			var column_cells: Array[PlantCell] = ZB001DoctorCellQuery.get_column(grid, column)
			if column_cells.is_empty():
				complete = false
				break
			# 当前列中可被蹦极偷取的格子，每格只记录一次。
			var cells: Array[PlantCell] = []
			# 当前列各行的格子，按蹦极自身的偷取规则和水陆限制筛选。
			for cell: PlantCell in column_cells:
				if cell.get_bungi_target() != null \
					and manager.main_game.zombie_manager.can_spawn_skill_zombie(CharacterRegistry.ZombieType.Z021Bungi, cell.row_col.x):
					cells.append(cell)
			has_target = has_target or not cells.is_empty()
			columns.append(cells)
		if complete and has_target:
			ranges.append({"data": {"start_column": start_column, "columns": columns,
				"reference_cell": grid[0][0], "start_cell": grid[0][start_column - 1]},
				"weight": 1.0})
	return ranges


## 只允许当前关卡正常战斗中的博士准备或执行技能。
func _get_active_manager() -> PlantCellManager:
	# 公共入口先检查博士与关卡的生命周期，本技能只确认自己的管理器。
	var game: MainGameManager = _get_active_game()
	if game == null:
		return null
	# 管理器正在释放或已离树时不再读取场地及生成对象。
	var manager: PlantCellManager = game.plant_cell_manager
	return manager if is_instance_valid(manager) and manager.is_inside_tree() and not manager.is_queued_for_deletion() else null


## 配置错误在发现处分支报告；返回字符串供状态机停止初始化。
func get_configuration_error() -> String:
	# 唯一的进入和离开动作使用共享常量；这里检查资源及博士自身定位节点。
	var placement_error: String = super.get_configuration_error()
	if not placement_error.is_empty():
		return placement_error
	# 三个定位点必须位于这只博士的手臂下，随同手臂偏移及手指动画移动。
	for anchor: Marker2D in [anchor_left, anchor_middle, anchor_right]:
		if not is_instance_valid(anchor) or not position_node.is_ancestor_of(anchor):
			push_error("BungeeSkill：必须分别绑定 InnerArm 下的左、中、右三个手部定位点。")
			return "蹦极绳子定位点配置无效。"
	if anchor_left == anchor_middle or anchor_left == anchor_right or anchor_middle == anchor_right:
		push_error("BungeeSkill：左、中、右定位点不能绑定同一个节点。")
		return "蹦极绳子定位点重复。"
	if scene_config.bungee_start_column_range.x < 1 \
		or scene_config.bungee_start_column_range.y < scene_config.bungee_start_column_range.x \
		or scene_config.bungee_column_count < 1 or scene_config.bungee_column_count > 3 \
		or not scene_config.bungee_first_column_position.is_finite():
		push_error("BungeeSkill：起始列必须为正且上限不小于下限，覆盖 1～3 列，基准位置必须有限。")
		return "蹦极列范围配置无效。"
	return ""


## 清理本批监听、目标和手臂偏移；已经创建的蹦极继续自身行为。
func cancel_skill() -> void:
	super.cancel_skill()
	cancel_batch_tracking()
	targets.clear()
	selected_start_column = 0


## 返回进入动画，离开动画由等待阶段单独校验且没有释放帧。
func get_action_animations() -> Array[StringName]:
	# 单项列表也显式声明元素类型，避免把普通 Array 交给类型化调用方。
	var animations: Array[StringName] = []
	animations.append(ZB001DoctorAnimations.BUNGEE_ENTER_ANIMATION)
	return animations
