## 管理普通僵尸波次和独立僵王实例，统一敌方计数、轮间保存及胜利请求。
extends MainGameSubManager
class_name ZombieManager

## 出战僵王成功入树、死亡或移除后发出，供所属关卡按当前存活实例选择战斗音乐。
signal signal_living_bosses_changed()

## 无出怪模式或最后一波启用的场外清理计时器，每秒清理离开视野的普通僵尸。
@onready var check_zombie_end_wave_timer: Timer = $CheckZombieEndWaveTimer
## 管理器
@onready var zombie_wave_manager: ZombieWaveManager = $ZombieWaveManager
@onready var zombie_show_in_start: ZombieShowInStart = $ZombieShowInStart
@onready var hammer_zombie_manager: HammerZombieManager = $HammerZombieManager
## 僵尸数量label
@onready var label_zombie_sum: Label = %LabelZombieSum
## 所有僵尸根节点
@onready var zombies_root: Node2D = %ZombiesRoot
## 僵王独立挂载，不混入会被当作僵尸行遍历的 ZombiesRoot。
@onready var zombie_boss_root: Node2D = get_node_or_null("%ZombieBossRoot") as Node2D

## 本关已登记的僵王弱引用；死亡演出期间保留，离树时按实例 ID 移除。
var _registered_bosses: Dictionary[int, WeakRef] = {}
## 仍计入敌方数量的僵王 ID；死亡和离树共用此集合，保证只扣一次。
var _counted_boss_ids: Dictionary[int, bool] = {}
## 实例对应的注册类型，用于保存存活僵王，不依赖节点名称。
var _boss_types: Dictionary[int, CharacterRegistry.ZombieBossType] = {}
## 自动生成入口是否已经成功出场；卡牌召唤不占用此记录。
var _auto_boss_spawned := false
## 自动生成实例的 ID，仅用于自动入口重复调用时返回原实例。
var _auto_boss_id: int = 0
## 本局累计成功生成数量，自动出场和卡牌召唤均计入，恢复存档不重复增加。
var _boss_spawn_total: int = 0
## 本局累计确认死亡数量；直接移除不计为击杀。
var _boss_dead_total: int = 0
## 额外 Boss 条件实际开始结算后接受最后死亡实例的请求；0 表示没有待结算实例。
var _boss_trophy_pending_id: int = 0
## 本轮调用 Boss 胜利完成入口前置位，防止方法轨道重复触发；下一轮重新开启结算。
var _boss_trophy_created := false
## 轮间读档暂存的数据；选卡完成后才恢复正常出战实例，避免选卡期间启动技能。
var _saved_boss_data: Dictionary = {}
## 每轮只安排一次首波计时，下一轮开始时重置。
var _start_requested := false
## 轮次切换时递增，首波延迟不能从上一轮恢复到新一轮。
var _round_generation: int = 0

#region 僵尸管理器参数
## 刷怪类型
var is_bungi = false
var zombie_refresh_types = []

## 出怪模式
var monster_mode:ConstLevelData.E_MonsterMode = ConstLevelData.E_MonsterMode.Norm

#endregion

#region 多轮游戏
## 多轮游戏最后一波计时器
var multi_round_end_wave_timer:Timer
## 多轮游戏最后一波时长
var multi_round_end_wave_time :float = 49

#endregion

var curr_zombie_num:int = 0:
	set(v):
		curr_zombie_num=v
		label_zombie_sum.text = "当前僵尸数量：" + str(curr_zombie_num)

## 参与自然提前刷新的实例集合；弱引用避免已释放对象残留，实例 ID 用于幂等移除。
var _natural_refresh_zombies: Dictionary[int, WeakRef] = {}
## 自然提前刷新只读取该数量，博士本体及其召唤物不在集合中。
var natural_refresh_zombie_count: int:
	get:
		return _natural_refresh_zombies.size()
## 自然刷新参与数量发生变化时发出；[param num] 不包含博士及其衍生僵尸。
signal signal_natural_refresh_zombie_num_change(num: int)

## 是否为最后一波,最后一波时，僵尸数量为0后结束游戏
var is_end_wave := false
## 被魅惑僵尸列表
var all_zombies_be_hypno:Array[Zombie000Base] = []
## 僵尸可以存在的x坐标范围,超出该范围,每波刷新时删除,最后一波时每秒删除检查删除
var zombie_range_pos_x:=Vector2(-300, 1000)
## 所有僵尸列表,用于每波清除在地图外的僵尸(矿工,魅惑等僵尸)
var all_zombies_1d:Array[Zombie000Base]

## 所有僵尸行
var all_zombie_rows:Array[ZombieRow] = []
## 冰道,按行保存每行的冰道
var all_ice_roads:Array[Array] = []
## 按行保存僵尸，用于保存僵尸列表的列表,僵尸被魅惑后从该列表中删除
var all_zombies_2d:Array[Array]

## 是否被冻结，用于管理冰消珊瑚
var is_ice:bool
var ice_timer:Timer

func _ready():
	## 注册事件总线
	EventBus.subscribe("ice_all_zombie", ice_all_zombie)
	## 火爆辣椒销毁道具[冰道和梯子]
	EventBus.subscribe("jalapeno_bomb_item_lane", jalapeno_bomb_item_lane)
	EventBus.subscribe("jalapeno_bomb_lane_zombie", jalapeno_bomb_lane_zombie)
	EventBus.subscribe("blover_blow_away_in_sky_zombie", blover_blow_away_in_sky_zombie)
	## 非刷怪模式最后一波僵尸
	EventBus.subscribe("end_wave_zombie", func():is_end_wave=true)
	EventBus.subscribe("test_death_all_zombie", death_all_zombie)

	## 初始化僵尸和行列表
	for zombie_row_i in zombies_root.get_child_count():
		var zombie_row :CanvasItem= zombies_root.get_child(zombie_row_i)
		zombie_row.z_index = zombie_row_i * 50 + 30

		all_zombie_rows.append(zombie_row)
		var row_ice_roads:Array[IceRoad] = []
		all_ice_roads.append(row_ice_roads)

		var row_zombies:Array[Zombie000Base] = []
		all_zombies_2d.append(row_zombies)

