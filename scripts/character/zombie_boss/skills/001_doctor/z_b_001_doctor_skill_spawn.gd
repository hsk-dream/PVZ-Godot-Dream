extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillSpawn
## 博士放置技能：独立更新类型权重与选行历史，提前准备整批清单，在动画关键帧逐只创建。

## 手指下的生成标记，仅在释放时读取全局 X；Y 使用清单目标行的出生点。
@export var spawn_marker: Marker2D
## 每次技能计划放置的最少数量；死亡等中断可以使实际生成数量少于此值。
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

## 博士独立维护的运行时权重；键和值均为整数，普通复制即可隔离修改。
var zombie_weights: Dictionary[CharacterRegistry.ZombieType, int] = CharacterRegistry.ZombieSpawnWeights.duplicate()
## 已成功准备的技能次数；先用于本次权重计算，再递增，中断时不回退。
var spawn_skill_use_count: int = 0
## 本次技能的有序清单，每项只保存实际类型 zombie_type 与零起始行号 lane。
var spawn_entries: Array[Dictionary] = []
## 博士独立使用的类型随机池，每次准备按最新权重和合法行重建。
var zombie_picker: RandomPicker
## 博士自己的选行实例；首次正式准备时初始化，技能之间保留历史。
@onready var choose_row_system: ZombieChooseRowSystem = get_node_or_null("SpawnChooseRowSystem") as ZombieChooseRowSystem


## 为 [param allowed_lanes] 支持的动画行一次性准备完整清单，返回计划放置数量。[br]
## 无可用组合时返回 0 且不累计技能次数；不会启动自然波次或修改其权重和选行记录。
func prepare_spawn(allowed_lanes: Array[int]) -> int:
	clear_spawn()
	# 当前博士所属的战斗管理器，只读取场地数据和生成合法性。
	var manager: ZombieManager = _get_active_manager()
	if manager == null or not is_instance_valid(choose_row_system):
		return 0
	if spawn_count_min < 1 or spawn_count_max < spawn_count_min:
		return 0
	if not choose_row_system.is_initialized:
		choose_row_system.init_zombie_choose_row_system(manager.all_zombie_rows)
	_update_spawn_weights()
	# 以配置类型的权重抽样；雪橇无可用冰道时可以解析成冰车，不改变原抽样权重。
	var candidates: Array[Dictionary] = []
	# 当前配置类型，每个类型最多贡献一个随机项。
	for zombie_type: CharacterRegistry.ZombieType in zombie_types:
		# 当前类型的有效权重与实际待生成类型。
		var weight: int = zombie_weights.get(zombie_type, 0)
		var actual_type: CharacterRegistry.ZombieType = zombie_type
		if weight <= 0:
			continue
		# 合法行同时满足动画映射、水陆限制和雪橇的冰道要求。
		var row_weights: Array[float] = _get_lane_weights(manager, actual_type, allowed_lanes)
		if zombie_type == CharacterRegistry.ZombieType.Z014Bobsled and not row_weights.has(1.0):
			actual_type = CharacterRegistry.ZombieType.Z013Zamboni
			row_weights = _get_lane_weights(manager, actual_type, allowed_lanes)
		if row_weights.has(1.0):
			candidates.append({"data": {"zombie_type": actual_type, "row_weights": row_weights}, "weight": weight})
	if candidates.is_empty():
		return 0
	zombie_picker = RandomPicker.new(candidates, false)
	# 数量只在本次技能开始时取样，不受自然波次的战力预算限制。
	var spawn_count: int = randi_range(spawn_count_min, spawn_count_max)
	# 当前计划项序号；每一项独立抽类型并依次更新博士的选行历史。
	for _spawn_index: int in range(spawn_count):
		# 已过滤的候选信息，清单只保存类型与行，不保存临时行权重数组。
		var selected: Dictionary = zombie_picker.get_random_item()
		var selected_type: CharacterRegistry.ZombieType = selected["zombie_type"]
		var row_type: CharacterRegistry.ZombieRowType = Global.character_registry.get_zombie_info(selected_type, CharacterRegistry.ZombieInfoAttribute.ZombieRowType)
		var lane: int = choose_row_system.select_spawn_row(row_type, selected["row_weights"])
		if lane < 0:
			clear_spawn()
			return 0
		spawn_entries.append({"zombie_type": selected_type, "lane": lane})
	spawn_skill_use_count += 1
	return spawn_entries.size()


