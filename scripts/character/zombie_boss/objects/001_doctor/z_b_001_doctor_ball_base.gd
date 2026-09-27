@abstract
extends Node2D
class_name ZB001DoctorBallBase
## 博士冰火球共用基类：成形后沿目标行滚动并碾压植物和小推车，离场或被对应植物消除时销毁。
## 根节点代表落地点，Body 的静态偏移负责将导入动画对齐到该位置。

## 球自身的生命周期，独立于博士的技能状态机。
enum Phase {
	Inactive, ## 尚未通过 launch() 初始化，不播放或移动。
	Forming, ## 在 Items 下以 4001 层播放成形动画，不启用移动、攻击或地面轨迹。
	Rolling, ## 循环播放滚动动画，沿目标行移动并碾压植物和小推车。
	Removed, ## 已提交释放，忽略后续动画完成通知。
}

## 球每秒向左移动的像素数，必须为有限正数；不跟随博士的减速或冰冻。
@export_range(1.0, 1000.0, 1.0, "or_greater") var move_speed: float = 20.0
## 全局 X 小于等于此值时销毁，单位为像素；默认在场景左侧外清理。
@export var despawn_x: float = -300.0
## 地面轨迹相对球落地点的像素偏移，默认零偏移，与球落地点重合。[br]
## 正 X 位于向左滚动的球后方，Y 叠加在发射点自身的坡面高度上。
@export var ground_particle_offset: Vector2 = Vector2.ZERO
## 仅滚动动画使用的播放倍率，默认 0.1 为原速的十分之一；1 为原速，必须为有限正数。[br]
## 滚动期间赋值立即生效；成形期间只保存配置，进入滚动时应用。[br]
## 成形动画固定为原速，移动速度由 move_speed 决定，最终播放速度仍受全局时间倍率影响。
@export_range(0.01, 10.0, 0.01, "or_greater") var roll_animation_speed_scale: float = 0.1:
	set(value):
		# value 为新的动画倍率；拒绝非法值并保留已有速度，在实际检测处报告错误。
		if not is_finite(value) or value <= 0.0:
			push_error("ZB001DoctorBallBase：roll_animation_speed_scale 必须为有限正数。")
			return
		roll_animation_speed_scale = value
		# 场景属性可能在入树前或成形时赋值，只有正在滚动时才同步播放器。
		if is_instance_valid(animation_player) and _phase == Phase.Rolling:
			animation_player.speed_scale = value
## 球自身的动画播放器；成形使用原速，滚动使用 roll_animation_speed_scale。
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
## 滚动阶段检测植物实际受击区域和小推车区域；直属球根节点，不随身体动画旋转或缩放。
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D
## 成形时保留在球下，开始滚动前独立移到 Items；球释放后粒子自行完成淡出。
@onready var ground_particles: ZB001DoctorGroundParticles = get_node_or_null("GroundParticles") as ZB001DoctorGroundParticles

## 本球锁定的目标行号，从 0 开始；未发射时为 -1。
var lane: int = -1
## 当前生命周期阶段，初始化后只允许成形、滚动、销毁的单向切换。
var _phase: Phase = Phase.Inactive
## 目标行不含坡面偏移的全局 Y，发射时从行出生点读取。
var _ground_y: float = 0.0
## 发射关卡的坡面引用；平地场景为 null，不通过博士对象获取后续移动信息。
var _slope: MainGameSlope
## 球所属关卡的 Items 节点，成形结束时将轨迹独立挂到此处，避免引用新关卡。
var _rolling_root: Node2D


## 具体球类型，必须与技能参数使用的 Ice 或 Fire 一致。
@abstract func get_ball_type() -> StringName

## 具体球的一次性成形动画名称。
@abstract func get_form_animation() -> StringName

## 具体球的循环滚动动画名称，沿用现有资源中的 role 拼写。
@abstract func get_roll_animation() -> StringName

## 行与位置初始化完成后订阅克制事件；由子类选择对应的植物技能。
@abstract func _subscribe_counter_events() -> void

## 取消子类的克制事件订阅；销毁和退出场景都会调用，必须允许重复取消。
@abstract func _unsubscribe_counter_events() -> void


## 入树后等待技能显式发射，避免尚未配置行与位置就播放动画。
func _ready() -> void:
	set_physics_process(false)
	if is_instance_valid(attack_area):
		# 入树可能发生在物理回调中，延迟修改检测开关；成形期间始终不处理攻击。
		attack_area.set_deferred("monitoring", false)
	if is_instance_valid(animation_player):
		animation_player.speed_scale = 1.0
		animation_player.animation_finished.connect(_on_animation_finished)