## 初始僵尸管理器
func init_manager() -> void:
	## 出怪模式
	monster_mode = game_para.monster_mode
	match monster_mode:
		# 不启动自然波次；无论胜利条件如何，都持续清理移出视野的普通僵尸。
		ConstLevelData.E_MonsterMode.Null:
			check_zombie_end_wave_timer.start()
			zombie_wave_manager.flag_progress_bar.hide()

		ConstLevelData.E_MonsterMode.Norm:
			## 如果游戏是多轮游戏
			if game_para.game_round != 1:
				update_multi_round_zombie_refresh_types(main_game.curr_game_round, main_game.game_para.game_sences)
			else:
				## 刷怪类型
				is_bungi = game_para.is_bungi
				zombie_refresh_types = game_para.zombie_refresh_types

			zombie_wave_manager.init_zombie_wave_manager(game_para)
			## 波次刷新时判断是否为最后一波，删除多余魅惑僵尸
			zombie_wave_manager.signal_wave_refresh.connect(wave_refresh)
			## 使用独立的自然刷新数量，博士及其召唤物不阻塞旗前波提前刷新。
			signal_natural_refresh_zombie_num_change.connect(zombie_wave_manager.zombie_wave_refresh_manager.judge_total_refresh)

		ConstLevelData.E_MonsterMode.HammerZombie:
			hammer_zombie_manager.init_hammer_zombie_manager(game_para)
			## 波次刷新时判断是否为最后一波，删除多余魅惑僵尸
			hammer_zombie_manager.signal_wave_refresh.connect(wave_refresh)

## 开始第一波
func start_game():
	if not is_game_running() or _start_requested:
		return
	_start_requested = true
	# 等待完成后必须仍属于启动时的轮次。
	var round_generation: int = _round_generation
	_refresh_boss_progress()
	# Boss 生成与自然波次分开；正常模式继续首波计时，无出怪模式在生成后返回。
	if game_para.has_boss() and game_para.boss_spawn_wave == 0 and not _auto_boss_spawned:
		if create_boss() == null:
			return
	match monster_mode:
		ConstLevelData.E_MonsterMode.Null:
			return

		ConstLevelData.E_MonsterMode.Norm:
			## 10秒后开始刷新僵尸
			await get_tree().create_timer(10).timeout
			# 等待期间可能已经失败或离开关卡，不能让旧协程恢复后继续生成敌人。
			if round_generation == _round_generation and is_game_running():
				zombie_wave_manager.start_first_wave()

		ConstLevelData.E_MonsterMode.HammerZombie:
			await get_tree().create_timer(2).timeout
			if round_generation == _round_generation and is_game_running():
				hammer_zombie_manager.start_first_wave()


## 返回本管理器是否仍在树中、未排队删除且所属有效关卡处于正式战斗阶段。
## 供生成入口和波次延迟恢复共用；只查询所属关卡，不读取可能已切换的 Global.main_game。
func is_game_running() -> bool:
	return is_inside_tree() and not is_queued_for_deletion() \
		and is_instance_valid(main_game) and not main_game.is_queued_for_deletion() \
		and main_game.main_game_progress == MainGameManager.E_MainGameProgress.MAIN_GAME


## 自动入口按关卡配置只生成一次；卡牌生成不占用该记录，失败返回 null。
func create_boss() -> ZB000Base:
	if _auto_boss_spawned:
		return _get_registered_boss(_auto_boss_id)
	if not is_game_running() or not game_para.has_boss():
		return null
	if monster_mode != ConstLevelData.E_MonsterMode.Norm and monster_mode != ConstLevelData.E_MonsterMode.Null:
		return null
	# 自动实例与卡牌实例共用创建流程，但自动入口仍保持一次性。
	var boss: ZB000Base = _create_boss_instance(game_para.boss_type, game_para.boss_spawn_position)
	if boss != null:
		_auto_boss_spawned = true
		_auto_boss_id = boss.get_instance_id()
	return boss


## [param boss_type] 已注册的僵王类型；正式战斗、有效根节点及固定出生点允许时返回 true。
## 卡牌资格不依赖自动出场配置、出怪模式或场上数量。
func can_summon_boss(boss_type: CharacterRegistry.ZombieBossType) -> bool:
	if not is_game_running() or not is_instance_valid(zombie_boss_root) \
		or not zombie_boss_root.is_inside_tree() or zombie_boss_root.is_queued_for_deletion() \
		or not game_para.boss_spawn_position.is_finite() \
		or not Global.character_registry.ZombieBossInfo.has(boss_type):
		return false
	# 场景来自注册表，未注册或无法实例化的类型不能消耗卡牌。
	var scene: PackedScene = Global.character_registry.get_zombie_boss_info(
		boss_type, CharacterRegistry.ZombieBossInfoAttribute.BossScenes
	) as PackedScene
	return scene != null and scene.can_instantiate()


## [param boss_type] 卡牌引用中的僵王类型；每次成功返回新实例，不复用自动生成或已有角色。
## 使用关卡固定出生点，失败返回 null，由手持入口决定是否扣费和冷却。
func try_create_boss_from_card(boss_type: CharacterRegistry.ZombieBossType) -> ZB000Base:
	return _create_boss_instance(boss_type, game_para.boss_spawn_position)


