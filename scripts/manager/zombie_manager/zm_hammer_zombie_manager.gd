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

## 最多波数
@export var max_wave = 10

## 当前小组数量总和
var curr_all_group_min_num_sum:=-1
var curr_wave := -1		#当前波
var curr_group_min := -1		#当前小组数

## 每一小组的进度条占比（%）
var progress_bar_segment_every_groud_min :float

## 当前可以生成的僵尸类型
var curr_zombie_type_candidate :Array[EnumsCharacter.ZombieType] = [EnumsCharacter.ZombieType.Z001Norm]
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

func init_hammer_zombie_manager(game_para:ResourceLevelData):
	zombie_multy = game_para.zombie_multy_hammer
	max_wave = game_para.max_wave_hammer_zombie
	curr_speed_zombie = game_para.speed_zombie_init
	speed_zombie_add = game_para.speed_zombie_add
	speed_zombie_max = game_para.speed_zombie_max

	## 生成旗帜
	flag_progress_bar.init_flag_from_wave(max_wave)
	progress_bar_segment_every_groud_min = 100.0 / (max_wave*10)

func start_first_wave():
	_on_hammer_zombie_timer_timeout()
	flag_progress_bar.visible = true

## 生成一小组僵尸
func create_one_group_min_zombie():
	var new_zombie_type = curr_zombie_type_candidate.pick_random()
	## 如果当前没有墓碑
	if Global.main_game.plant_cell_manager.tombstone_list.is_empty():
		EventBus.push_event("create_tombstone", [randi()%3+1])
		await get_tree().create_timer(2).timeout

	## 真正生成的僵尸数量
	var real_zombie_num = min(randi_range(1, curr_num_new_zombie_every_group) * zombie_multy, Global.main_game.plant_cell_manager.tombstone_list.size())
	if big_wave:
		real_zombie_num = Global.main_game.plant_cell_manager.tombstone_list.size()
		for i in range(real_zombie_num):
			new_zombie_type = curr_zombie_type_candidate.pick_random()
			Global.main_game.plant_cell_manager.tombstone_list[i].create_new_zombie(new_zombie_type, curr_speed_zombie)
	else:
		Global.main_game.plant_cell_manager.tombstone_list.shuffle()
		for i in range(real_zombie_num):
			Global.main_game.plant_cell_manager.tombstone_list[i].create_new_zombie(new_zombie_type, curr_speed_zombie)

## 计算当前进度并更新进度条
func set_progress_bar(curr_flag=-1):
	var curr_progress :float = curr_all_group_min_num_sum * progress_bar_segment_every_groud_min
	flag_progress_bar.set_progress(curr_progress, curr_flag)

func _on_hammer_zombie_timer_timeout() -> void:
	## 如果上一小组为最后一小组
	if curr_group_min == -1:
		curr_wave += 1
	curr_group_min += 1
	curr_all_group_min_num_sum += 1
	## 如果为第10波最后一小组
	if curr_wave % 10 == 9 and curr_group_min == 9:
		await get_tree().create_timer(3).timeout
		@warning_ignore("integer_division")
		set_progress_bar(curr_wave/10)
		big_wave = true
	else:
		set_progress_bar()
		big_wave = false

	## 生成一小组僵尸
	create_one_group_min_zombie()
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
			match curr_wave:
				2:
					curr_num_new_zombie_every_group = 2
				4:
					curr_zombie_type_candidate.append(EnumsCharacter.ZombieType.Z003Cone)
				6:
					curr_zombie_type_candidate.append(EnumsCharacter.ZombieType.Z005Bucket)
				8:
					curr_num_new_zombie_every_group = 3
			## 更新僵尸动画速度和小组间隔

			curr_speed_zombie = clampf(curr_speed_zombie+speed_zombie_add, curr_speed_zombie, speed_zombie_max)
			interval_every_group = clampf(interval_every_group-0.05, 0.5, 1.0)

			## 等待3秒创建墓碑后再等待两秒
			await get_tree().create_timer(3).timeout
			if Global.main_game.plant_cell_manager.tombstone_list.size() >= 5:
				EventBus.push_event("create_tombstone", [1])
			else:
				EventBus.push_event("create_tombstone", [5 - Global.main_game.plant_cell_manager.tombstone_list.size()])
			await get_tree().create_timer(2).timeout
			hammer_zombie_timer.wait_time = interval_every_group + randf_range(-0.1, 0.1)

	else:
		hammer_zombie_timer.wait_time = interval_every_group + randf_range(-0.1, 0.1)

	hammer_zombie_timer.start()