## 在挂载到 Items 后调用，成功后开始成形；失败返回 false，由调用者释放。[br]
## 成形时使用独立层级 4001，成形结束后按目标行调整层级，球始终留在 Items 下。[br]
## [param game] 本球所属的主游戏，提供行出生点与屋顶坡面。[br]
## [param target_lane] 准备阶段锁定的行号，从 0 开始。[br]
## [param spawn_x] 释放关键帧处嘴部标记的全局 X，不使用嘴部 Y。
func launch(game: MainGameManager, target_lane: int, spawn_x: float) -> bool:
	if _phase != Phase.Inactive or not is_node_ready() or is_queued_for_deletion() \
		or not is_instance_valid(game) or not is_finite(spawn_x):
		return false
	if not is_instance_valid(game.zombie_manager) or target_lane < 0 \
		or target_lane >= game.zombie_manager.all_zombie_rows.size():
		return false
	if not is_instance_valid(game.items) or not game.items.is_inside_tree() or game.items.is_queued_for_deletion():
		return false
	# 当前目标行，只读取出生基准，球不会注册成僵尸或增加僵尸数量。
	var row: ZombieRow = game.zombie_manager.all_zombie_rows[target_lane]
	if not is_instance_valid(row) or not is_instance_valid(row.zombie_create_position):
		return false
	# 动画与移动配置必须有效，防止生成后永远停留在成形阶段。
	var error: String = get_configuration_error()
	if not error.is_empty():
		push_error("ZB001DoctorBallBase：" + error)
		return false
	lane = target_lane
	_ground_y = row.zombie_create_position.global_position.y
	_slope = game.main_game_slope
	_rolling_root = game.items
	global_position = Vector2(spawn_x, _get_ground_y(spawn_x))
	if not global_position.is_finite():
		return false
	# 成形时固定显示在 4001 层，不叠加 Items 的层级；轨迹仍是球的子节点且不发射。
	z_as_relative = false
	z_index = 4001
	_phase = Phase.Forming
	# 成形与滚动都可以被克制；事件回调不依赖球的物理更新，不回放生成前的技能。
	_subscribe_counter_events()
	# 成形时始终使用原速，不受滚动动画倍率影响。
	animation_player.speed_scale = 1.0
	animation_player.play(get_form_animation())
	# 立即应用首帧，避免生成当帧显示编辑器保存的滚动姿态。
	animation_player.advance(0.0)
	# 成形期间保持物理更新关闭；动画播放器独立运行，完成信号负责开启滚动。
	return true


## 仅滚动阶段启用：处理物理系统已更新的重叠结果，再推进根节点并重算坡面 Y。[br]
## [param delta] 当前物理帧经过的秒数，已包含引擎全局时间倍率。
func _physics_process(delta: float) -> void:
	if _phase != Phase.Rolling or is_queued_for_deletion():
		return
	if global_position.x <= despawn_x:
		_remove_from_scene()
		return
	# 重叠列表按物理步更新；持续查询也能处理开启检测时已经重叠或刚补种的植物。
	_crush_overlapping_targets()
	if _phase != Phase.Rolling or is_queued_for_deletion():
		return
	# 本帧球落地点的全局 X，不继承博士后续的移动或动画倍率。
	var next_x: float = global_position.x - move_speed * delta
	global_position = Vector2(next_x, _get_ground_y(next_x))
	_update_ground_particle_position()
	if global_position.x <= despawn_x:
		_remove_from_scene()


