extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillSpawn
## 博士放置技能：独立更新类型权重、战力预算与选行历史，提前准备整批清单，在动画关键帧逐只创建。

## 零起始行号到放置动画的映射；缺失行在准备时排除。
@export var lane_animations: Dictionary[int, StringName] = {}
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
## 放置技能的初始战力预算；不足时自动提高到最低候选战力乘计划数量，相等时不调整。
## 修正只影响当前实例并保留到后续批次，不回写场景文件；与自然波次预算独立。
@export_range(1, 200, 1, "or_greater") var spawn_power_base: int = 4
## 每成功准备多少次放置技能提高一档，至少为 1；不是逐只僵尸累计。
@export_range(1, 100, 1, "or_greater") var spawn_power_growth_interval: int = 3
## 每档增加的整批战力；0 表示保持初始预算，不随使用次数成长。
@export_range(0, 100, 1, "or_greater") var spawn_power_growth_step: int = 3
## 成长后的战力预算上限；低于修正后的初始预算时同步提高，剩余预算不结转到下一批。
@export_range(1, 200, 1, "or_greater") var spawn_power_max: int = 100
@export_group("")

## 博士独立维护的运行时权重；键和值均为整数，普通复制即可隔离修改。
var zombie_weights: Dictionary[CharacterRegistry.ZombieType, int] = CharacterRegistry.ZombieSpawnWeights.duplicate()
## 已成功准备的技能次数；先用于本次权重和战力预算计算，再递增，中断时不回退。
var spawn_skill_use_count: int = 0
## 本次技能的有序清单，每项只保存实际类型 zombie_type 与零起始行号 lane。
var spawn_entries: Array[ZB001DoctorSpawnEntry] = []
## 本批已完整播放的放置动作数；动画结束时推进，释放失败也沿用原有次数规则。
var completed_count: int = 0
## 当前动画绑定的放置任务，重复释放由技能基类阻止。
var _current_entry: ZB001DoctorSpawnEntry
## 博士独立使用的类型随机池，每个名额按最新权重、合法行和剩余战力重建。
var zombie_picker: RandomPicker
## 博士自己的选行实例；首次正式准备时初始化，技能之间保留历史。
@onready var choose_row_system: ZombieChooseRowSystem = get_node_or_null("SpawnChooseRowSystem") as ZombieChooseRowSystem


## 配置全部通过后修正当前实例的最低预算；不累计技能次数，也不准备清单。
## 此处按配置最少数量修正，实际放置时再按合法候选与本批随机数量向上修正。
func initialize_skill() -> void:
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
	# 当前组件支持的行号副本，准备算法不改写映射。
	var allowed_lanes: Array[int] = []
	allowed_lanes.assign(lane_animations.keys())
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
	# 以配置类型的权重抽样；雪橇无可用冰道时可以解析成冰车，不改变原抽样权重。
	var candidates: Array[Dictionary] = []
	# 当前场地合法候选中的最低战力；0 表示尚未找到候选，用于预算修正及名额预留。
	var minimum_power: int = 0
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
			return 0
		minimum_power = actual_power if minimum_power == 0 else mini(minimum_power, actual_power)
		candidates.append({"data": {"zombie_type": actual_type, "row_weights": row_weights, "power": actual_power}, "weight": weight})
	if candidates.is_empty():
		return 0
	# 先按配置确定本批数量，再抬高预算，避免低预算缩减数量或取消整批放置。
	var spawn_count: int = randi_range(spawn_count_min, spawn_count_max)
	_ensure_minimum_spawn_power(minimum_power, spawn_count)
	# 修正初始预算和封顶值后计算成长；本批在使用次数递增前锁定，不结转余额。
	var remaining_power: int = _calculate_spawn_power_limit()
	# 当前计划项序号，用于计算本项之后还需保证的数量。
	for spawn_index: int in range(spawn_count):
		# 后续名额至少需要的预算，保证前面抽到强力僵尸后仍能填满整批清单。
		var reserved_power: int = (spawn_count - spawn_index - 1) * minimum_power
		# 本项能够负担的随机候选；保留各自概率权重，只排除战力超预算的类型。
		var affordable_candidates: Array[Dictionary] = []
		# 已通过场地筛选的候选及其实际生成类型数据。
		for candidate: Dictionary in candidates:
			# 候选数据中的 power 始终对应实际生成类型，不使用替换前类型的战力。
			var candidate_data: Dictionary = candidate["data"]
			if int(candidate_data["power"]) + reserved_power <= remaining_power:
				affordable_candidates.append(candidate)
		if affordable_candidates.is_empty():
			_clear_spawn_data()
			return 0
		# 先过滤再随机，避免对无法负担的类型反复重抽而卡住技能准备。
		zombie_picker = RandomPicker.new(affordable_candidates, false)
		# 已过滤的候选信息，清单只保存类型与行，不保存临时行权重数组。
		var selected: Dictionary = zombie_picker.get_random_item()
		# 本项最终生成类型，与候选中计费的战力一致。
		var selected_type: CharacterRegistry.ZombieType = selected["zombie_type"]
		# 实际类型允许的水陆行分类，交给博士独立的选行系统。
		var row_type: CharacterRegistry.ZombieRowType = Global.character_registry.get_zombie_info(selected_type, CharacterRegistry.ZombieInfoAttribute.ZombieRowType)
		# 本项锁定的零起始行号，播放动画和释放僵尸共用；负数表示选行失败。
		var lane: int = choose_row_system.select_spawn_row(row_type, selected["row_weights"])
		if lane < 0:
			_clear_spawn_data()
			return 0
		spawn_entries.append(ZB001DoctorSpawnEntry.new(selected_type, lane))
		remaining_power -= int(selected["power"])
	spawn_skill_use_count += 1
	return spawn_entries.size()