## [param boss_type] 注册类型；[param spawn_position] 为僵王根节点下的本地位置。[br]
## [param count_as_new] 恢复存档时为 false，避免累计生成数重复增加。[br]
## [param restored_hp] 为正数时恢复存活血量，-1 沿用满血；成功返回新实例，失败返回 null。
func _create_boss_instance(boss_type: CharacterRegistry.ZombieBossType, spawn_position: Vector2,
	count_as_new: bool = true, restored_hp: int = -1) -> ZB000Base:
	if not can_summon_boss(boss_type) or not spawn_position.is_finite():
		return null
	# 资格检查已确认该注册场景可以实例化。
	var scene: PackedScene = Global.character_registry.get_zombie_boss_info(
		boss_type, CharacterRegistry.ZombieBossInfoAttribute.BossScenes
	) as PackedScene
	# 根节点先保持 Node，以便配置错误时释放实际创建的节点。
	var instance: Node = scene.instantiate()
	# 本次新角色，必须符合僵王基础接口。
	var boss: ZB000Base = instance as ZB000Base
	if boss == null:
		push_error("ZombieManager：僵王场景根节点必须继承 ZB000Base。")
		instance.free()
		return null
	# 血量子节点先于角色 _ready 初始化；提前拒绝零血量，避免漏接初始化死亡。
	var boss_hp: HpComponent = boss.get_node_or_null("%HpComponent") as HpComponent
	if boss_hp == null or boss_hp.max_hp <= 0 or boss.is_death:
		push_error("ZombieManager：僵王必须具有正数初始血量，且不能预设为死亡。")
		boss.free()
		return null
	boss.character_init_type = Character000Base.E_CharacterInitType.IsNorm
	boss.position = spawn_position
	# 先连接信号并计数，再触发角色 _ready，避免初始化期间发出的通知被遗漏。
	if not register_boss(boss, boss_type, count_as_new):
		boss.free()
		return null
	zombie_boss_root.add_child(boss)
	# 子节点已初始化，状态机尚未执行延迟启动；恢复血量不会重放上轮技能中间状态。
	if restored_hp > 0:
		boss_hp.Hp_loss(boss_hp.max_hp - mini(restored_hp, boss_hp.max_hp),
			BulletRegistry.AttackMode.Norm, false, false, false)
	# 登记发生在入树前，音乐通知必须等入树完成，存活快照才能包含本次实例。
	signal_living_bosses_changed.emit()
	_refresh_boss_progress()
	return boss


## [param boss] 尚未入树或已挂在僵王根节点的正常出战实例。[br]
## [param boss_type] 保存时使用的注册类型；[param count_as_new] 是否增加累计生成数。
## 同一实例重复登记只返回 true，不重复连接信号或计数；不限制登记数量。
func register_boss(boss: ZB000Base, boss_type: CharacterRegistry.ZombieBossType, count_as_new: bool = true) -> bool:
	if not is_instance_valid(boss) or boss.is_queued_for_deletion():
		return false
	# 用实例 ID 绑定通知，避免信号持有已释放的强类型角色参数。
	var instance_id: int = boss.get_instance_id()
	if _registered_bosses.has(instance_id):
		return true
	if not is_game_running() or boss.is_death \
		or boss.character_init_type != Character000Base.E_CharacterInitType.IsNorm \
		or not Global.character_registry.ZombieBossInfo.has(boss_type):
		return false
	if boss.get_parent() != null and boss.get_parent() != zombie_boss_root:
		return false
	_registered_bosses[instance_id] = weakref(boss)
	_counted_boss_ids[instance_id] = true
	_boss_types[instance_id] = boss_type
	if count_as_new:
		_boss_spawn_total += 1
	boss.signal_character_death.connect(_on_boss_dead.bind(instance_id))
	boss.signal_trophy_requested.connect(_on_boss_trophy_requested.bind(instance_id))
	boss.tree_exiting.connect(_on_boss_tree_exiting.bind(instance_id))
	curr_zombie_num += 1
	# 已挂在根节点的外部实例可直接登记；尚未入树的实例由生成入口完成后通知。
	if boss.is_inside_tree():
		signal_living_bosses_changed.emit()
	return true


## [param instance_id] 发出死亡通知的登记实例；重复通知不再次扣数或累计死亡。
## 先检查原有清场条件，再检查额外 Boss 条件；只有实际接受 Boss 胜利才停止刷新并等待演出。
## 单轮全部僵王死亡满足胜利条件时先判胜，已进入结算则保留僵王音乐。
func _on_boss_dead(instance_id: int) -> void:
	# 先验证弱引用，再访问角色死亡状态。
	var boss: ZB000Base = _get_registered_boss(instance_id)
	if boss == null or not boss.is_death or not _counted_boss_ids.erase(instance_id):
		return
	_boss_dead_total += 1
	curr_zombie_num -= 1
	# 单轮启用死亡胜利且全部僵王已击杀时，延后音乐通知，避免获胜前短暂切回原曲。
	var defer_bgm_update: bool = game_para.game_round == 1 and game_para.win_on_boss_death \
		and _boss_spawn_total > 0 and _boss_dead_total == _boss_spawn_total
	if not defer_bgm_update:
		# 多轮或仍需继续战斗时，先恢复原曲，再允许胜利判断切到结算阶段。
		signal_living_bosses_changed.emit()
	# 同一次死亡也满足普通清场时，保留原清场结算时机，不强制等待 Boss 演出。
	_try_finish_wave(boss.global_position)
	if game_para.win_on_boss_death and is_game_running() \
		and _boss_spawn_total > 0 and _boss_dead_total == _boss_spawn_total \
		and main_game.try_claim_round_end(true):
		_boss_trophy_pending_id = instance_id
		# 不暂停场景树、不直接通关，也不改变现有僵尸进房等失败入口。
		main_game.main_game_progress = MainGameManager.E_MainGameProgress.GAME_OVER
		# 停止两种波次入口；无出怪模式的场外清理在死亡演出期间继续运行。
		zombie_wave_manager.stop_wave_refresh()
		hammer_zombie_manager.stop_wave_refresh()
		if monster_mode == ConstLevelData.E_MonsterMode.Norm:
			check_zombie_end_wave_timer.stop()
		if is_instance_valid(multi_round_end_wave_timer):
			multi_round_end_wave_timer.stop()
	if defer_bgm_update:
		# 获胜后阶段过滤会保留僵王曲目；若未实际获胜，仍按存活快照恢复原曲。
		signal_living_bosses_changed.emit()
	_refresh_boss_progress()


