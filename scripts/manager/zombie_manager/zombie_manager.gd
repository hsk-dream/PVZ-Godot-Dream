extends MainGameSubManager
class_name ZombieManager

## 最后一波僵尸每秒检测是否有僵尸离开当前视野
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

## 当前僵王独立保存，不加入要求 Zombie000Base 类型的普通僵尸数组。
var active_boss: ZB000Base
## 生成记录不随死亡清除，防止重复启动或波次回调补生第二个僵王。
var _boss_spawned := false
## 首次死亡或离树时消费计数标记，避免重复通知扣减数量。
var _boss_counted := false
## Boss 死亡后等待动画关键帧；独立于存活计数，允许 GAME_OVER 阶段继续接收奖杯请求。
var _boss_trophy_pending := false
## 在发出奖杯事件前置位，防止方法轨道或事件回调重复创建奖杯。
var _boss_trophy_created := false
## 每轮只安排一次首波计时，下一轮开始时重置。
var _start_requested := false

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
		signal_curr_zombie_num_change.emit(v)

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

signal signal_curr_zombie_num_change(num:int)

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
		## 没有僵尸刷新,直接启动最后一波僵尸检查计时器
		ConstLevelData.E_MonsterMode.Null:
			check_zombie_end_wave_timer.start()

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
			## 僵尸数量改变时，剩余僵尸为0触发提前刷新
			signal_curr_zombie_num_change.connect(zombie_wave_manager.zombie_wave_refresh_manager.judge_total_refresh)

		ConstLevelData.E_MonsterMode.HammerZombie:
			hammer_zombie_manager.init_hammer_zombie_manager(game_para)
			## 波次刷新时判断是否为最后一波，删除多余魅惑僵尸
			hammer_zombie_manager.signal_wave_refresh.connect(wave_refresh)

		ConstLevelData.E_MonsterMode.Boss:
			# Boss 模式不初始化自然波次，也不连接数量变化触发的提前刷新。
			is_end_wave = false
			check_zombie_end_wave_timer.stop()
			zombie_wave_manager.flag_progress_bar.hide()

## 开始第一波
func start_game():
	if not _is_game_running() or _start_requested:
		return
	_start_requested = true
	# 普通模式仍继续下方首波计时；Boss 模式在生成后结束本入口。
	if game_para.has_boss() and game_para.boss_spawn_wave == 0:
		if create_boss() == null:
			return
	match monster_mode:
		ConstLevelData.E_MonsterMode.Null:
			return
		ConstLevelData.E_MonsterMode.Boss:
			return

		ConstLevelData.E_MonsterMode.Norm:
			## 10秒后开始刷新僵尸
			await get_tree().create_timer(10).timeout
			# 等待期间可能已经失败或离开关卡，不能让旧协程恢复后继续生成敌人。
			if _is_game_running():
				zombie_wave_manager.start_first_wave()

		ConstLevelData.E_MonsterMode.HammerZombie:
			await get_tree().create_timer(2).timeout
			if _is_game_running():
				hammer_zombie_manager.start_first_wave()


## 判断本管理器仍属于正在战斗的关卡，供生成入口与延迟计时恢复时共用。
func _is_game_running() -> bool:
	return is_inside_tree() and not is_queued_for_deletion() \
		and is_instance_valid(main_game) and not main_game.is_queued_for_deletion() \
		and main_game.main_game_progress == MainGameManager.E_MainGameProgress.MAIN_GAME


## 按关卡类型从全局注册表生成一次僵王；失败返回 null，不生成替代角色。
func create_boss() -> ZB000Base:
	if _boss_spawned:
		return active_boss if is_instance_valid(active_boss) else null
	if not _is_game_running() or not game_para.has_boss():
		return null
	if monster_mode != ConstLevelData.E_MonsterMode.Norm and monster_mode != ConstLevelData.E_MonsterMode.Boss:
		return null
	if not is_instance_valid(zombie_boss_root):
		push_error("ZombieManager：主游戏场景缺少有效的 %ZombieBossRoot。")
		return null
	var scene := Global.character_registry.get_zombie_boss_info(
		game_para.boss_type, CharacterRegistry.ZombieBossInfoAttribute.BossScenes
	) as PackedScene
	if scene == null or not scene.can_instantiate():
		push_error("ZombieManager：注册的僵王场景无效，无法生成。")
		return null
	var instance := scene.instantiate()
	var boss := instance as ZB000Base
	if boss == null:
		push_error("ZombieManager：僵王场景根节点必须继承 ZB000Base。")
		instance.free()
		return null
	# 血量子节点先于角色 _ready 初始化；提前拒绝零血量，避免漏接初始化死亡。
	var boss_hp := boss.get_node_or_null("%HpComponent") as HpComponent
	if boss_hp == null or boss_hp.max_hp <= 0 or boss.is_death:
		push_error("ZombieManager：僵王必须具有正数初始血量，且不能预设为死亡。")
		boss.free()
		return null
	boss.character_init_type = Character000Base.E_CharacterInitType.IsNorm
	boss.position = game_para.boss_spawn_position
	# 先连接信号并计数，再触发角色 _ready，避免初始化期间发出的通知被遗漏。
	if not register_boss(boss):
		boss.free()
		return null
	zombie_boss_root.add_child(boss)
	return boss


