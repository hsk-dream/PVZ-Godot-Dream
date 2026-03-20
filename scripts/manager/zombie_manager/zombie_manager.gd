extends Node
class_name ZombieManager

@onready var main_game: MainGameManager = $"../.."
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

#region 僵尸管理器参数
## 刷怪类型
var is_bungi = false
var zombie_refresh_types = []

## 出怪模式
var monster_mode:ResourceLevelData.E_MonsterMode = ResourceLevelData.E_MonsterMode.Norm
## 是否为僵尸快跑模式
var is_mini_zombie := false
## 是否为我是僵尸模式
var is_zombie_mode:=false
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
func init_zombie_manager(game_para:ResourceLevelData):
	## 出怪模式
	monster_mode = game_para.monster_mode
	## 是否为僵尸快跑模式
	is_mini_zombie = game_para.is_mini_zombie
	## 是否为我是僵尸模式
	is_zombie_mode = game_para.is_zombie_mode
	match monster_mode:
		## 没有僵尸刷新,直接启动最后一波僵尸检查计时器
		ResourceLevelData.E_MonsterMode.Null:
			check_zombie_end_wave_timer.start()

		ResourceLevelData.E_MonsterMode.Norm:
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

		ResourceLevelData.E_MonsterMode.HammerZombie:
			hammer_zombie_manager.init_hammer_zombie_manager(game_para)
			## 波次刷新时判断是否为最后一波，删除多余魅惑僵尸
			hammer_zombie_manager.signal_wave_refresh.connect(wave_refresh)

## 开始第一波
func start_game():
	match monster_mode:
		ResourceLevelData.E_MonsterMode.Null:
			return

		ResourceLevelData.E_MonsterMode.Norm:
			## 10秒后开始刷新僵尸
			await get_tree().create_timer(10).timeout
			zombie_wave_manager.start_first_wave()

		ResourceLevelData.E_MonsterMode.HammerZombie:
			await get_tree().create_timer(2).timeout
			hammer_zombie_manager.start_first_wave()

#region 生成僵尸
## 生成一个正常出战僵尸，所有出战僵尸都要从这里生成
func create_norm_zombie(
	zombie_type:EnumsCharacter.ZombieType,	## 僵尸类型
	zombie_parent:Node,				## 僵尸父节点
	zombie_init_para:Dictionary,			## 僵尸初始化参数
	global_pos:Vector2=Vector2.ZERO,
	init_zombie_special:Callable = Callable()		## 初始化僵尸特殊属性
) -> Zombie000Base:
	var zombie:Zombie000Base = Global.character_registry.get_zombie_info(zombie_type, EnumsCharacter.ZombieInfoAttribute.ZombieScenes).instantiate()
	zombie_init_para[Zombie000Base.E_ZInitAttr.IsMiniZombie] = is_mini_zombie
	zombie_init_para[Zombie000Base.E_ZInitAttr.IsZombieMode] = is_zombie_mode

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

	## 如果到了最后一波刷新,且最后一个僵尸被魅惑
	if is_end_wave and curr_zombie_num == 0:
		EventBus.push_event("create_trophy", [zombie.global_position])
		if is_instance_valid(multi_round_end_wave_timer):
			multi_round_end_wave_timer.stop()

## 僵尸发射死亡信号后调用函数
func _on_zombie_dead(zombie: Zombie000Base) -> void:
	all_zombies_1d.erase(zombie)
	if zombie.is_hypno:
		all_zombies_be_hypno.erase(zombie)
	else:
		curr_zombie_num -= 1
		all_zombies_2d[zombie.lane].erase(zombie)

		## 如果到了最后一波刷新,且僵尸全部死亡
		if is_end_wave and curr_zombie_num == 0:
			EventBus.push_event("create_trophy", [zombie.global_position])
			if is_instance_valid(multi_round_end_wave_timer):
				multi_round_end_wave_timer.stop()
#endregion

#region 波次刷新
func wave_refresh(curr_is_end_wave:bool):
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
	match monster_mode:
		ResourceLevelData.E_MonsterMode.Norm:
			check_zombie_end_wave_timer.stop()
			## 更新当前轮次的出怪列表
			update_multi_round_zombie_refresh_types(main_game.curr_game_round, main_game.game_para.game_sences)
			zombie_wave_manager.start_next_game_zombie_wave_mananger_update()

	## 我是僵尸模式删除所有的僵尸
	if is_zombie_mode:
		for i in range(all_zombies_1d.size()-1,-1,-1):
			var zombie:Zombie000Base = all_zombies_1d[i]
			zombie.character_death_disappear()

#endregion


#region 多轮(无尽)出怪
## 多轮出怪获取出怪列表
func update_multi_round_zombie_refresh_types(curr_round:int, game_sences:EnumsMainScene.MainScenes) -> void:
	## 清空数据
	is_bungi = false
	zombie_refresh_types.clear()
	# 第一次选卡 (curr_round == 1) 的 “固定三种”：普僵 + 路障 + 铁桶
	if curr_round == 1:
		zombie_refresh_types.append(EnumsCharacter.ZombieType.Z001Norm)
		zombie_refresh_types.append(EnumsCharacter.ZombieType.Z003Cone)
		zombie_refresh_types.append(EnumsCharacter.ZombieType.Z005Bucket)
	else:
		var whitelist_refresh_zombie_types_copy = Global.whitelist_refresh_zombie_types_with_zombie_row_type[Global.main_scene_registry.ZombieRowTypewithMainScenesMap[game_sences]].duplicate(true)
		zombie_refresh_types.append(EnumsCharacter.ZombieType.Z001Norm)
		whitelist_refresh_zombie_types_copy.erase(EnumsCharacter.ZombieType.Z001Norm)
		# 第二种：80% 路障 (Cone)，20% 报纸 (Paper)
		var prob = randf()
		if prob < 0.8:
			zombie_refresh_types.append(EnumsCharacter.ZombieType.Z003Cone)
			whitelist_refresh_zombie_types_copy.erase(EnumsCharacter.ZombieType.Z003Cone)
		else:
			zombie_refresh_types.append(EnumsCharacter.ZombieType.Z006Paper)
			whitelist_refresh_zombie_types_copy.erase(EnumsCharacter.ZombieType.Z006Paper)
		## 第二轮之后可能刷新僵尸(min(轮次*2,8)+2)个
		for i in range(min(curr_round * 2, 8)):
			var zombie_type_choose = whitelist_refresh_zombie_types_copy.pick_random()
			zombie_refresh_types.append(zombie_type_choose)
			whitelist_refresh_zombie_types_copy.erase(zombie_type_choose)

			if zombie_type_choose == EnumsCharacter.ZombieType.Z021Bungi:
				print("warning: 出怪刷新列表禁止使用 Z021Bungi ,已修改为选择 is_bungi 参数")
				is_bungi = true
				zombie_refresh_types.erase(zombie_type_choose)

			if whitelist_refresh_zombie_types_copy.is_empty():
				break

	print("当前轮次", curr_round,"可能刷新的僵尸类型有:")
	for zombie_type in zombie_refresh_types:
		print(Global.character_registry.get_zombie_info(zombie_type, EnumsCharacter.ZombieInfoAttribute.ZombieName))
	if is_bungi:
		print(Global.character_registry.get_zombie_info(EnumsCharacter.ZombieType.Z021Bungi, EnumsCharacter.ZombieInfoAttribute.ZombieName))


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