## [param global_pos] 死亡动画或直接消失接口请求的奖杯生成位置，使用世界坐标。
## [param instance_id] 发出请求的登记实例；只完成已接受的 Boss 胜利，且每轮最多请求一次。
func _on_boss_trophy_requested(global_pos: Vector2, instance_id: int) -> void:
	if not game_para.win_on_boss_death or instance_id != _boss_trophy_pending_id or _boss_trophy_created:
		return
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(main_game) \
		or main_game.is_queued_for_deletion() or not main_game.is_inside_tree():
		return
	# 请求时实例必须仍有登记且尚未排队释放；直接消失在释放前发送，纯清场不会发送。
	var boss: ZB000Base = _get_registered_boss(instance_id)
	if boss == null or not boss.is_death \
		or boss.is_queued_for_deletion() or not boss.is_inside_tree():
		return
	if main_game.main_game_progress != MainGameManager.E_MainGameProgress.GAME_OVER \
		or TreePauseManager.curr_pause_factor.get(TreePauseManager.E_PauseFactor.GameOver, false):
		return
	_boss_trophy_created = true
	_boss_trophy_pending_id = 0
	# Boss 死亡时已接受胜利，演出结束只完成结算，不能再次调用普通判胜入口。
	main_game.complete_boss_victory(global_pos)


## [param instance_id] 即将离树的登记实例；只移除自身引用和计数，直接移除不计为击杀。
func _on_boss_tree_exiting(instance_id: int) -> void:
	_registered_bosses.erase(instance_id)
	_boss_types.erase(instance_id)
	if _counted_boss_ids.erase(instance_id):
		curr_zombie_num -= 1
		# 未死亡的直接移除也解除音乐覆盖；死亡后的离树不再重复通知。
		signal_living_bosses_changed.emit()
	if _boss_trophy_pending_id == instance_id:
		_boss_trophy_pending_id = 0
	_refresh_boss_progress()


## [param instance_id] 本局实例 ID；返回仍有效的登记僵王，已释放或未登记时返回 null。
func _get_registered_boss(instance_id: int) -> ZB000Base:
	if not _registered_bosses.has(instance_id):
		return null
	# 弱引用先保持 Variant，避免已释放对象传入强类型入口。
	var boss = _registered_bosses[instance_id].get_ref()
	return boss as ZB000Base if is_instance_valid(boss) else null


## 返回按登记顺序排列的存活实例快照；调用方可以遍历施加效果，不持有管理器内部集合。
func get_living_bosses() -> Array[ZB000Base]:
	# 快照只收集仍计入场上敌方的有效实例。
	var bosses: Array[ZB000Base] = []
	# 登记顺序决定血条显示最新生成的存活实例。
	for instance_id: int in _registered_bosses:
		# 死亡演出仍可登记，但不进入存活快照。
		var boss: ZB000Base = _get_registered_boss(instance_id)
		if _counted_boss_ids.has(instance_id) and boss != null and not boss.is_death \
			and boss.is_inside_tree() and not boss.is_queued_for_deletion():
			bosses.append(boss)
	return bosses


## 生命周期变化后更新存活数量和最新实例血条；场景卸载时不访问已退出的 UI。
func _refresh_boss_progress() -> void:
	if is_instance_valid(main_game) and is_instance_valid(main_game.level_info) \
		and main_game.level_info.is_inside_tree() and not main_game.level_info.is_queued_for_deletion():
		main_game.level_info.refresh_boss_progress(
			get_living_bosses(), _boss_trophy_pending_id != 0 or _boss_trophy_created,
			monster_mode != ConstLevelData.E_MonsterMode.Null and is_game_running()
		)


## 返回存活僵王及累计结算数据；待恢复的缓存原样复制，避免选卡前再次保存时覆盖为空。
func get_save_game_data_bosses() -> Dictionary:
	if not _saved_boss_data.is_empty():
		return _saved_boss_data.duplicate(true)
	# 只保存正常存活角色，不保存死亡演出或具体技能阶段。
	var living_bosses: Array[Dictionary] = []
	# 每只角色保留类型、生命值、根节点本地位置及自动入口归属。
	for boss: ZB000Base in get_living_bosses():
		# 运行时 ID 不写入存档，仅用于查找本次实例的元数据。
		var instance_id: int = boss.get_instance_id()
		living_bosses.append({"boss_type": _boss_types[instance_id], "hp": boss.hp_component.curr_hp,
			"position": boss.position, "is_auto": instance_id == _auto_boss_id})
	return {"living_bosses": living_bosses, "spawn_total": _boss_spawn_total,
		"dead_total": _boss_dead_total, "auto_spawned": _auto_boss_spawned}


## [param data] 可选僵王存档数据；仅暂存，正式战斗开始时再恢复，旧存档传空字典即可。
func load_game_data_bosses(data: Dictionary) -> void:
	_saved_boss_data = data.duplicate(true)


## 正式战斗开始后一次性恢复存活实例及累计记录；新实例从完整入场动作开始，不重复计数。
func restore_saved_bosses() -> void:
	if _saved_boss_data.is_empty() or not is_game_running():
		return
	# 消费一次缓存；恢复失败不会由后续开战调用重复生成。
	var data: Dictionary = _saved_boss_data
	_saved_boss_data = {}
	_boss_spawn_total = maxi(int(data.get("spawn_total", 0)), 0)
	_boss_dead_total = clampi(int(data.get("dead_total", 0)), 0, _boss_spawn_total)
	_auto_boss_spawned = bool(data.get("auto_spawned", false))
	# 存档仅记录存活角色，恢复时分配新的实例 ID。
	for snapshot: Dictionary in data.get("living_bosses", []):
		# 保存的类型、剩余生命与本地位置，缺少关键字段时拒绝恢复该条目。
		var boss_type: CharacterRegistry.ZombieBossType = snapshot.get("boss_type", CharacterRegistry.ZombieBossType.Null)
		# 0 血量不恢复为存活角色。
		var hp: int = snapshot.get("hp", 0)
		# 根节点本地坐标，避免恢复时受相机或父节点世界位置影响。
		var spawn_position: Vector2 = snapshot.get("position", game_para.boss_spawn_position)
		if hp <= 0:
			continue
		# 恢复使用同一生成流程，但累计生成数已经从存档读取。
		var boss: ZB000Base = _create_boss_instance(boss_type, spawn_position, false, hp)
		if boss == null:
			push_error("ZombieManager：无法恢复存档中的僵王：%s。" % boss_type)
			continue
		if snapshot.get("is_auto", false):
			_auto_boss_id = boss.get_instance_id()
	_refresh_boss_progress()