## 同一实例重复登记不重复计数；本关最多登记一个存活的正常出战僵王。
func register_boss(boss: ZB000Base) -> bool:
	if not is_instance_valid(boss) or boss.is_queued_for_deletion():
		return false
	if _boss_spawned:
		return boss == active_boss
	if not _is_game_running() or boss.is_death \
		or boss.character_init_type != Character000Base.E_CharacterInitType.IsNorm:
		return false
	if boss.get_parent() != null and boss.get_parent() != zombie_boss_root:
		return false
	active_boss = boss
	_boss_spawned = true
	_boss_counted = true
	boss.signal_character_death.connect(_on_boss_dead.bind(boss))
	boss.signal_trophy_requested.connect(_on_boss_trophy_requested.bind(boss))
	boss.tree_exiting.connect(_on_boss_tree_exiting.bind(boss))
	curr_zombie_num += 1
	return true


## 死亡信号只消费一次计数；Boss 模式结束战斗阶段，等待动画轨道，普通模式仍检查清场。
func _on_boss_dead(boss: ZB000Base) -> void:
	if boss != active_boss or not _boss_counted or not boss.is_death:
		return
	_boss_counted = false
	curr_zombie_num -= 1
	if monster_mode == ConstLevelData.E_MonsterMode.Boss and _is_game_running():
		_boss_trophy_pending = true
		# 不暂停场景树、不直接通关，也不改变现有僵尸进房等失败入口。
		main_game.main_game_progress = MainGameManager.E_MainGameProgress.GAME_OVER
	_try_finish_wave(boss.global_position)


## 只接受本关已登记并死亡的 Boss；动画末尾的延迟回调即使已进入 Dead 也可发奖。
func _on_boss_trophy_requested(global_pos: Vector2, boss: ZB000Base) -> void:
	if monster_mode != ConstLevelData.E_MonsterMode.Boss or not _boss_trophy_pending or _boss_trophy_created:
		return
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(main_game) \
		or main_game.is_queued_for_deletion() or not main_game.is_inside_tree():
		return
	if boss != active_boss or not is_instance_valid(boss) or not boss.is_death \
		or boss.is_queued_for_deletion() or not boss.is_inside_tree():
		return
	if main_game.main_game_progress != MainGameManager.E_MainGameProgress.GAME_OVER:
		return
	_boss_trophy_created = true
	_boss_trophy_pending = false
	EventBus.push_event("create_trophy", [global_pos])


## 直接移除角色只清理计数和引用，不把离树事件当作击杀触发奖杯。
func _on_boss_tree_exiting(boss: ZB000Base) -> void:
	if boss != active_boss:
		return
	active_boss = null
	_boss_trophy_pending = false
	if _boss_counted:
		_boss_counted = false
		curr_zombie_num -= 1

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
	if not _is_game_running() or not is_finite(spawn_x) or not can_spawn_skill_zombie(zombie_type, lane):
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
	}
	return create_norm_zombie(zombie_type, row, init_parameters, spawn_position)


## 创建技能召唤的蹦极僵尸，目标在入树前注入；失败时返回 null。[br]
## [param target_cell] 目标格子，其行号使用项目内部的零起始索引。[br]
## [param on_created] 可选初始化回调，接收僵尸实例；用于在入树前监听本批完成事件。
func create_skill_bungi(target_cell: PlantCell, on_created: Callable = Callable()) -> Zombie021Bungi:
	if not _is_game_running() or not is_instance_valid(target_cell) \
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
	}
	return create_norm_zombie(CharacterRegistry.ZombieType.Z021Bungi, row, init_parameters,
		spawn_position, _initialize_skill_bungi.bind(target_cell, on_created)) as Zombie021Bungi


