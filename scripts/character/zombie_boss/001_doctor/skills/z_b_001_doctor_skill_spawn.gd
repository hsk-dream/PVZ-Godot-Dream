## 博士放置技能：独立更新类型权重、战力预算与选行历史，提前准备整批清单，在动画关键帧逐只创建。
extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillSpawn

## 本技能私有的同步准备候选；保存实际类型与抽样数据，不随放置清单跨帧保存。
class SpawnCandidate extends RefCounted:
	## 已解析雪橇替换后的实际生成类型，战力与选行均以此类型为准。
	var zombie_type: CharacterRegistry.ZombieType
	## 与当前场地行数一致的零起始行权重；合法行为 1，其他行为 0，仅在准备阶段读取。
	var row_weights: Array[float] = []
	## 实际生成类型的正数单体战力，用于最低预算与剩余名额预留。
	var power: int
	## 原配置类型的正数抽样权重；雪橇替换成冰车后仍保留雪橇权重。
	var weight: int

	## 创建准备阶段候选，并将行权重复制到固定类型容器，不共享调用方数组。[br]
	## [param type] 实际生成类型；[param lanes] 零起始行权重。[br]
	## [param zombie_power] 已校验为正数的单体战力；[param selection_weight] 原配置类型的正数抽样权重。
	func _init(type: CharacterRegistry.ZombieType, lanes: Array[float], zombie_power: int, selection_weight: int) -> void:
		zombie_type = type
		row_weights.assign(lanes)
		power = zombie_power
		weight = selection_weight


## 手指下的生成标记，仅在释放时读取全局 X；Y 使用清单目标行的出生点。
@export var spawn_marker: Marker2D
## 每次成功准备的清单最少数量；预算不足时自动抬高，死亡等中断可以使实际生成数量少于此值。
@export_range(1, 20, 1) var spawn_count_min: int = 3
## 每次技能计划放置的最多数量，不得小于最小值。
@export_range(1, 20, 1) var spawn_count_max: int = 5
## 博士允许放置的类型，基础权重统一来自角色注册表，不读取自然出怪列表。
@export var zombie_types: Array[CharacterRegistry.ZombieType] = [
	CharacterRegistry.ZombieType.Z001Norm,
	CharacterRegistry.ZombieType.Z003Cone,
	CharacterRegistry.ZombieType.Z004PoleVaulter,
	CharacterRegistry.ZombieType.Z005Bucket,
]

@export_group("放置战力成长")
## 放置技能的原始初始战力配置；运行时最低预算修正另存，不改写此值。
@export_range(1, 200, 1, "or_greater") var spawn_power_base: int = 4
## 每成功准备多少次放置技能提高一档，至少为 1；不是逐只僵尸累计。
@export_range(1, 100, 1, "or_greater") var spawn_power_growth_interval: int = 3
## 每档增加的整批战力；0 表示保持初始预算，不随使用次数成长。
@export_range(0, 100, 1, "or_greater") var spawn_power_growth_step: int = 3
## 成长后的原始战力上限配置；运行时有效上限可向上修正，剩余预算不结转到下一批。
@export_range(1, 200, 1, "or_greater") var spawn_power_max: int = 100
@export_group("")

## 博士独立维护的运行时权重；键和值均为整数，普通复制即可隔离修改。
var zombie_weights: Dictionary[CharacterRegistry.ZombieType, int] = CharacterRegistry.ZombieSpawnWeights.duplicate()
## 已成功准备的技能次数；先用于本次权重和战力预算计算，再递增，中断时不回退。
var spawn_skill_use_count: int = 0
## 当前实例的有效初始战力预算；0 表示尚未修正，后续初始化与批次准备只允许提高。
var _effective_spawn_power_base: int = 0
## 当前实例的有效战力上限；不低于有效初始预算，取消及清单失败时保留。
var _effective_spawn_power_max: int = 0
## 本次技能的有序清单，每项只保存实际类型 zombie_type 与零起始行号 lane。
var spawn_entries: Array[ZB001DoctorSpawnEntry] = []
## 本批已完整播放的放置动作数；动画结束时推进，释放失败也沿用原有次数规则。
var completed_count: int = 0
## 当前动画绑定的放置任务，重复释放由技能基类阻止。
var _current_entry: ZB001DoctorSpawnEntry
## 博士自己的选行实例；首次正式准备时初始化，技能之间保留历史。
@onready var choose_row_system: ZombieChooseRowSystem = get_node_or_null("SpawnChooseRowSystem") as ZombieChooseRowSystem