## 我是僵尸轮间清场时一并移除僵王；清场不产生击杀或奖杯，下一轮重新累计。
func _clear_bosses_for_next_round() -> void:
	# 在清空登记前收集所有有效实例，包括尚未离树的死亡演出。
	var bosses: Array[ZB000Base] = []
	# 逐个查找弱引用，跳过已经释放的实例。
	for instance_id: int in _registered_bosses:
		# 本次准备移除的角色。
		var boss: ZB000Base = _get_registered_boss(instance_id)
		if boss != null:
			bosses.append(boss)
	curr_zombie_num -= _counted_boss_ids.size()
	_counted_boss_ids.clear()
	_registered_bosses.clear()
	_boss_types.clear()
	_saved_boss_data.clear()
	_auto_boss_spawned = false
	_auto_boss_id = 0
	_boss_spawn_total = 0
	_boss_dead_total = 0
	# 信号在离树时仍可能执行，但集合已清空，不会再次扣减敌方数量。
	for boss: ZB000Base in bosses:
		boss.queue_free()
	# 整批清场后同步一次；重选卡阶段由关卡保留选卡音乐。
	signal_living_bosses_changed.emit()
	_refresh_boss_progress()

#region 生成僵尸
## 判断技能能否将指定类型放入目标行，不依赖普通波次选行器，也不改变计数。[br]
## [param zombie_type] 角色注册表中的僵尸类型。[br]
## [param lane] 从 0 开始的目标行号；不存在的行或不兼容的水陆类型返回 false。
func can_spawn_skill_zombie(zombie_type: CharacterRegistry.ZombieType, lane: int) -> bool:
	if lane < 0 or lane >= all_zombie_rows.size() or lane >= all_zombies_2d.size():
		return false
	# 目标行及出生点必须仍属于有效场景，避免使用已卸载的行数据。
	var row: ZombieRow = all_zombie_rows[lane]
	if not is_instance_valid(row) or not row.is_inside_tree() or row.is_queued_for_deletion() \
		or not is_instance_valid(row.zombie_create_position):
		return false
	if zombie_type == 0 or not Global.character_registry.ZombieInfo.has(zombie_type):
		return false
	# 注册场景必须可以实例化，空类型不会进入通用创建入口。
	var scene: PackedScene = Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieScenes) as PackedScene
	if scene == null or not scene.can_instantiate():
		return false
	# Both 表示两栖僵尸，或允许两种类型的行；其余情况要求水陆类型一致。
	var row_type: CharacterRegistry.ZombieRowType = Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieRowType)
	return row_type == CharacterRegistry.ZombieRowType.Both \
		or row.zombie_row_type == CharacterRegistry.ZombieRowType.Both or row_type == row.zombie_row_type


## 技能生成入口：使用释放点 X 和目标行基准 Y，登记与计数复用普通创建流程。[br]
## [param zombie_type] 本次准备阶段锁定的僵尸类型。[br]
## [param lane] 本次准备阶段锁定的目标行号，从 0 开始。[br]
## [param spawn_x] 释放瞬间的全局 X 坐标；非法坐标或关卡已结束时返回 null。
func create_skill_zombie(zombie_type: CharacterRegistry.ZombieType, lane: int, spawn_x: float) -> Zombie000Base:
	if not is_game_running() or not is_finite(spawn_x) or not can_spawn_skill_zombie(zombie_type, lane):
		return null
	# 新僵尸挂载到实际目标行，继续沿用该行的绘制层级和后续换行规则。
	var row: ZombieRow = all_zombie_rows[lane]
	# 此处只取标准行高；屋顶坡面高度由僵尸 ready_norm() 根据 X 修正一次。
	var spawn_position := Vector2(spawn_x, row.zombie_create_position.global_position.y)
	if not spawn_position.is_finite():
		return null
	# -1 表示技能生成，不归属自然波次，也不接入自然波次的掉血刷新统计。
	var init_parameters: Dictionary = {
		Zombie000Base.E_ZInitAttr.CharacterInitType: Character000Base.E_CharacterInitType.IsNorm,
		Zombie000Base.E_ZInitAttr.Lane: lane,
		Zombie000Base.E_ZInitAttr.CurrWave: -1,
		Zombie000Base.E_ZInitAttr.ParticipatesNaturalRefresh: false,
	}
	return create_norm_zombie(zombie_type, row, init_parameters, spawn_position)


## 创建技能召唤的蹦极僵尸，目标在入树前注入；失败时返回 null。[br]
## [param target_cell] 目标格子，其行号使用项目内部的零起始索引。[br]
## [param anchor] 本列对应的博士手部绳子连接点，入树前与目标一起注入。[br]
## [param on_created] 可选初始化回调，接收僵尸实例；用于在入树前监听本批完成事件。
func create_skill_bungi(target_cell: PlantCell, anchor: Marker2D, on_created: Callable = Callable()) -> Zombie021Bungi:
	if not is_game_running() or not is_instance_valid(target_cell) \
		or target_cell.is_queued_for_deletion() or not target_cell.is_inside_tree() \
		or not main_game.is_ancestor_of(target_cell) or target_cell.get_bungi_target() == null:
		return null
	# 目标所在行，不使用展示用的一起始行号。
	var lane: int = target_cell.row_col.x
	if not can_spawn_skill_zombie(CharacterRegistry.ZombieType.Z021Bungi, lane):
		return null
	# 父节点沿用实际僵尸行，保持现有行层级和死亡登记方式。
	var row: ZombieRow = all_zombie_rows[lane]
	# 根节点使用落点基准；身体上方偏移由蹦极自身处理，坡面由 ready_norm 修正一次。
	var spawn_position := Vector2(target_cell.global_position.x + target_cell.size.x / 2.0,
		row.zombie_create_position.global_position.y)
	if not spawn_position.is_finite():
		return null
	# 技能生成不归属自然波次，但仍正常计入场上僵尸数量。
	var init_parameters: Dictionary = {
		Zombie000Base.E_ZInitAttr.CharacterInitType: Character000Base.E_CharacterInitType.IsNorm,
		Zombie000Base.E_ZInitAttr.Lane: lane,
		Zombie000Base.E_ZInitAttr.CurrWave: -1,
		Zombie000Base.E_ZInitAttr.ParticipatesNaturalRefresh: false,
	}
	return create_norm_zombie(CharacterRegistry.ZombieType.Z021Bungi, row, init_parameters,
		spawn_position, _initialize_skill_bungi.bind(target_cell, anchor, on_created)) as Zombie021Bungi


