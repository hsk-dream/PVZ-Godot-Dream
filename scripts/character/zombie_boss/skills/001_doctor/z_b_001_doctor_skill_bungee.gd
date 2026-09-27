## 蹦极技能负责连续三列选点、手臂定位和本批实例管理；状态机只等待整批结束。
extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillBungee

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

## 可随机起始列的下限，列号从 1 开始，每组固定覆盖连续三列。
@export_range(1, 3, 1) var start_column_min: int = 1
## 可随机起始列的上限；默认候选为 123、234、345 三组。
@export_range(1, 3, 1) var start_column_max: int = 3
## 原动画对应范围的起始列，默认第 2 列，此时手臂 X 为 0。
@export_range(1, 3, 1) var reference_start_column: int = 2
## 代码只修改此节点的 X，子节点继续由进入和离开动画控制。
@export var inner_arm: Node2D
## 本轮第一列对应的左侧手部连接点，空列跳过后也不改变对应关系。
@export var anchor_left: Marker2D
## 本轮第二列对应的中间手部连接点。
@export var anchor_middle: Marker2D
## 本轮第三列对应的右侧手部连接点。
@export var anchor_right: Marker2D
## 固定三列宽，不通过随机数量删减已选范围中的非空列。
const COLUMN_COUNT: int = 3
## 尚未结束偷取的实例，使用 ID 作为键，信号回调不携带可能已释放的角色引用。
var _pending_zombies: Dictionary[int, Zombie021Bungi] = {}
## 每次准备或取消批次都会递增，旧批次回调不能影响新批次。
var _batch_id: int = 0
## 当前批次阶段；只有 NOT_STARTED 可以响应召唤，取消后恢复为 NOT_STARTED。
var batch_state: BatchState = BatchState.NOT_STARTED


## 技能选择条件只读取目标，不消耗随机数，也不改变手臂位置。
func has_available_target() -> bool:
	return not _collect_ranges().is_empty()


## 在准备阶段抽取一组连续三列，再逐列等权抽取一个格子；无目标返回空字典。
func prepare_parameters() -> Dictionary:
	cancel_batch_tracking()
	reset_visual_offset()
	# 每项包含整组范围与按列分开的目标快照，权重统一为 1。
	var ranges: Array[Dictionary] = _collect_ranges()
	if ranges.is_empty():
		return {}
	# 项目统一选择器，每轮只抽一次整组范围，不逐列拼凑范围。
	var range_picker := RandomPicker.new(ranges, false)
	# 此轮范围从准备到收尾保持不变。
	var selected: Dictionary = range_picker.get_random_item()
	# 每个目标保存格子和原始槽位，空列跳过时不能压缩左、中、右编号。
	var targets: Array[Dictionary] = []
	# 当前列在三列范围内的固定槽位：0 左、1 中、2 右。
	for anchor_index: int in range(COLUMN_COUNT):
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
		targets.append({"cell": cell_picker.get_random_item(), "anchor_index": anchor_index})
	# 原动画与目标范围的第一行格子，仅用于计算横向差值。
	var reference_cell: PlantCell = selected["reference_cell"]
	# 选中范围的首列格子，屋顶高度不会被应用到手臂 Y。
	var start_cell: PlantCell = selected["start_cell"]
	# 使用相同的初始种植点，避免花盆容器移动改变对齐结果。
	var reference_position: Vector2 = reference_cell.plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 目标定位点转换到手臂父级的局部坐标后只取 X。
	var target_position: Vector2 = start_cell.plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]
	# 手臂父级坐标空间兼容博士自身的缩放，不硬编码单列像素宽度。
	var arm_parent := inner_arm.get_parent() as Node2D
	inner_arm.position.x = arm_parent.to_local(target_position).x - arm_parent.to_local(reference_position).x
	return {"start_column": selected["start_column"], "targets": targets}


## [param parameters] 准备时锁定的格子与连接点槽位；仅由进入动画第 1 秒关键帧释放一次。
## 生成前复查目标，空格跳过且不重新随机；重复释放不能清理并重建同一批僵尸。
func execute(parameters: Dictionary) -> void:
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
		for target: Dictionary in parameters.get("targets", []):
			if executing_batch != _batch_id or batch_state != BatchState.SPAWNING:
				return
			if _get_active_manager() != manager:
				break
			# 先使用 Variant 验证格子，避免给类型变量赋入已释放实例。
			var cell_reference: Variant = target.get("cell")
			if not is_instance_valid(cell_reference) or not cell_reference is PlantCell:
				continue
			# 准备时记录的固定槽位，生成失败或空列不会使后面的连接点前移。
			var anchor_index: int = target.get("anchor_index", -1)
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


## 技能正常结束或死亡中断时恢复动画基准位置，Y 始终由原场景保留。
func reset_visual_offset() -> void:
	if is_instance_valid(inner_arm):
		inner_arm.position.x = 0.0


## 场景卸载同样清除对外连接，不将卸载当作整批完成。
func _exit_tree() -> void:
	cancel_batch_tracking()