## 配置全部通过后修正当前实例的最低预算；不累计技能次数，也不准备清单。
## 此处按配置最少数量修正，实际放置时再按合法候选与本批随机数量向上修正。
func initialize_skill() -> void:
	super.initialize_skill()
	# 已校验配置中的最低战力，不依赖尚未开始的关卡选行过程。
	var minimum_power: int = 0
	# 已验证具有正战力的配置类型；雪橇替换仍在实际准备阶段按冰车计费。
	for zombie_type: CharacterRegistry.ZombieType in zombie_types:
		# 当前配置类型的战力，用于计算首批可承担的最低总战力。
		var power: int = CharacterRegistry.ZombieSpawnPower[zombie_type]
		minimum_power = power if minimum_power == 0 else mini(minimum_power, power)
	_ensure_minimum_spawn_power(minimum_power, spawn_count_min)


## 开始本批放置，权重与预算使用次数只在完整清单成功准备后累计。
func begin_skill() -> bool:
	super.begin_skill()
	return _prepare_spawn() > 0


## 为映射支持的动画行一次性准备完整清单，返回计划放置数量。[br]
## 无可用组合时返回 0 且不累计技能次数；预算不足会自动修正，不修改自然波次数据。
func _prepare_spawn() -> int:
	_clear_spawn_data()
	# 当前博士所属的战斗管理器，只读取场地数据和生成合法性。
	var manager: ZombieManager = _get_active_manager()
	if manager == null or not is_instance_valid(choose_row_system):
		return 0
	if spawn_count_min < 1 or spawn_count_max < spawn_count_min:
		return 0
	if spawn_power_growth_interval < 1 or spawn_power_growth_step < 0:
		return 0
	if not choose_row_system.is_initialized:
		choose_row_system.init_zombie_choose_row_system(manager.all_zombie_rows)
	_update_spawn_weights()
	# 本次允许的动画行副本，不修改导出的映射顺序或内容。
	var allowed_lanes: Array[int] = []
	# 配置行号从 1 开始，只在管理器接口边界转换成零起始下标。
	for row: int in scene_config.spawn_row_actions:
		allowed_lanes.append(row - 1)
	# 先锁定合法候选；此阶段不选行、不消耗抽样随机数。
	var candidates: Array[SpawnCandidate] = _collect_spawn_candidates(manager, allowed_lanes)
	if candidates.is_empty():
		return 0
	# 本批计划数量仍由配置上下限随机确定，不因初始预算较低而缩减。
	var spawn_count: int = randi_range(spawn_count_min, spawn_count_max)
	# 最低战力必须来自最终生成的合法类型，供最低预算修正及后续名额预留。
	var minimum_power: int = _get_minimum_candidate_power(candidates)
	_ensure_minimum_spawn_power(minimum_power, spawn_count)
	# 本次预算在技能次数递增之前计算，修正后的封顶值仍然生效。
	var power_limit: int = _calculate_spawn_power_limit()
	# 临时完整清单；抽样或选行失败时不会将半批任务提交给动画流程。
	var entries: Array[ZB001DoctorSpawnEntry] = _build_spawn_entries(candidates, spawn_count, minimum_power, power_limit)
	if entries.is_empty():
		return 0
	spawn_entries.assign(entries)
	spawn_skill_use_count += 1
	return spawn_entries.size()