## [param zombie] 刚实例化且尚未入树的蹦极僵尸。[br]
## [param target_cell] 本轮锁定的格子。[br]
## [param anchor] 本列对应的博士手部绳子连接点。[br]
## [param on_created] 技能提供的实例监听回调；先统一注入出战参数，再交给调用方登记。
func _initialize_skill_bungi(zombie: Zombie021Bungi, target_cell: PlantCell, anchor: Marker2D, on_created: Callable) -> void:
	# 博士已经通过进入动画表现召唤，蹦极入树后隐藏靶子并立即下降。
	zombie.initialize_spawn(target_cell, true, anchor)
	if on_created.is_valid():
		on_created.call(zombie)


## 生成一个正常出战僵尸，所有出战僵尸都要从这里生成
func create_norm_zombie(
	zombie_type:CharacterRegistry.ZombieType,	## 僵尸类型
	zombie_parent:Node,				## 僵尸父节点
	zombie_init_para:Dictionary,			## 僵尸初始化参数
	global_pos:Vector2=Vector2.ZERO,
	init_zombie_special:Callable = Callable()		## 初始化僵尸特殊属性
) -> Zombie000Base:
	# 新实例入树前由初始化参数确定刷新归属；博士来源不会登记到自然刷新集合。
	var zombie:Zombie000Base = Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieScenes).instantiate()
	zombie_init_para[Zombie000Base.E_ZInitAttr.IsMiniZombie] = game_para.is_mini_zombie
	zombie_init_para[Zombie000Base.E_ZInitAttr.IsZombieMode] = game_para.is_zombie_mode

	zombie.init_zombie(zombie_init_para)
	if not init_zombie_special.is_null():
		init_zombie_special.call(zombie)
	zombie.position = global_pos - zombie_parent.global_position
	zombie_parent.add_child(zombie)

	## 只要创建僵尸，都要连接这两个信号
	zombie.signal_character_death.connect(_on_zombie_dead.bind(zombie))
	zombie.signal_character_be_hypno.connect(_on_zombie_hypno.bind(zombie))
	zombie.signal_lane_update.connect(zombie_update_lane.bind(zombie, zombie.lane))

	all_zombies_2d[zombie.lane].append(zombie)
	all_zombies_1d.append(zombie)

	curr_zombie_num += 1
	_register_natural_refresh_zombie(zombie)

	return zombie

#endregion

#region 僵尸死亡 魅惑信号 波次刷新 多轮游戏
#region 魅惑 死亡
## [param zombie] 被魅惑时移出敌方及自然刷新计数，保留实例用于后续死亡清理。
func _on_zombie_hypno(zombie: Zombie000Base) -> void:
	if not all_zombies_1d.has(zombie) or all_zombies_be_hypno.has(zombie):
		return
	curr_zombie_num -= 1
	all_zombies_2d[zombie.lane].erase(zombie)
	all_zombies_be_hypno.append(zombie)
	_remove_natural_refresh_zombie(zombie.get_instance_id())
	zombie.signal_zombie_hp_loss.emit(zombie.hp_component.get_all_hp(), zombie.curr_wave)
	# 魅惑之后不再把该实例的掉血记入原自然波次。
	var connections: Array = zombie.signal_zombie_hp_loss.get_connections()
	# 当前需要移除的掉血监听连接。
	for connection: Dictionary in connections:
		zombie.signal_zombie_hp_loss.disconnect(connection.callable)
	_try_finish_wave(zombie.global_position)


## [param zombie] 死亡时只结算一次；已魅惑实例不会再次减少敌方或自然刷新数量。
func _on_zombie_dead(zombie: Zombie000Base) -> void:
	if not all_zombies_1d.has(zombie):
		return
	all_zombies_1d.erase(zombie)
	_remove_natural_refresh_zombie(zombie.get_instance_id())
	if zombie.is_hypno:
		all_zombies_be_hypno.erase(zombie)
	else:
		curr_zombie_num -= 1
		all_zombies_2d[zombie.lane].erase(zombie)
		_try_finish_wave(zombie.global_position)


## 将 [param zombie] 登记到自然刷新集合；所有原有生成默认参与，博士来源在入树前明确关闭。
func _register_natural_refresh_zombie(zombie: Zombie000Base) -> void:
	if not zombie.participates_natural_refresh or zombie.is_death or zombie.is_hypno or zombie.is_queued_for_deletion():
		return
	# 集合以实例 ID 去重，死亡、魅惑和离树可重复请求移除而不重复扣数。
	var instance_id: int = zombie.get_instance_id()
	if _natural_refresh_zombies.has(instance_id):
		return
	_natural_refresh_zombies[instance_id] = weakref(zombie)
	zombie.tree_exiting.connect(_on_natural_refresh_zombie_tree_exiting.bind(instance_id))
	signal_natural_refresh_zombie_num_change.emit(natural_refresh_zombie_count)


## 移除 [param instance_id] 的刷新登记；场景卸载期间只清理记录，不触发新的自然波次。
func _remove_natural_refresh_zombie(instance_id: int) -> void:
	if not _natural_refresh_zombies.erase(instance_id):
		return
	if is_game_running():
		signal_natural_refresh_zombie_num_change.emit(natural_refresh_zombie_count)


## [param instance_id] 离树时延迟确认；僵尸换行会重挂父节点，不能误当成离开关卡。
func _on_natural_refresh_zombie_tree_exiting(instance_id: int) -> void:
	call_deferred("_remove_natural_refresh_zombie_if_absent", instance_id)