## 保证初始预算大于等于最低总战力，只向上修正当前实例，不降低后续批次的预算。
## [param minimum_power] 候选中的正数最低战力；准备时必须使用实际合法类型的战力。
## [param spawn_count] 要保证的正数数量；初始化使用最少数量，实际准备使用本批随机数量。
func _ensure_minimum_spawn_power(minimum_power: int, spawn_count: int) -> void:
	# 正好承担所有名额的最低战力即可，预算相等时不额外提高。
	var required_power: int = minimum_power * spawn_count
	spawn_power_base = maxi(spawn_power_base, required_power)
	# 封顶不能压低数量所需的最低预算，否则成长计算后仍可能无法填满清单。
	spawn_power_max = maxi(spawn_power_max, spawn_power_base)


## 按准备前的成功使用次数计算本批战力；不依赖自然波次，也不修改计数。
## 调用前需校验增长间隔并修正最低预算；返回值不超过修正后的最终上限。
func _calculate_spawn_power_limit() -> int:
	# 已完成的增长档数，整数除法使每档覆盖指定数量的技能使用次数。
	@warning_ignore("integer_division")
	var growth_steps: int = spawn_skill_use_count / spawn_power_growth_interval
	return mini(spawn_power_base + growth_steps * spawn_power_growth_step, spawn_power_max)


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
	return _arm_action(lane_animations.get(_current_entry.lane, &""))


## 完整动作结束时推进一次，返回是否还有下一次放置；不在释放关键帧累计。
func complete_action() -> bool:
	completed_count += 1
	return completed_count < spawn_entries.size()


## 清理本轮任务，保留独立权重、使用次数与选行历史。
func cancel_skill() -> void:
	super.cancel_skill()
	_clear_spawn_data()


## 清理尚未执行的本批任务和临时随机池；保留使用次数、运行时权重及选行历史。
func _clear_spawn_data() -> void:
	spawn_entries.clear()
	completed_count = 0
	_current_entry = null
	zombie_picker = null


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
	if lane_animations.is_empty():
		push_error("%s：必须配置行动画映射。" % get_path())
		return "行动画映射为空。"
	# 字典保证键唯一；负行号属于错误，地图缺失的正行号只在准备时排除。
	for lane: int in lane_animations:
		if lane < 0:
			push_error("%s：行动画映射的行号必须非负。" % get_path())
			return "动画行号无效。"
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


## 返回映射中的动画集合，供状态检查资源和方法关键帧。
func get_action_animations() -> Array[StringName]:
	# 只读类型化副本，不允许校验修改技能配置。
	var animations: Array[StringName] = []
	animations.assign(lane_animations.values())
	return animations