## 按放置技能使用次数更新博士权重；本函数独立于自然波次规则，便于单独调整博士难度。[br]
## 每次从注册表基础值计算，避免重复调用时在已衰减的结果上再次扣减。
func _update_spawn_weights() -> void:
	zombie_weights = CharacterRegistry.ZombieSpawnWeights.duplicate()
	# 前六次技能保持基础权重，之后最多衰减二十档；首次准备使用索引 0。
	var decay_steps: int = clampi(spawn_skill_use_count - 5, 0, 20)
	zombie_weights[CharacterRegistry.ZombieType.Z001Norm] -= decay_steps * 180
	zombie_weights[CharacterRegistry.ZombieType.Z003Cone] -= decay_steps * 150


## 返回 [param index] 对应清单项的独立副本，供状态添加动画参数；越界返回空字典。
func get_spawn_parameters(index: int) -> Dictionary:
	if index < 0 or index >= spawn_entries.size():
		return {}
	return spawn_entries[index].duplicate()


## 清理尚未执行的本批任务和临时随机池；保留使用次数、运行时权重及选行历史。
func clear_spawn() -> void:
	spawn_entries.clear()
	zombie_picker = null


## 使用 [param parameters] 锁定的类型与行创建僵尸，释放时才读取手部 X。[br]
## 关卡结束、博士死亡或雪橇冰道消失时跳过本项，不临时换行或重新抽取。
func execute(parameters: Dictionary) -> void:
	# 重新确认释放时的生命周期，避免迟到方法轨道补生僵尸。
	var manager: ZombieManager = _get_active_manager()
	if manager == null or not is_instance_valid(spawn_marker) or not spawn_marker.is_inside_tree() \
		or spawn_marker.is_queued_for_deletion() or not parameters.has_all(["lane", "zombie_type"]):
		return
	# 类型与行必须和播放中的动画使用同一份准备结果。
	var zombie_type: CharacterRegistry.ZombieType = parameters["zombie_type"]
	var lane: int = parameters["lane"]
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


## 启动前校验博士专属依赖、数量和类型；错误在检测位置报告，不依赖运行中的主场景。
func get_configuration_error() -> String:
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
	if zombie_types.is_empty():
		detected_error = "放置技能必须配置至少一种僵尸类型。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 拒绝重复类型，避免同一类型因重复填写获得额外权重。
	var seen_types: Array[CharacterRegistry.ZombieType] = []
	# 每个类型必须有已注册场景和正的基础权重，特殊蹦极不进入手部放置池。
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
		seen_types.append(zombie_type)
	return ""


## 返回本博士所在战斗的管理器；展示实例、死亡实例及离开关卡后均返回 null。
func _get_active_manager() -> ZombieManager:
	# 技能节点由博士场景持有，使用场景 owner 避免依赖 Skills 节点的固定层级。
	var doctor: ZB001Doctor = owner as ZB001Doctor
	if not is_instance_valid(doctor) or doctor.is_death or doctor.is_queued_for_deletion() \
		or not doctor.is_inside_tree() or doctor.character_init_type != Character000Base.E_CharacterInitType.IsNorm:
		return null
	if not is_instance_valid(Global.main_game) or Global.main_game.is_queued_for_deletion() \
		or not Global.main_game.is_ancestor_of(doctor) \
		or Global.main_game.main_game_progress != MainGameManager.E_MainGameProgress.MAIN_GAME:
		return null
	return Global.main_game.zombie_manager
