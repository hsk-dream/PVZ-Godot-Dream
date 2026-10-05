extends Node
class_name HammerZombieManager

"""
参考：https://www.bilibili.com/video/BV12e4y1J7hH/
共计11大组僵尸、每大组结束后会停顿较长时间，并生成一次墓碑
每大组僵尸有11-15小组僵尸

修改为：每10波为1大波，每10小组为1波

游戏开始后，墓碑可能出现普通僵尸
第2次停顿后，2个墓碑可能同时召唤同一种僵尸
第4次停顿后，可能出现路障僵尸
第6次停顿后，可能出现铁桶僵尸
第8次停顿后，3个墓碑可能同时召唤同一种僵尸
最后1波时，所有墓碑同时召唤铁桶或路障，但是不超过20只


游戏开始时，长9个墓碑
每次长墓碑时，如果墓碑数量<5，则把墓碑数量长至5
每次长墓碑时，如果墓碑数量=>5，则长1个墓碑
墓碑只长第4列~第9列，如果都被占满则不长墓碑，只有停顿
"""
@onready var hammer_zombie_timer: Timer = $HammerZombieTimer
@onready var flag_progress_bar: FlagProgressBar = %FlagProgressBar
## 固定所属僵尸管理器，延迟回调只读取原关卡，不能生成到切换后的 Global.main_game。
@onready var zombie_manager: ZombieManager = get_parent() as ZombieManager
## 当前轮次已停止时禁止刷新；初始化新一轮才解除，旧协程仍受版本约束。
var _refresh_stopped: bool = false
## 停止或初始化时递增的刷新版本；旧轮次等待恢复后不能进入新一轮。
var _refresh_generation: int = 0

## 最多波数
@export var max_wave = 10

## 当前小组数量总和
var curr_all_group_min_num_sum:=-1
var curr_wave := -1		#当前波
var curr_group_min := -1		#当前小组数

## 每一小组的进度条占比（%）
var progress_bar_segment_every_groud_min :float

## 当前可以生成的僵尸类型
var curr_zombie_type_candidate :Array[CharacterRegistry.ZombieType] = [CharacterRegistry.ZombieType.Z001Norm]
## 当前每小组可以生成的僵尸数量
var curr_num_new_zombie_every_group := 1
## 当前每小组间隔时间（从1s开始，每大组减速0.05秒，真正使用时增加0.1秒波动）最小为0.5
var interval_every_group := 1.0
## 是否围为大波（每10波一大波）
var big_wave := false

## 出怪倍率
var zombie_multy:= 1

## 初始化僵尸速度
var curr_speed_zombie := 1.0
## 每小组僵尸速度提升
var speed_zombie_add := 0.15
## 僵尸速度提升最大值
var speed_zombie_max := 2.0


## 波次刷新信号,给zombie_manager,删除魅惑僵尸，更新是否为最后一波
signal signal_wave_refresh(is_end_wave:bool)

func _ready() -> void:
	hammer_zombie_timer.one_shot = true

## 读取 [param game_para] 的锤僵尸出怪参数，并启用新版本的刷新流程。
## [param is_next_round] 为 true 时重置既有旗进度，避免重复使用首次初始化后已释放的旗模板。
func init_hammer_zombie_manager(game_para:ResourceLevelData, is_next_round: bool = false):
	_refresh_generation += 1
	hammer_zombie_timer.stop()
	_refresh_stopped = false
	zombie_multy = game_para.zombie_multy_hammer
	max_wave = game_para.max_wave_hammer_zombie
	curr_speed_zombie = game_para.speed_zombie_init
	speed_zombie_add = game_para.speed_zombie_add
	speed_zombie_max = game_para.speed_zombie_max

	# 首轮创建旗帜，后续轮次复用现有旗帜与进度条。
	if is_next_round:
		flag_progress_bar.start_next_game_flag_progress_bar_update()
	else:
		flag_progress_bar.init_flag_from_wave(max_wave)
	progress_bar_segment_every_groud_min = 100.0 / (max_wave*10)

## 按 [param game_para] 重新启用下一轮；清空波次成长，等待正式战斗后启动第一小组。
func start_next_game_hammer_manager_update(game_para: ResourceLevelData) -> void:
	init_hammer_zombie_manager(game_para, true)
	curr_all_group_min_num_sum = -1
	curr_wave = -1
	curr_group_min = -1
	curr_zombie_type_candidate = [CharacterRegistry.ZombieType.Z001Norm]
	curr_num_new_zombie_every_group = 1
	interval_every_group = 1.0
	big_wave = false
	hammer_zombie_timer.wait_time = interval_every_group
	flag_progress_bar.visible = false

## 正式战斗仍有效时启动第一小组，并显示原波次进度。
func start_first_wave():
	if not _can_refresh_wave():
		return
	# 外部回调可能结束本轮或重新初始化，显示进度前也确认本次启动仍有效。
	var refresh_generation: int = _refresh_generation
	_on_hammer_zombie_timer_timeout()
	if _can_refresh_wave(refresh_generation):
		flag_progress_bar.visible = true

## 停止小组定时器并禁止已等待的协程恢复刷新；不删除已经生成的僵尸。
func stop_wave_refresh() -> void:
	_refresh_generation += 1
	_refresh_stopped = true
	if is_instance_valid(hammer_zombie_timer):
		hammer_zombie_timer.stop()

