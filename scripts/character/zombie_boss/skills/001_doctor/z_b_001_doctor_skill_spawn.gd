extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillSpawn
## 放置僵尸效果：准备阶段先选行再选类型，释放关键帧使用手部实时 X 请求管理器创建。

## 博士手指下的生成标记，只在释放时读取全局 X；Y 由目标行出生点提供。
@export var spawn_marker: Marker2D
## 可放置的僵尸类型及随机权重；0 不参与选择，默认只生成普通僵尸。
@export var zombie_type_weights: Dictionary[CharacterRegistry.ZombieType, float] = {
	CharacterRegistry.ZombieType.Z001Norm: 1.0,
}


## 从有对应动画且有兼容僵尸的行中等概率选行，再按权重选择该行的僵尸类型。[br]
## [param allowed_lanes] 放置状态配置的行号集合；无有效组合时返回空字典，交由状态结束技能。
func prepare_parameters(allowed_lanes: Array[int]) -> Dictionary:
	# 本博士所属的活动关卡管理器；死亡、离树或战斗结束后不再准备新动作。
	var manager: ZombieManager = _get_active_manager()
	if manager == null:
		return {}
	# 行号到该行可选类型池的映射；过滤后每个行号只出现一次。
	var lane_pools: Dictionary[int, Array] = {}
	# 动画映射中的候选行号，可能超出当前场景的行数。
	for lane: int in allowed_lanes:
		# 当前行可用的 RandomPicker 输入，包含类型和正且有限的权重。
		var items: Array[Dictionary] = []
		# 配置池中的僵尸类型；每行独立判断水陆适配，避免先选类型造成行选择偏置。
		for zombie_type: CharacterRegistry.ZombieType in zombie_type_weights:
			# 当前类型的选择权重，运行中改成 0 后立即停止参与后续准备。
			var weight: float = zombie_type_weights[zombie_type]
			if is_finite(weight) and weight > 0.0 and manager.can_spawn_skill_zombie(zombie_type, lane):
				items.append({"data": zombie_type, "weight": weight})
		if not items.is_empty():
			lane_pools[lane] = items
	if lane_pools.is_empty():
		return {}
	# 本次先锁定的目标行；每个可用行具有相同概率。
	var selected_lane: int = lane_pools.keys().pick_random()
	# 只包含目标行兼容类型的加权选择器，不使用普通波次的选行与战力系统。
	var picker := RandomPicker.new(lane_pools[selected_lane], false)
	return {"lane": selected_lane, "zombie_type": picker.get_random_item()}


## 释放阶段只使用准备结果，位置 X 此时才采样；管理器统一登记并增加数量。[br]
## [param parameters] 已锁定的行号与僵尸类型；死亡中断、依赖失效或参数缺失时取消创建。
func execute(parameters: Dictionary) -> void:
	# 重查关卡与博士生命周期，避免延迟方法轨道在死亡或退出后补生僵尸。
	var manager: ZombieManager = _get_active_manager()
	if manager == null or not is_instance_valid(spawn_marker) or not spawn_marker.is_inside_tree() \
		or spawn_marker.is_queued_for_deletion() or not parameters.has_all(["lane", "zombie_type"]):
		return
	# 使用动画关键帧对应的手部全局 X，不能沿用 Prepare 时手尚未落下的位置。
	var spawn_x: float = spawn_marker.global_position.x
	manager.create_skill_zombie(parameters["zombie_type"], parameters["lane"], spawn_x)


## 配置错误在博士启动前报告；运行中没有匹配行的情况由准备阶段正常结束技能。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not is_instance_valid(spawn_marker) or not is_instance_valid(owner) or not owner.is_ancestor_of(spawn_marker):
		detected_error = "SpawnSkill 必须绑定博士自身的 Marker2DSpawnZombie。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 初始权重和必须有限且为正，避免技能配置为空或加权选择器溢出。
	var total_weight: float = 0.0
	# 当前校验的类型键，必须是注册表中的有效僵尸。
	for zombie_type: CharacterRegistry.ZombieType in zombie_type_weights:
		if zombie_type == 0 or not Global.character_registry.ZombieInfo.has(zombie_type):
			detected_error = "放置技能包含未注册的僵尸类型。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		# 当前类型的配置权重；负数和非有限值属于错误，0 允许禁用该类型。
		var weight: float = zombie_type_weights[zombie_type]
		if not is_finite(weight) or weight < 0.0:
			detected_error = "放置僵尸权重必须为有限非负数。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		total_weight += weight
	if not is_finite(total_weight) or total_weight <= 0.0:
		detected_error = "放置技能必须配置至少一种正权重僵尸。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
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