## 仅成形动画正常结束时开始滚动，循环动画不承担离场销毁逻辑。[br]
## [param animation_name] 自身播放器的完成通知，不接收博士的动画事件。
func _on_animation_finished(animation_name: StringName) -> void:
	if _phase == Phase.Forming and not is_queued_for_deletion() and animation_name == get_form_animation():
		# 原关卡退出时不再启动滚动，也不能把球挂到另一个关卡。
		if not is_instance_valid(_rolling_root) or not _rolling_root.is_inside_tree() or _rolling_root.is_queued_for_deletion():
			_remove_from_scene()
			return
		# 行号从 0 开始，第一行为 50；独立层级避免父节点 z_index 再次叠加。
		z_as_relative = false
		z_index = (lane + 1) * 50
		if is_instance_valid(ground_particles) and not ground_particles.is_queued_for_deletion():
			# 粒子在首次发射前脱离球，后续不随球释放而突然消失；第一行层级为 0，每行增加 50。
			ground_particles.reparent(_rolling_root, true)
			ground_particles.z_as_relative = false
			ground_particles.z_index = lane * 50
		_phase = Phase.Rolling
		# 成形结束后再应用滚动倍率，移动与攻击仍按各自逻辑更新。
		animation_player.speed_scale = roll_animation_speed_scale
		animation_player.play(get_roll_animation())
		# 成形阶段不产生轨迹；先将发射点对齐地面，再开始留下碎屑。
		_update_ground_particle_position()
		if is_instance_valid(ground_particles) and not ground_particles.is_queued_for_deletion():
			ground_particles.start_emitting()
		# 等待物理系统建立重叠列表后，由后续物理帧统一攻击，不在开关切换时立即查询。
		attack_area.set_deferred("monitoring", true)
		set_physics_process(true)


## 同行小推车直接碾压，植物按整格处理；每步格子去重，不跨帧缓存以允许碾压新种植物。
func _crush_overlapping_targets() -> void:
	if not is_instance_valid(attack_area) or not attack_area.monitoring:
		return
	# 本次物理更新已经处理的格子，避免花盆、普通植物和南瓜同时重叠时重复遍历。
	var processed_cells: Array[PlantCell] = []
	# 上次物理同步的区域引用可能随植物死亡失效；先用 Variant 接收，避免强类型赋值先于有效性检查。
	for area_reference: Variant in attack_area.get_overlapping_areas():
		if _phase != Phase.Rolling or is_queued_for_deletion():
			return
		if not is_instance_valid(area_reference):
			continue
		# 仅将仍存活的引用转换为区域节点，再读取 owner 和删除状态。
		var area: Area2D = area_reference as Area2D
		if area == null or area.is_queued_for_deletion():
			continue
		# 小推车复用现有 Area2D 作为受击区域；只销毁同行的有效原车，球继续滚动。
		if area.owner is LawnMover:
			# 三种小推车共用的碾压入口，不要求小推车已经启动。
			var mower: LawnMover = area.owner as LawnMover
			if mower.is_inside_tree() and not mower.is_queued_for_deletion() \
				and not mower.is_destroyed and mower.lane == lane:
				mower.be_flattened()
			continue
		# 受击区域所属的植物，沿用现有子弹从 owner 获取角色的方式。
		var plant: Plant000Base = area.owner as Plant000Base
		if not _can_crush_plant(plant):
			continue
		# 命中任意一层后处理其整个格子，行号再校验一次以防无效格子引用。
		var cell: PlantCell = plant.plant_cell
		if not is_instance_valid(cell) or cell.is_queued_for_deletion() or cell.row_col.x != lane \
			or processed_cells.has(cell):
			continue
		processed_cells.append(cell)
		_crush_cell(cell)


## 判断植物当前是否允许被本球碾压，不给相邻行、预览角色或死亡角色施加效果。[br]
## [param plant] 待检查植物；无效引用、待删除和受击组件关闭时返回 false。
func _can_crush_plant(plant: Plant000Base) -> bool:
	return is_instance_valid(plant) and plant.is_inside_tree() and not plant.is_queued_for_deletion() \
		and not plant.is_death and plant.lane == lane \
		and plant.character_init_type == Character000Base.E_CharacterInitType.IsNorm \
		and is_instance_valid(plant.hurt_box_component) and plant.hurt_box_component.is_enabling


## 碾压命中格子的全部有效植物层，复用现有压扁外观、死亡信号和格子清理流程。[br]
## [param cell] 已通过行号检查的目标格子；植物死亡时允许其字典同步变化。
func _crush_cell(cell: PlantCell) -> void:
	# values() 只固定遍历列表，不延长植物的生命周期；其中仍可能含有已释放的引用。
	var plants: Array = cell.plant_in_cell.values()
	# 先保留为 Variant，避免已释放引用在进入循环体前赋给 Plant000Base 时直接报错。
	for plant_reference: Variant in plants:
		# 植物死亡可能同步触发克制事件并移除本球，此时不能继续碾压下一层植物。
		if _phase != Phase.Rolling or is_queued_for_deletion():
			return
		if not is_instance_valid(plant_reference):
			continue
		# 有效性检查通过后才转换类型；后续判断仍负责排除死亡或待删除植物。
		var plant: Plant000Base = plant_reference as Plant000Base
		if _can_crush_plant(plant):
			# 使用无攻击者的压扁入口；冰火球不触发地刺针对角色攻击者的反击规则。
			plant.be_flattened()