## 只读收集合法类型、行权重和战力；不准备任务、不改变选行历史。[br]
## [param manager] 当前关卡僵尸管理器；[param allowed_lanes] 本技能动画支持的零起始行号。[br]
## 雪橇无冰道时沿用原权重替换为冰车，按替换后的实际类型计费；战力配置错误时返回空池。
func _collect_spawn_candidates(manager: ZombieManager, allowed_lanes: Array[int]) -> Array[SpawnCandidate]:
	# 配置错误必须拒绝整个候选池，不能返回已追加的部分类型。
	var empty_candidates: Array[SpawnCandidate] = []
	# 以配置类型的权重抽样；雪橇无可用冰道时可以解析成冰车，不改变原抽样权重。
	var candidates: Array[SpawnCandidate] = []
	# 当前配置类型，每个类型最多贡献一个随机项。
	for zombie_type: CharacterRegistry.ZombieType in zombie_types:
		# 当前类型的有效概率权重，权重不参与战力预算计算。
		var weight: int = zombie_weights.get(zombie_type, 0)
		# 实际待生成的类型，雪橇缺少冰道时替换为冰车。
		var actual_type: CharacterRegistry.ZombieType = zombie_type
		if weight <= 0:
			continue
		# 合法行同时满足动画映射、水陆限制和雪橇的冰道要求。
		var row_weights: Array[float] = _get_lane_weights(manager, actual_type, allowed_lanes)
		if zombie_type == CharacterRegistry.ZombieType.Z014Bobsled and not row_weights.has(1.0):
			actual_type = CharacterRegistry.ZombieType.Z013Zamboni
			row_weights = _get_lane_weights(manager, actual_type, allowed_lanes)
		if not row_weights.has(1.0):
			continue
		# 必须按最终生成类型计费，例如雪橇替换为冰车后使用冰车战力。
		var actual_power: int = CharacterRegistry.ZombieSpawnPower.get(actual_type, 0)
		if actual_power <= 0:
			push_error("%s：放置类型 %s 缺少正数战力配置。" % [get_path(), actual_type])
			return empty_candidates
		candidates.append(SpawnCandidate.new(actual_type, row_weights, actual_power, weight))
	return candidates


## 返回 [param candidates] 中实际生成类型的最低战力；输入由合法候选收集产生，空池返回 0。
func _get_minimum_candidate_power(candidates: Array[SpawnCandidate]) -> int:
	# 首个候选初始化最低值，后续只比较已经验证为正数的战力。
	var minimum_power: int = 0
	# 每项直接保存实际生成类型及其正数战力。
	for candidate: SpawnCandidate in candidates:
		# 候选所代表的实际生成战力，雪橇替换已在收集阶段处理。
		var power: int = candidate.power
		minimum_power = power if minimum_power == 0 else mini(minimum_power, power)
	return minimum_power


## 按预算构建完整清单；任一名额无法抽样或选行时返回空数组，不提交部分任务。[br]
## [param candidates] 已筛选的合法类型；[param spawn_count] 本批计划数量。[br]
## [param minimum_power] 合法候选的最低战力；[param power_limit] 修正及成长后的整批预算。[br]
## 选行仍由博士独立选行系统完成并更新历史；此函数不累计技能次数。
func _build_spawn_entries(candidates: Array[SpawnCandidate], spawn_count: int, minimum_power: int, power_limit: int) -> Array[ZB001DoctorSpawnEntry]:
	# 失败时不返回已准备的部分清单，保持类型明确且避免播放半批任务。
	var empty_entries: Array[ZB001DoctorSpawnEntry] = []
	# 本次局部清单，全部名额完成后由调用方统一提交。
	var entries: Array[ZB001DoctorSpawnEntry] = []
	# 每抽取一项只扣除对应实际战力，未用完的预算不结转到下一批。
	var remaining_power: int = power_limit
	# 当前计划项序号，用于计算本项之后还需保证的数量。
	for spawn_index: int in range(spawn_count):
		# 后续名额至少需要的预算，保证前面抽到强力僵尸后仍能填满整批清单。
		var reserved_power: int = (spawn_count - spawn_index - 1) * minimum_power
		# 后续名额的最低预算不可被本项消耗，候选过滤保留原有概率权重。
		var affordable_candidates: Array[SpawnCandidate] = _get_affordable_candidates(candidates, remaining_power - reserved_power)
		if affordable_candidates.is_empty():
			return empty_entries
		# 先过滤再随机，避免对无法负担的类型反复重抽而卡住技能准备。
		var picker := RandomPicker.new()
		# 按原候选顺序加入并统一重建，保持别名表及每项抽样的随机数消费顺序。
		for candidate: SpawnCandidate in affordable_candidates:
			picker.add_item(candidate, candidate.weight, false, false)
		picker.rebuild_alias_table()
		# 已过滤的候选信息，清单只保存类型与行，不保存临时行权重数组。
		var selected: SpawnCandidate = picker.get_random_item() as SpawnCandidate
		# 本项最终生成类型，与候选中计费的战力一致。
		var selected_type: CharacterRegistry.ZombieType = selected.zombie_type
		# 实际类型允许的水陆行分类，交给博士独立的选行系统。
		var row_type: CharacterRegistry.ZombieRowType = Global.character_registry.get_zombie_info(selected_type, CharacterRegistry.ZombieInfoAttribute.ZombieRowType)
		# 本项锁定的零起始行号，播放动画和释放僵尸共用；负数表示选行失败。
		var lane: int = choose_row_system.select_spawn_row(row_type, selected.row_weights)
		if lane < 0:
			return empty_entries
		entries.append(ZB001DoctorSpawnEntry.new(selected_type, lane))
		remaining_power -= selected.power
	return entries