## 返回带等权权重的完整三列范围；空范围排除，范围中允许存在空列。
func _collect_ranges() -> Array[Dictionary]:
	# 当前角色所属的有效格子管理器。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or start_column_min < 1 or start_column_max > 3 \
		or start_column_min > start_column_max or reference_start_column < 1:
		return []
	# 各行独立排序为画面从左到右，不修改格子管理器的公共数组。
	var grid: Array[Array] = []
	# 原始行引用只读，不在原数组上排序。
	for source_row: Array in manager.all_plant_cells:
		# 当前行有效格子的独立副本，失效格子不能被删除后导致列号压缩。
		var row: Array[PlantCell] = []
		# 可能已释放的格子先检查，再进行类型转换。
		for cell_reference: Variant in source_row:
			if not is_instance_valid(cell_reference) or not cell_reference is PlantCell:
				return []
			# 种植点初始化后才可计算手臂基准。
			var cell := cell_reference as PlantCell
			if not cell.is_inside_tree() or cell.is_queued_for_deletion() \
				or not cell.plant_postion_node_ori_global_position.has(CharacterRegistry.PlacePlantInCell.Norm):
				return []
			row.append(cell)
		row.sort_custom(_is_cell_left_of)
		grid.append(row)
	if grid.is_empty() or grid[0].size() < reference_start_column:
		return []
	# 每个候选只保存一个起始列，天然不会出现非连续的组合。
	var ranges: Array[Dictionary] = []
	# 从 1 开始的范围起始列，默认遍历 1、2、3。
	for start_column: int in range(start_column_min, start_column_max + 1):
		# 范围必须在每一行完整存在，禁止截断成不足三列的范围。
		var complete: bool = true
		# 当前待验证列边界的行数组。
		for row: Array in grid:
			if row.size() < start_column + COLUMN_COUNT - 1:
				complete = false
				break
		if not complete:
			continue
		# 当前范围三列的目标分别存储，后续每列只选一个。
		var columns: Array[Array] = []
		# 整组三列至少要有一个有效目标。
		var has_target: bool = false
		# 当前列使用一起始展示列号，访问数组时减一。
		for column: int in range(start_column, start_column + COLUMN_COUNT):
			# 当前列中可被蹦极偷取的格子，每格只记录一次。
			var cells: Array[PlantCell] = []
			# 当前扫描的行，目标可以出现在任意合法行。
			for row: Array in grid:
				# 该行该列的实际格子，检查管理器是否允许该行生成蹦极。
				var cell: PlantCell = row[column - 1]
				if cell.get_bungi_target() != null \
					and manager.main_game.zombie_manager.can_spawn_skill_zombie(CharacterRegistry.ZombieType.Z021Bungi, cell.row_col.x):
					cells.append(cell)
			has_target = has_target or not cells.is_empty()
			columns.append(cells)
		if has_target:
			ranges.append({"data": {"start_column": start_column, "columns": columns,
				"reference_cell": grid[0][reference_start_column - 1], "start_cell": grid[0][start_column - 1]},
				"weight": 1.0})
	return ranges


## [param left] 左侧候选格子。[br]
## [param right] 右侧候选格子；按世界 X 排序得到画面列号。
func _is_cell_left_of(left: PlantCell, right: PlantCell) -> bool:
	return left.global_position.x < right.global_position.x


## 只允许当前关卡正常战斗中的博士准备或执行技能。
func _get_active_manager() -> PlantCellManager:
	# 技能场景 owner 指向博士，避免依赖固定的 Skills 父层级。
	var doctor := owner as ZB001Doctor
	if not is_instance_valid(doctor) or doctor.is_death or doctor.is_queued_for_deletion() \
		or not doctor.is_inside_tree() or doctor.character_init_type != Character000Base.E_CharacterInitType.IsNorm:
		return null
	if not is_instance_valid(Global.main_game) or Global.main_game.is_queued_for_deletion() \
		or not Global.main_game.is_ancestor_of(doctor) \
		or Global.main_game.main_game_progress != MainGameManager.E_MainGameProgress.MAIN_GAME:
		return null
	# 离树或关卡结束后不再读取格子或创建僵尸。
	var manager: PlantCellManager = Global.main_game.plant_cell_manager
	return manager if is_instance_valid(manager) and manager.is_inside_tree() and not manager.is_queued_for_deletion() else null


## 配置错误在发现处分支报告；返回字符串供状态机停止初始化。
func get_configuration_error() -> String:
	if not is_instance_valid(inner_arm) or not is_instance_valid(owner) \
		or not owner.is_ancestor_of(inner_arm) or not inner_arm.get_parent() is Node2D:
		push_error("BungeeSkill：必须绑定博士自身的 InnerArm，且父节点为 Node2D。")
		return "蹦极手臂配置无效。"
	# 三个定位点必须位于这只博士的手臂下，随同手臂偏移及手指动画移动。
	for anchor: Marker2D in [anchor_left, anchor_middle, anchor_right]:
		if not is_instance_valid(anchor) or not inner_arm.is_ancestor_of(anchor):
			push_error("BungeeSkill：必须分别绑定 InnerArm 下的左、中、右三个手部定位点。")
			return "蹦极绳子定位点配置无效。"
	if anchor_left == anchor_middle or anchor_left == anchor_right or anchor_middle == anchor_right:
		push_error("BungeeSkill：左、中、右定位点不能绑定同一个节点。")
		return "蹦极绳子定位点重复。"
	if start_column_min < 1 or start_column_max > 3 or start_column_min > start_column_max \
		or reference_start_column < 1 or reference_start_column > 3:
		push_error("BungeeSkill：起始列上下限和动画基准列必须位于 1～3，且上限不能小于下限。")
		return "蹦极列范围配置无效。"
	return ""