## [param zombie] 刚实例化且尚未入树的蹦极僵尸。[br]
## [param target_cell] 本轮锁定的格子。[br]
## [param on_created] 技能提供的实例监听回调；先注入目标和入场参数，再交给调用方登记。
func _initialize_skill_bungi(zombie: Zombie021Bungi, target_cell: PlantCell, on_created: Callable) -> void:
	GlobalUtils.create_bungi(zombie, target_cell)
	# 博士已经通过进入动画表现召唤，蹦极入树后隐藏靶子并立即下降。
	zombie.skip_spawn_warning = true
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

	return zombie

#endregion

#region 僵尸死亡 魅惑信号 波次刷新 多轮游戏
#region 魅惑 死亡
## 僵尸被魅惑发射信号
func _on_zombie_hypno(zombie:Zombie000Base):
	## 出战僵尸保存列表删除该僵尸
	curr_zombie_num -= 1
	all_zombies_2d[zombie.lane].erase(zombie)
	## 掉血信号
	zombie.signal_zombie_hp_loss.emit(zombie.hp_component.get_all_hp(), zombie.curr_wave)
	var conns = zombie.signal_zombie_hp_loss.get_connections()
	for conn in conns:
		zombie.signal_zombie_hp_loss.disconnect(conn.callable)
	all_zombies_be_hypno.append(zombie)

	_try_finish_wave(zombie.global_position)

## 僵尸发射死亡信号后调用函数
func _on_zombie_dead(zombie: Zombie000Base) -> void:
	all_zombies_1d.erase(zombie)
	if zombie.is_hypno:
		all_zombies_be_hypno.erase(zombie)
	else:
		curr_zombie_num -= 1
		all_zombies_2d[zombie.lane].erase(zombie)

		_try_finish_wave(zombie.global_position)


## 普通死亡、魅惑及僵王死亡共用原有清场条件；Boss 模式不通过此入口发奖。
func _try_finish_wave(global_pos: Vector2) -> void:
	if monster_mode == ConstLevelData.E_MonsterMode.Boss or not _is_game_running():
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
		and game_para.boss_spawn_wave > 0 and not _boss_spawned \
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
## 多轮游戏 非最后一轮 最后一波 计时器
func multi_round_end_wave_timer_start():
	if not is_instance_valid(multi_round_end_wave_timer):
		multi_round_end_wave_timer = Timer.new()
		multi_round_end_wave_timer.wait_time = multi_round_end_wave_time
		multi_round_end_wave_timer.one_shot = true
		multi_round_end_wave_timer.autostart = false
		multi_round_end_wave_timer.timeout.connect(_on_trigger_start_next_round_game)
		add_child(multi_round_end_wave_timer)
	multi_round_end_wave_timer.start()
	print("多轮游戏波次后一波计时器启动")

## 触发开始下一轮game
func _on_trigger_start_next_round_game():
	EventBus.push_event("start_next_round_game")
	multi_round_end_wave_timer.stop()
#endregion

#region 开始下一轮游戏
## 僵尸管理器更新
func start_next_game_zombie_mananger_update():
	is_end_wave = false
	_start_requested = false
	match monster_mode:
		ConstLevelData.E_MonsterMode.Norm:
			check_zombie_end_wave_timer.stop()
			## 更新当前轮次的出怪列表
			update_multi_round_zombie_refresh_types(main_game.curr_game_round, main_game.game_para.game_sences)
			zombie_wave_manager.start_next_game_zombie_wave_mananger_update()

	## 我是僵尸模式删除所有的僵尸
	if game_para.is_zombie_mode:
		for i in range(all_zombies_1d.size()-1,-1,-1):
			var zombie:Zombie000Base = all_zombies_1d[i]
			zombie.character_death_disappear()

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
## 冰冻所有僵尸
func ice_all_zombie(time_ice:float, time_decelerate: float):
	## 冰消珊瑚
	is_ice = true
	start_ice_timer(time_ice)
	for zombie_row:Array in all_zombies_2d:
		if zombie_row.is_empty():
			continue
		for zombie:Zombie000Base in zombie_row:
			zombie.be_ice_freeze(time_ice, time_decelerate)

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

## 火爆辣椒爆炸整行僵尸
func jalapeno_bomb_lane_zombie(lane:int):
	#print(all_zombies_2d[lane])
	for i in range(all_zombies_2d[lane].size()-1,-1,-1) :
		if is_instance_valid(all_zombies_2d[lane][i]):
			var zombie:Zombie000Base = all_zombies_2d[lane][i]
			zombie.be_bomb(1800, true)

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

## 最后一波时每秒检查是否有僵尸离开当前视野
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