## 返回 [param candidates] 中实际战力不超过 [param available_power] 的候选副本，保留原抽样权重。[br]
## available_power 已扣除后续名额预留，本函数只筛选、不抽样、不修改输入池。
func _get_affordable_candidates(candidates: Array[SpawnCandidate], available_power: int) -> Array[SpawnCandidate]:
	# 本项可负担的候选；对象只读共享，不改写原候选的数据或权重。
	var affordable_candidates: Array[SpawnCandidate] = []
	# 每个候选对应的战力均已在收集阶段验证为正数。
	for candidate: SpawnCandidate in candidates:
		if candidate.power <= available_power:
			affordable_candidates.append(candidate)
	return affordable_candidates


## 保证有效初始预算大于等于最低总战力，只向上修正当前实例，不改写原始导出配置。
## [param minimum_power] 候选中的正数最低战力；准备时必须使用实际合法类型的战力。
## [param spawn_count] 要保证的正数数量；初始化使用最少数量，实际准备使用本批随机数量。
func _ensure_minimum_spawn_power(minimum_power: int, spawn_count: int) -> void:
	# 正好承担所有名额的最低战力即可，预算相等时不额外提高。
	var required_power: int = minimum_power * spawn_count
	_effective_spawn_power_base = maxi(_effective_spawn_power_base, maxi(spawn_power_base, required_power))
	# 封顶不能压低数量所需的最低预算，否则成长计算后仍可能无法填满清单。
	_effective_spawn_power_max = maxi(_effective_spawn_power_max, maxi(spawn_power_max, _effective_spawn_power_base))


## 按准备前的成功使用次数计算本批战力；不依赖自然波次，也不修改计数。
## 调用前需校验增长间隔并修正最低预算；返回值不超过修正后的最终上限。
func _calculate_spawn_power_limit() -> int:
	# 已完成的增长档数，整数除法使每档覆盖指定数量的技能使用次数。
	@warning_ignore("integer_division")
	var growth_steps: int = spawn_skill_use_count / spawn_power_growth_interval
	return mini(_effective_spawn_power_base + growth_steps * spawn_power_growth_step, _effective_spawn_power_max)


## 按放置技能使用次数更新博士权重；本函数独立于自然波次规则，便于单独调整博士难度。[br]
## 每次从注册表基础值计算，避免重复调用时在已衰减的结果上再次扣减。
func _update_spawn_weights() -> void:
	zombie_weights = CharacterRegistry.ZombieSpawnWeights.duplicate()
	# 前六次技能保持基础权重，之后最多衰减二十档；首次准备使用索引 0。
	var decay_steps: int = clampi(spawn_skill_use_count - 5, 0, 20)
	zombie_weights[CharacterRegistry.ZombieType.Z001Norm] -= decay_steps * 180
	zombie_weights[CharacterRegistry.ZombieType.Z003Cone] -= decay_steps * 150