## 返回本节点与所属关卡是否仍允许刷新；停止、离树或战斗结束时返回 false。
## [param refresh_generation] 为协程捕获的版本；-1 仅检查当前资格，旧版本一律返回 false。
func _can_refresh_wave(refresh_generation: int = -1) -> bool:
	return (refresh_generation == -1 or refresh_generation == _refresh_generation) \
		and not _refresh_stopped and is_inside_tree() and not is_queued_for_deletion() \
		and is_instance_valid(zombie_manager) and zombie_manager.is_game_running()

## 生成一小组僵尸；等待墓碑准备后重验原关卡，战斗结束时不继续生成。
func create_one_group_min_zombie():
	if not _can_refresh_wave():
		return
	# 本小组只属于捕获的轮次版本，墓碑准备等待后不能跨轮继续生成。
	var refresh_generation: int = _refresh_generation
	# 本次小组所属的关卡引用，等待期间也不会替换为其他全局关卡。
	var game: MainGameManager = zombie_manager.main_game
	# 本小组抽中的普通僵尸类型；大波会按每个墓碑重新抽取。
	var new_zombie_type = curr_zombie_type_candidate.pick_random()
	## 如果当前没有墓碑
	if game.plant_cell_manager.tombstone_list.is_empty():
		EventBus.push_event("create_tombstone", [randi()%3+1])
		await get_tree().create_timer(2).timeout
		if not _can_refresh_wave(refresh_generation):
			return

	# 本小组实际生成数量不能超过当前墓碑数量。
	var real_zombie_num = min(randi_range(1, curr_num_new_zombie_every_group) * zombie_multy, game.plant_cell_manager.tombstone_list.size())
	if big_wave:
		real_zombie_num = game.plant_cell_manager.tombstone_list.size()
		# 大波按墓碑索引逐一创建，回调结束战斗后不继续后续墓碑。
		for i in range(real_zombie_num):
			if not _can_refresh_wave(refresh_generation):
				return
			new_zombie_type = curr_zombie_type_candidate.pick_random()
			game.plant_cell_manager.tombstone_list[i].create_new_zombie(new_zombie_type, curr_speed_zombie)
	else:
		game.plant_cell_manager.tombstone_list.shuffle()
		# 普通小组仅使用打乱后的前几个墓碑。
		for i in range(real_zombie_num):
			if not _can_refresh_wave(refresh_generation):
				return
			game.plant_cell_manager.tombstone_list[i].create_new_zombie(new_zombie_type, curr_speed_zombie)

## 计算当前进度并更新进度条
func set_progress_bar(curr_flag=-1):
	var curr_progress :float = curr_all_group_min_num_sum * progress_bar_segment_every_groud_min
	flag_progress_bar.set_progress(curr_progress, curr_flag)

## 推进本关卡的小组与波次；每次延迟恢复和外部回调返回后重验刷新资格。
func _on_hammer_zombie_timer_timeout() -> void:
	if not _can_refresh_wave():
		return
	# 本次推进固定所属轮次版本，所有延迟及外部回调返回后都拒绝旧版本。
	var refresh_generation: int = _refresh_generation
	# 固定本次回调的关卡，等待期间不读取可能已切换的全局节点。
	var game: MainGameManager = zombie_manager.main_game
	## 如果上一小组为最后一小组
	if curr_group_min == -1:
		curr_wave += 1
	curr_group_min += 1
	curr_all_group_min_num_sum += 1
	## 如果为第10波最后一小组
	if curr_wave % 10 == 9 and curr_group_min == 9:
		await get_tree().create_timer(3).timeout
		if not _can_refresh_wave(refresh_generation):
			return
		set_progress_bar(int(curr_wave/10.0))
		big_wave = true
	else:
		set_progress_bar()
		big_wave = false

	## 生成一小组僵尸
	create_one_group_min_zombie()
	if not _can_refresh_wave(refresh_generation):
		return
	#print("当前波：",curr_wave)
	## 如果是大组的最后一小组（从0开始计数）
	if curr_group_min == 9:
		curr_group_min = -1
		## 如果是最后一大组
		if curr_wave == max_wave - 1:
			## 生成僵尸之后，更新zombie_manager的end_wave,使其管理最后一波僵尸死亡后奖杯
			signal_wave_refresh.emit(true)
			return
		else:
			signal_wave_refresh.emit(false)
			if not _can_refresh_wave(refresh_generation):
				return
			match curr_wave:
				2:
					curr_num_new_zombie_every_group = 2
				4:
					curr_zombie_type_candidate.append(CharacterRegistry.ZombieType.Z003Cone)
				6:
					curr_zombie_type_candidate.append(CharacterRegistry.ZombieType.Z005Bucket)
				8:
					curr_num_new_zombie_every_group = 3
			## 更新僵尸动画速度和小组间隔

			curr_speed_zombie = clampf(curr_speed_zombie+speed_zombie_add, curr_speed_zombie, speed_zombie_max)
			interval_every_group = clampf(interval_every_group-0.05, 0.5, 1.0)

			## 等待3秒创建墓碑后再等待两秒
			await get_tree().create_timer(3).timeout
			if not _can_refresh_wave(refresh_generation):
				return
			if game.plant_cell_manager.tombstone_list.size() >= 5:
				EventBus.push_event("create_tombstone", [1])
			else:
				EventBus.push_event("create_tombstone", [5 - game.plant_cell_manager.tombstone_list.size()])
			await get_tree().create_timer(2).timeout
			if not _can_refresh_wave(refresh_generation):
				return
			hammer_zombie_timer.wait_time = interval_every_group + randf_range(-0.1, 0.1)

	else:
		hammer_zombie_timer.wait_time = interval_every_group + randf_range(-0.1, 0.1)

	hammer_zombie_timer.start()

