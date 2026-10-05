extends Node
class_name ZombieChooseRowSystem
## 复用平滑选行算法；每个节点独立保存行基础权重和最近两次选择历史。

## 按水陆类型保存初始化时生成的基础权重，数组下标对应场景行号。
var base_weigth_all_type: Dictionary[CharacterRegistry.ZombieRowType, Array] = {}
## 各行距离上一次被选择的次数；只在本实例选择成功后更新。
var last_picked: Array[int] = []
## 各行距离上上次被选择的次数，用于平滑连续选择的分布。
var second_last_picked: Array[int] = []
## 是否完成行配置初始化；技能组件据此避免每次技能都重置历史。
var is_initialized: bool = false


## 根据 [param zombie_rows] 初始化水陆基础权重并清空本实例历史。[br]
## 应只在所属关卡或角色首次使用时调用，不在每次选行前重复调用。
func init_zombie_choose_row_system(zombie_rows: Array[ZombieRow]) -> void:
	# 三种类型的行基础权重均与输入行列表等长。
	var land_weights: Array[float] = []
	var pool_weights: Array[float] = []
	var both_weights: Array[float] = []
	# 当前场景行；无效节点仍保留索引，但对所有类型都禁用。
	for row: ZombieRow in zombie_rows:
		# 同一位置的有效行状态，避免初始化时访问已释放节点。
		var valid_row: bool = is_instance_valid(row) and not row.is_queued_for_deletion()
		land_weights.append(1.0 if valid_row and row.zombie_row_type != CharacterRegistry.ZombieRowType.Pool else 0.0)
		pool_weights.append(1.0 if valid_row and row.zombie_row_type != CharacterRegistry.ZombieRowType.Land else 0.0)
		both_weights.append(1.0 if valid_row else 0.0)
	base_weigth_all_type = {
		CharacterRegistry.ZombieRowType.Land: land_weights,
		CharacterRegistry.ZombieRowType.Pool: pool_weights,
		CharacterRegistry.ZombieRowType.Both: both_weights,
	}
	last_picked.resize(zombie_rows.size())
	last_picked.fill(0)
	second_last_picked.resize(zombie_rows.size())
	second_last_picked.fill(0)
	is_initialized = not zombie_rows.is_empty()


## 记录已选择的零起始行号 [param row_index]，不依赖僵尸是否已经实际创建。
func on_zombie_spawned(row_index: int) -> void:
	if row_index < 0 or row_index >= last_picked.size():
		return
	# 更新每行的选择间隔，保持原有两次历史计算方式。
	for lane: int in range(last_picked.size()):
		last_picked[lane] += 1
		second_last_picked[lane] += 1
	second_last_picked[row_index] = last_picked[row_index]
	last_picked[row_index] = 0


## 计算 [param zombie_row_type] 的平滑权重，不改变历史。[br]
## [param special_base_weight] 非空时必须与行数一致，并与水陆基础限制取交集；0 表示禁用该行。
func calculate_smooth_weights(zombie_row_type: CharacterRegistry.ZombieRowType, special_base_weight: Array = []) -> Array[float]:
	# 返回数组只包含可选择行的非负权重；无可用配置时返回空数组。
	var smooth_weights: Array[float] = []
	if not is_initialized or not base_weigth_all_type.has(zombie_row_type):
		return smooth_weights
	if not special_base_weight.is_empty() and special_base_weight.size() != last_picked.size():
		push_error("ZombieChooseRowSystem：特殊行权重数量必须与实际行数一致。")
		return smooth_weights
	# 当前类型的地形限制，不因传入特殊权重而绕过水陆规则。
	var terrain_weights: Array = base_weigth_all_type[zombie_row_type]
	# 本次有效基础权重及总和，不修改初始化保存的数据。
	var base_weights: Array[float] = []
	var total_base_weight: float = 0.0
	# 当前计算的零起始行号。
	for lane: int in range(last_picked.size()):
		# 特殊权重仅对允许的地形生效，非法或非正权重视为禁用。
		var weight: float = terrain_weights[lane] if special_base_weight.is_empty() else float(special_base_weight[lane])
		if terrain_weights[lane] <= 0.0 or not is_finite(weight) or weight <= 0.0:
			weight = 0.0
		base_weights.append(weight)
		total_base_weight += weight
	if not is_finite(total_base_weight) or total_base_weight <= 0.0:
		return smooth_weights
	# 当前行的历史用于平滑概率；系数 6 保持原算法，并非实际行数。
	for lane: int in range(last_picked.size()):
		if base_weights[lane] <= 0.0:
			smooth_weights.append(0.0)
			continue
		# 当前行的基础概率及最近两次历史对平滑权重的贡献。
		var weight_p: float = base_weights[lane] / total_base_weight
		var p_last: float = (6.0 * last_picked[lane] * weight_p + 6.0 * weight_p - 3.0) / 4.0
		var p_second_last: float = (second_last_picked[lane] * weight_p + weight_p - 1.0) / 4.0
		var combined: float = clampf(p_last + p_second_last, 0.01, 100.0)
		smooth_weights.append(weight_p * combined)
	return smooth_weights


## 为 [param zombie_row_type] 选择行并记录历史；[param special_base_weight] 用于限制本次候选行。[br]
## 未初始化或没有合法行时返回 -1，调用方必须跳过生成，不能作为数组下标使用。
func select_spawn_row(zombie_row_type: CharacterRegistry.ZombieRowType, special_base_weight: Array = []) -> int:
	# 只读计算候选权重，选择成功之后才改变本实例历史。
	var smooth_weights: Array[float] = calculate_smooth_weights(zombie_row_type, special_base_weight)
	var total_weight: float = 0.0
	# 当前候选行的平滑权重。
	for weight: float in smooth_weights:
		total_weight += weight
	if total_weight <= 0.0:
		return -1
	# 累积抽样的随机位置与边界；备用行仅处理浮点累加末位差异。
	var random_weight: float = randf_range(0.0, total_weight)
	var cumulative_weight: float = 0.0
	var last_valid_lane: int = -1
	# 当前抽样行号；跳过零权重，避免随机值为 0 时选中禁用行。
	for lane: int in range(smooth_weights.size()):
		if smooth_weights[lane] <= 0.0:
			continue
		last_valid_lane = lane
		cumulative_weight += smooth_weights[lane]
		if random_weight < cumulative_weight:
			on_zombie_spawned(lane)
			return lane
	if last_valid_lane >= 0:
		on_zombie_spawned(last_valid_lane)
	return last_valid_lane