## 按完整动画结束次数选择本批任务；不重新随机类型或行。
func prepare_action() -> StringName:
	_current_entry = null
	if completed_count >= spawn_entries.size():
		return _arm_action(&"")
	_current_entry = spawn_entries[completed_count]
	# 动画和部件位置来自同一行资源，允许多行复用动画而不复用实际生成行。
	var action: ZB001DoctorRowAction = scene_config.spawn_row_actions.get(_current_entry.lane + 1)
	if action == null:
		return _arm_action(&"")
	return _arm_position_action(action.animation_name, action.part_position)


## 完整动作结束时推进一次，返回是否还有下一次放置；不在释放关键帧累计。
func complete_action() -> bool:
	# 复位由动画关键帧启动，动作状态退出时补齐端点；这里仅推进批次，不重复写位置。
	completed_count += 1
	return completed_count < spawn_entries.size()


## 当前场地的手臂平移参数；使用共享只读资源，不把 Tween 状态写回配置。
func get_part_motion_config() -> ZB001DoctorPartMotionConfig:
	return scene_config.spawn_part_motion if scene_config != null else null


## 清理本轮任务，保留独立权重、使用次数、有效预算与选行历史。
func cancel_skill() -> void:
	super.cancel_skill()
	_clear_spawn_data()


## 清理尚未执行的本批任务；随机池只在准备函数内存在，保留使用次数、权重、有效预算及选行历史。
func _clear_spawn_data() -> void:
	spawn_entries.clear()
	completed_count = 0
	_current_entry = null


## 使用当前任务的类型与行创建僵尸，释放时才读取手部 X。[br]
## 关卡结束、博士死亡或雪橇冰道消失时跳过本项，不临时换行或重新抽取。
func _release_action() -> void:
	# 重新确认释放时的生命周期，避免迟到方法轨道补生僵尸。
	var manager: ZombieManager = _get_active_manager()
	if manager == null or not is_instance_valid(spawn_marker) or not spawn_marker.is_inside_tree() \
		or spawn_marker.is_queued_for_deletion() or _current_entry == null:
		return
	# 类型与行必须和播放中的动画使用同一份准备结果。
	var zombie_type: CharacterRegistry.ZombieType = _current_entry.zombie_type
	var lane: int = _current_entry.lane
	if zombie_type == CharacterRegistry.ZombieType.Z014Bobsled and not _has_ice_road(manager, lane):
		return
	manager.create_skill_zombie(zombie_type, lane, spawn_marker.global_position.x)


## 返回 [param zombie_type] 在 [param manager] 场地中的候选行权重。[br]
## [param allowed_lanes] 来自动画映射；不合法的行权重为 0，合法行为 1。
func _get_lane_weights(manager: ZombieManager, zombie_type: CharacterRegistry.ZombieType, allowed_lanes: Array[int]) -> Array[float]:
	# 与真实场景行数一致，不能把缺失行映射成默认末行。
	var row_weights: Array[float] = []
	row_weights.resize(manager.all_zombie_rows.size())
	row_weights.fill(0.0)
	# 动画支持的零起始行号，逐项检查场景范围和水陆兼容性。
	for lane: int in allowed_lanes:
		if not manager.can_spawn_skill_zombie(zombie_type, lane):
			continue
		if zombie_type == CharacterRegistry.ZombieType.Z014Bobsled and not _has_ice_road(manager, lane):
			continue
		row_weights[lane] = 1.0
	return row_weights


## 检查 [param manager] 的 [param lane] 是否仍有有效冰道，准备和释放阶段共同使用。
func _has_ice_road(manager: ZombieManager, lane: int) -> bool:
	if lane < 0 or lane >= manager.all_ice_roads.size():
		return false
	# 冰道可能已排队销毁，先以 Variant 检查，避免给类型变量赋已释放实例。
	for road in manager.all_ice_roads[lane]:
		if is_instance_valid(road) and road.is_inside_tree() and not road.is_queued_for_deletion():
			return true
	return false