## 被对应植物技能消除；仅成形和滚动阶段生效，重复通知或待删除时忽略。
func dispel() -> void:
	if not is_inside_tree() or is_queued_for_deletion() \
		or (_phase != Phase.Forming and _phase != Phase.Rolling):
		return
	_remove_from_scene()


## 离场或被消除时先关闭行为，再排队释放；延迟关闭区域，避免在物理同步期间修改检测状态。
func _remove_from_scene() -> void:
	if _phase == Phase.Removed:
		return
	# 必须先切换阶段，保证同步植物死亡事件返回后，当前碾压循环立即停止。
	_phase = Phase.Removed
	set_physics_process(false)
	_unsubscribe_counter_events()
	_stop_ground_particles()
	if is_instance_valid(animation_player):
		animation_player.stop()
	if is_instance_valid(attack_area):
		attack_area.set_deferred("monitoring", false)
	queue_free()


## 切换关卡等直接卸载也要清理事件订阅及其元数据，不依赖正常销毁入口。
func _exit_tree() -> void:
	# 单独卸载球也要停止已经挂到 Items 的发射器；整个关卡卸载时由父节点一并释放。
	_stop_ground_particles()
	# 退出整个游戏时自动加载节点可能已释放，此时无需再访问事件总线。
	if is_instance_valid(EventBus):
		_unsubscribe_counter_events()


## 只移动发射器，世界坐标下已经留下的粒子保持原位；发射点使用自身 X 查询坡面。
func _update_ground_particle_position() -> void:
	if not is_instance_valid(ground_particles) or ground_particles.is_queued_for_deletion():
		return
	# 带偏移的发射横坐标，跨坡段时不能直接沿用球所在点的高度。
	var emission_x: float = global_position.x + ground_particle_offset.x
	ground_particles.global_position = Vector2(emission_x, _get_ground_y(emission_x) + ground_particle_offset.y)


## 正常离场、被植物消除或直接卸载时统一停止发射，允许已有轨迹完成淡出。
func _stop_ground_particles() -> void:
	if is_instance_valid(ground_particles) and ground_particles.is_inside_tree() \
		and not ground_particles.is_queued_for_deletion():
		ground_particles.stop_and_release()


## 返回当前 X 对应的地面全局 Y；平地没有坡面时直接使用行出生点高度。[br]
## [param global_x] 球落地点当前的全局 X。
func _get_ground_y(global_x: float) -> float:
	return _ground_y + (_slope.get_all_slope_y(global_x) if is_instance_valid(_slope) else 0.0)


## 检查子类动画、移动参数与攻击区域，避免错误场景静默留在战场中。
func get_configuration_error() -> String:
	if not ground_particle_offset.is_finite():
		return "地面粒子偏移必须为有限坐标。"
	if not is_instance_valid(ground_particles) or ground_particles.texture == null \
		or ground_particles.process_material == null or ground_particles.local_coords or ground_particles.one_shot:
		return "GroundParticles 必须配置地面贴图与处理材质，使用世界坐标和持续发射模式。"
	if not is_finite(move_speed) or move_speed <= 0.0 or not is_finite(despawn_x):
		return "移动速度必须为有限正数，离场 X 必须为有限数值。"
	if not is_instance_valid(animation_player) or not animation_player.has_animation(get_form_animation()) \
		or not animation_player.has_animation(get_roll_animation()):
		return "缺少有效播放器、成形动画或滚动动画。"
	if animation_player.get_animation(get_form_animation()).loop_mode != Animation.LOOP_NONE:
		return "成形动画必须为非循环。"
	if animation_player.get_animation(get_roll_animation()).loop_mode != Animation.LOOP_LINEAR:
		return "滚动动画必须为线性循环。"
	if not is_instance_valid(attack_area) or attack_area.collision_layer != 0 \
		or attack_area.collision_mask != 8448 or attack_area.monitorable:
		return "AttackArea 必须只检测第 9 层 PlantHurtBoxReal 和第 14 层 LawnMover，自身碰撞层为 0 且不可被检测。"
	# 固定场景结构中的攻击形状，启动前确认存在且没有被编辑器禁用。
	var attack_shape: CollisionShape2D = attack_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not is_instance_valid(attack_shape) or attack_shape.shape == null or attack_shape.disabled:
		return "AttackArea 缺少有效且启用的 CollisionShape2D。"
	return ""