## 仅当 [param instance_id] 真正释放或离开本关卡时清理刷新登记，正常换行保留。
func _remove_natural_refresh_zombie_if_absent(instance_id: int) -> void:
	if not _natural_refresh_zombies.has(instance_id):
		return
	# 弱引用返回值先保持 Variant，避免读取已释放的角色实例。
	var zombie = _natural_refresh_zombies[instance_id].get_ref()
	if is_instance_valid(zombie) and zombie.is_inside_tree() and not zombie.is_queued_for_deletion() \
		and is_instance_valid(main_game) and main_game.is_ancestor_of(zombie):
		return
	_remove_natural_refresh_zombie(instance_id)


## 普通死亡、魅惑及僵王死亡共用原有清场条件，不受额外 Boss 胜利选项影响。
## [param global_pos] 最后一个敌人的世界坐标，用于原清场胜利的奖杯位置。
func _try_finish_wave(global_pos: Vector2) -> void:
	if not is_game_running():
		return
	if is_end_wave and curr_zombie_num == 0:
		if is_instance_valid(multi_round_end_wave_timer):
			multi_round_end_wave_timer.stop()
		EventBus.push_event("create_trophy", [global_pos])
#endregion

#region 波次刷新
func wave_refresh(curr_is_end_wave:bool):
	# 回调发生在本波普通僵尸生成后。先计入僵王，再清理场外僵尸，避免末波短暂归零。
	if monster_mode == ConstLevelData.E_MonsterMode.Norm and game_para.has_boss() \
		and game_para.boss_spawn_wave > 0 and not _auto_boss_spawned \
		and zombie_wave_manager.curr_wave + 1 == game_para.boss_spawn_wave:
		if create_boss() == null:
			return
	is_end_wave = curr_is_end_wave
	set_zombie_death_over_view()
	if is_end_wave:
		check_zombie_end_wave_timer.start()
		print("最后一波僵尸检测是否有离开当前视野的僵尸")
		## 多轮游戏计时器启动
		multi_round_end_wave_timer_start()

### 删除移动超出视野的僵尸,每次刷新僵尸调用
func set_zombie_death_over_view():
	for z:Zombie000Base in all_zombies_1d:
		# 检查是否在屏幕外
		if z.global_position.x > zombie_range_pos_x.y or z.global_position.x < zombie_range_pos_x.x:
			#all_zombies_be_hypno.erase(z)
			z.character_death_disappear()
	#print("删除离开当前视野的僵尸，目前还剩的僵尸：", all_zombies_1d)
#endregion

#region 多轮游戏
#region 触发
## 战斗末波后按原规则启动 49 秒轮间计时，不受额外 Boss 胜利选项影响。
func multi_round_end_wave_timer_start():
	if not is_game_running():
		return
	if not is_instance_valid(multi_round_end_wave_timer):
		multi_round_end_wave_timer = Timer.new()
		multi_round_end_wave_timer.wait_time = multi_round_end_wave_time
		multi_round_end_wave_timer.one_shot = true
		multi_round_end_wave_timer.autostart = false
		multi_round_end_wave_timer.timeout.connect(_on_trigger_start_next_round_game)
		add_child(multi_round_end_wave_timer)
	multi_round_end_wave_timer.start()
	print("多轮游戏波次后一波计时器启动")

## 战斗中触发原有轮间计时请求；末轮与重复请求由主游戏管理器拒绝。
func _on_trigger_start_next_round_game():
	multi_round_end_wave_timer.stop()
	if is_game_running():
		EventBus.push_event("start_next_round_game")
#endregion

#region 开始下一轮游戏
## 更新下一轮僵尸管理器；[param finish_current_round] 为实际 Boss 胜利时跳过剩余自然波次。
func start_next_game_zombie_mananger_update(finish_current_round: bool = false):
	is_end_wave = false
	_start_requested = false
	_round_generation += 1
	_boss_trophy_pending_id = 0
	_boss_trophy_created = false
	match monster_mode:
		ConstLevelData.E_MonsterMode.Norm:
			check_zombie_end_wave_timer.stop()
			## 更新当前轮次的出怪列表
			update_multi_round_zombie_refresh_types(main_game.curr_game_round, main_game.game_para.game_sences)
			# 按本轮实际结束原因推进波次，配置开启本身不改变原有轮间规则。
			zombie_wave_manager.start_next_game_zombie_wave_mananger_update(finish_current_round)
		ConstLevelData.E_MonsterMode.HammerZombie:
			hammer_zombie_manager.start_next_game_hammer_manager_update(game_para)

	## 我是僵尸模式删除所有的僵尸
	if game_para.is_zombie_mode:
		_clear_bosses_for_next_round()
		# 我是僵尸轮间原有清场顺序，僵王已由独立根节点清理。
		for i in range(all_zombies_1d.size()-1,-1,-1):
			# 当前轮次尚未移除的普通僵尸。
			var zombie:Zombie000Base = all_zombies_1d[i]
			zombie.character_death_disappear()
	_refresh_boss_progress()

#endregion


#region 多轮(无尽)出怪
## 多轮出怪获取出怪列表
func update_multi_round_zombie_refresh_types(curr_round:int, game_sences:MainSceneRegistry.MainScenes) -> void:
	## 清空数据
	is_bungi = false
	zombie_refresh_types.clear()
	# 第一次选卡 (curr_round == 1) 的 “固定三种”：普僵 + 路障 + 铁桶
	if curr_round == 1:
		zombie_refresh_types.append(CharacterRegistry.ZombieType.Z001Norm)
		zombie_refresh_types.append(CharacterRegistry.ZombieType.Z003Cone)
		zombie_refresh_types.append(CharacterRegistry.ZombieType.Z005Bucket)
	else:
		var whitelist_refresh_zombie_types_copy = Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[Global.main_scene_registry.ZombieRowTypewithMainScenesMap[game_sences]].duplicate(true)
		zombie_refresh_types.append(CharacterRegistry.ZombieType.Z001Norm)
		whitelist_refresh_zombie_types_copy.erase(CharacterRegistry.ZombieType.Z001Norm)
		# 第二种：80% 路障 (Cone)，20% 报纸 (Paper)
		var prob = randf()
		if prob < 0.8:
			zombie_refresh_types.append(CharacterRegistry.ZombieType.Z003Cone)
			whitelist_refresh_zombie_types_copy.erase(CharacterRegistry.ZombieType.Z003Cone)
		else:
			zombie_refresh_types.append(CharacterRegistry.ZombieType.Z006Paper)
			whitelist_refresh_zombie_types_copy.erase(CharacterRegistry.ZombieType.Z006Paper)
		## 第二轮之后可能刷新僵尸(min(轮次*2,8)+2)个
		for i in range(min(curr_round * 2, 8)):
			var zombie_type_choose = whitelist_refresh_zombie_types_copy.pick_random()
			zombie_refresh_types.append(zombie_type_choose)
			whitelist_refresh_zombie_types_copy.erase(zombie_type_choose)

			if zombie_type_choose == CharacterRegistry.ZombieType.Z021Bungi:
				print("warning: 出怪刷新列表禁止使用 Z021Bungi ,已修改为选择 is_bungi 参数")
				is_bungi = true
				zombie_refresh_types.erase(zombie_type_choose)

			if whitelist_refresh_zombie_types_copy.is_empty():
				break

	print("当前轮次", curr_round,"可能刷新的僵尸类型有:")
	for zombie_type in zombie_refresh_types:
		print(Global.character_registry.get_zombie_info(zombie_type, CharacterRegistry.ZombieInfoAttribute.ZombieName))
	if is_bungi:
		print(Global.character_registry.get_zombie_info(CharacterRegistry.ZombieType.Z021Bungi, CharacterRegistry.ZombieInfoAttribute.ZombieName))