## 只读校验博士专属依赖、数量和类型；预算修正由初始化与批次准备显式执行。
## 错误在检测位置报告，不依赖运行中的主场景；实际合法候选仍在准备时重新判断。
func get_configuration_error() -> String:
	# 基类先检查共享资源和博士自身的定位节点，错误已在发现处报告。
	var placement_error: String = super.get_configuration_error()
	if not placement_error.is_empty():
		return placement_error
	# 行号、动画与位置统一由场地资源校验；实际地图缺失的行在候选阶段过滤。
	var row_error: String = scene_config.get_row_actions_error(scene_config.spawn_row_actions, str(get_path()))
	if not row_error.is_empty():
		return row_error
	# 当前检测分支的错误文本，在发现问题的位置报告，方便定位场景配置。
	var detected_error: String = ""
	if not is_instance_valid(spawn_marker) or not is_instance_valid(owner) or not owner.is_ancestor_of(spawn_marker):
		detected_error = "SpawnSkill 必须绑定博士自身的 Marker2DSpawnZombie。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(choose_row_system) or choose_row_system.get_parent() != self:
		detected_error = "SpawnSkill 必须配置独立的 SpawnChooseRowSystem 子节点。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if spawn_count_min < 1 or spawn_count_max < spawn_count_min:
		detected_error = "放置数量必须满足 1 <= spawn_count_min <= spawn_count_max。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if spawn_power_growth_interval < 1 or spawn_power_growth_step < 0:
		detected_error = "放置战力的增长间隔必须 >= 1，增长量必须 >= 0。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if zombie_types.is_empty():
		detected_error = "放置技能必须配置至少一种僵尸类型。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 拒绝重复类型，避免同一类型因重复填写获得额外权重。
	var seen_types: Array[CharacterRegistry.ZombieType] = []
	# 每个类型必须有已注册场景、正的基础权重及战力，特殊蹦极不进入手部放置池。
	for zombie_type: CharacterRegistry.ZombieType in zombie_types:
		if not CharacterRegistry.ZombieInfo.has(zombie_type) or not CharacterRegistry.ZombieSpawnWeights.has(zombie_type):
			detected_error = "放置类型必须同时具有角色注册信息和基础出怪权重。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		if seen_types.has(zombie_type):
			detected_error = "放置技能的僵尸类型不能重复。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		if CharacterRegistry.ZombieSpawnWeights[zombie_type] <= 0:
			detected_error = "放置技能的基础出怪权重必须为正数。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		# 每只候选的公共战力；缺失条目按 0 拒绝，不默认为普通僵尸战力。
		var configured_power: int = CharacterRegistry.ZombieSpawnPower.get(zombie_type, 0)
		if configured_power <= 0:
			detected_error = "放置技能的每种僵尸必须配置正数战力。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		if zombie_type == CharacterRegistry.ZombieType.Z014Bobsled \
			and CharacterRegistry.ZombieSpawnPower.get(CharacterRegistry.ZombieType.Z013Zamboni, 0) <= 0:
			detected_error = "雪橇的冰车替换类型必须配置正数战力。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		seen_types.append(zombie_type)
	return ""


## 返回本博士所在战斗的管理器；展示实例、死亡实例及离开关卡后均返回 null。
func _get_active_manager() -> ZombieManager:
	# 公共入口先检查博士与关卡的生命周期，本技能只确认自己的管理器。
	var game: MainGameManager = _get_active_game()
	if game == null:
		return null
	# 管理器正在释放或已离树时不再读取场地及生成对象。
	var manager: ZombieManager = game.zombie_manager
	return manager if is_instance_valid(manager) and manager.is_inside_tree() and not manager.is_queued_for_deletion() else null


## 返回行映射中首次出现的动画集合；场地资源统一查询，供状态检查资源和方法关键帧。
func get_action_animations() -> Array[StringName]:
	if scene_config != null:
		return scene_config.get_row_action_animations(scene_config.spawn_row_actions)
	# 未绑定场地资源时仍返回元素类型明确的新空列表，保持状态层的返回约定。
	var empty_animations: Array[StringName] = []
	return empty_animations