#endregion


#endregion
#endregion

#region 生成关卡前展示僵尸
func create_prepare_show_zombies():
	zombie_show_in_start.create_prepare_show_zombies()

func delete_prepare_show_zombies():
	zombie_show_in_start.delete_prepare_show_zombies()
#endregion

#region 植物调用相关，寒冰菇\火爆辣椒\三叶草
## 寒冰菇处理普通僵尸及所有存活僵王；各僵王自行检查受击窗口。[br]
## [param time_ice] 完全冻结时长，单位为游戏秒。[br]
## [param time_decelerate] 解冻后的减速时长，单位为游戏秒。
func ice_all_zombie(time_ice:float, time_decelerate: float):
	# 保留寒冰菇对珊瑚出怪的抑制计时。
	is_ice = true
	start_ice_timer(time_ice)
	# 当前行的普通僵尸列表；僵王由独立集合登记。
	for zombie_row:Array in all_zombies_2d:
		if zombie_row.is_empty():
			continue
		# 当前接受冻结效果的普通僵尸。
		for zombie:Zombie000Base in zombie_row:
			zombie.be_ice_freeze(time_ice, time_decelerate)
	# 僵王不加入普通僵尸列表，避免重复计数或受到普通僵尸的删除规则影响。
	# 每只存活僵王只接收一次本次全场冻结。
	for boss: ZB000Base in get_living_bosses():
		if is_instance_valid(boss):
			boss.be_ice_freeze(time_ice, time_decelerate)

func start_ice_timer(wait_time:float):
	if not is_instance_valid(ice_timer):
		ice_timer = Timer.new()
		ice_timer.one_shot = true
		ice_timer.timeout.connect(_on_ice_timer_timeout)
		add_child(ice_timer)
	ice_timer.start(wait_time)

func _on_ice_timer_timeout():
	if is_ice == false:
		push_error("冰消珊瑚计时器有误，is_ice应该为true")
	is_ice = false




func jalapeno_bomb_item_lane(lane:int):
	## 冰道
	for i in range(all_ice_roads[lane].size()-1, -1, -1):
		var ice_road:IceRoad = all_ice_roads[lane][i]
		ice_road.ice_road_disappear()

## 火爆辣椒处理整行普通僵尸，并攻击所有存活僵王；僵王检查受击窗口，不限制行号。[br]
## [param lane] 辣椒所在的零起始行号，仅用于选择受影响的普通僵尸。
func jalapeno_bomb_lane_zombie(lane:int):
	# 倒序遍历当前行，普通僵尸被炸死时可能立即从列表移除。
	for i in range(all_zombies_2d[lane].size()-1,-1,-1) :
		if is_instance_valid(all_zombies_2d[lane][i]):
			# 当前接受爆炸伤害的普通僵尸，继续沿用其原有灰烬与删除规则。
			var zombie:Zombie000Base = all_zombies_2d[lane][i]
			zombie.be_bomb(1800, true)
	# 任意行的辣椒都可命中僵王，使用专用入口检查受击窗口并保留完整死亡演出。
	# 使用快照，某只僵王死亡不会影响其余实例遍历。
	for boss: ZB000Base in get_living_bosses():
		if is_instance_valid(boss):
			boss.be_jalapeno(1800)

## 三叶草吹走空中僵尸
func blover_blow_away_in_sky_zombie():
	for zombie_row:Array in all_zombies_2d:
		if zombie_row.is_empty():
			continue
		for i in range(zombie_row.size()-1, -1, -1):
			var zombie:Zombie000Base = zombie_row[i]
			if zombie.curr_be_attack_status == Zombie000Base.E_BeAttackStatusZombie.IsSky:
				zombie.be_blow_away()

#endregion

## 无出怪模式或最后一波时，每秒清理离开当前视野的普通僵尸。
func _on_check_zombie_end_wave_timer_timeout() -> void:
	set_zombie_death_over_view()

## 僵尸换行,更新数据
func zombie_update_lane(zombie:Zombie000Base, ori_lane:int):
	if all_zombies_2d[ori_lane].has(zombie):
		all_zombies_2d[ori_lane].erase(zombie)
		all_zombies_2d[zombie.lane].append(zombie)
		zombie.signal_lane_update.disconnect(zombie_update_lane.bind(zombie, ori_lane))
		zombie.signal_lane_update.connect(zombie_update_lane.bind(zombie, zombie.lane))
		#print("僵尸换行")


#region 控制台 所有僵尸死亡
## 所有僵尸死亡
func death_all_zombie():
	for zombie_row:Array in all_zombies_2d:
		if zombie_row.is_empty():
			continue
		for i in range(zombie_row.size()-1, -1, -1):
			var zombie:Zombie000Base = zombie_row[i]
			zombie.character_death_disappear()
#endregion
