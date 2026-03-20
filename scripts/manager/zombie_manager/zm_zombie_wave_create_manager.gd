extends Node
## 僵尸波次生成管理器
class_name ZombieWaveCreateManager

#region 波次生成僵尸管理器参数
## 出怪倍率
var zombie_multy := 1
## 蹦极僵尸数量范围
var range_num_bungi:Vector2i = Vector2i(3,5)
#endregion
@onready var zombie_manager: ZombieManager = %ZombieManager

## 僵尸选行系统
@onready var zombie_choose_row_system: ZombieChooseRowSystem = %ZombieChooseRowSystem

## 定义每个僵尸的战力值
const zombie_power = {
	EnumsCharacter.ZombieType.Z001Norm: 1,		# 普僵战力
	EnumsCharacter.ZombieType.Z002Flag: 1,		# 旗帜战力
	EnumsCharacter.ZombieType.Z003Cone: 2,		# 路障战力
	EnumsCharacter.ZombieType.Z004PoleVaulter: 2,	# 撑杆战力
	EnumsCharacter.ZombieType.Z005Bucket: 4,		# 铁桶战力

	EnumsCharacter.ZombieType.Z006Paper: 2,		# 读报战力
	EnumsCharacter.ZombieType.Z007ScreenDoor: 4,	# 铁门战力
	EnumsCharacter.ZombieType.Z008Football: 7,	# 橄榄球战力
	EnumsCharacter.ZombieType.Z009Jackson: 5,		# 舞王战力
	EnumsCharacter.ZombieType.Z010Dancer: 1,		# 伴舞权重

	EnumsCharacter.ZombieType.Z012Snorkle: 3,		# 潜水
	EnumsCharacter.ZombieType.Z013Zamboni: 7,		# 冰车
	EnumsCharacter.ZombieType.Z014Bobsled: 3,		# 滑雪四兄弟
	EnumsCharacter.ZombieType.Z015Dolphinrider: 3,# 海豚僵尸

	EnumsCharacter.ZombieType.Z016Jackbox: 3,		# 小丑
	EnumsCharacter.ZombieType.Z017Balloon: 2,		# 气球
	EnumsCharacter.ZombieType.Z018Digger: 4,		# 矿工
	EnumsCharacter.ZombieType.Z019Pogo: 4,			# 跳跳
	EnumsCharacter.ZombieType.Z020Yeti: 4,			# 雪人

	EnumsCharacter.ZombieType.Z022Ladder: 4,		# 扶梯
	EnumsCharacter.ZombieType.Z023Catapult: 5,		# 投篮
	EnumsCharacter.ZombieType.Z024Gargantuar: 10,	# 伽刚特尔
	EnumsCharacter.ZombieType.Z025Imp: 1,			# 小鬼
}

## 创建 zombie_weights 字典，存储初始权重,普僵权重会修改，
var zombie_weights:Dictionary = zombie_weights_ori.duplicate_deep()
const zombie_weights_ori = {
	EnumsCharacter.ZombieType.Z001Norm: 4000,			# 普僵权重
	#EnumsCharacter.ZombieType.Z002Flag: 0,			# 旗帜权重
	EnumsCharacter.ZombieType.Z003Cone: 4000,			# 路障权重
	EnumsCharacter.ZombieType.Z004PoleVaulter: 2000,	# 撑杆权重
	EnumsCharacter.ZombieType.Z005Bucket: 3000,		# 铁桶权重

	EnumsCharacter.ZombieType.Z006Paper: 1000,		# 读报权重
	EnumsCharacter.ZombieType.Z007ScreenDoor: 3500,	# 铁门权重
	EnumsCharacter.ZombieType.Z008Football: 2000,		# 橄榄球权重
	EnumsCharacter.ZombieType.Z009Jackson: 1000,		# 舞王权重
	EnumsCharacter.ZombieType.Z010Dancer: 4000,		# 舞王权重

	EnumsCharacter.ZombieType.Z012Snorkle: 2000,		# 潜水
	EnumsCharacter.ZombieType.Z013Zamboni: 2000,		# 冰车
	EnumsCharacter.ZombieType.Z014Bobsled: 2000,		# 滑雪四兄弟
	EnumsCharacter.ZombieType.Z015Dolphinrider: 1500,	# 海豚僵尸

	EnumsCharacter.ZombieType.Z016Jackbox: 1000,		# 小丑
	EnumsCharacter.ZombieType.Z017Balloon: 2000,		# 气球
	EnumsCharacter.ZombieType.Z018Digger: 1000,		# 矿工
	EnumsCharacter.ZombieType.Z019Pogo: 1000,			# 跳跳
	EnumsCharacter.ZombieType.Z020Yeti: 1,			# 雪人

	EnumsCharacter.ZombieType.Z022Ladder: 1000,		# 扶梯
	EnumsCharacter.ZombieType.Z023Catapult: 1500,	# 投篮
	EnumsCharacter.ZombieType.Z024Gargantuar: 1500,	# 伽刚特尔
	#EnumsCharacter.ZombieType.Z025Imp: 0,		# 小鬼
}

## 僵尸随机选择池
var zombie_choose_random_pool:RandomPicker

## 每波最大僵尸数量
@export var max_zombies_per_wave = 50
## 刷新类型最小战力
var min_power:=100
## 当前所有可能出怪僵尸权重上限和,每波修改
var curr_zombie_weight_upper_limit :int
## 当前波次生成的僵尸
var wave_all_zombies:Array[Zombie000Base]

## 初始化创建波次僵尸管理器
func init_zombie_wave_create_manager(game_para:ResourceLevelData):
	zombie_multy = game_para.zombie_multy
	range_num_bungi = game_para.range_num_bungi
	zombie_choose_row_system.init_zombie_choose_row_system()
	update_zombie_refresh_types()

## 更新可以刷新的僵尸列表
func update_zombie_refresh_types():
	## 初始化僵尸生成随机池数据
	var zombie_choose_random_pool_data:Array[Array] = []
	min_power = 100
	for zombie_type in zombie_manager.zombie_refresh_types:
		if min_power > zombie_power[zombie_type]:
			min_power = zombie_power[zombie_type]
		zombie_choose_random_pool_data.append([zombie_type, zombie_weights[zombie_type]])
	print("更新僵尸随机选择池")
	zombie_choose_random_pool = RandomPicker.new(zombie_choose_random_pool_data)


#region 创建当前波次僵尸
## 创建当前波僵尸
func create_curr_wave_all_zombies(wave:int, is_big_wave:bool):
	## 获取当前波僵尸生成列表
	var wave_spawn :Array[EnumsCharacter.ZombieType] = create_curr_wave_zombie_list(wave, is_big_wave)
	## 特殊基础权重,若有雪橇车僵尸,更新该权重
	var special_base_weight:Array[float] = []
	wave_all_zombies.clear()
	## 当前波次僵尸数据
	var curr_wave_zombie_date:Array[Dictionary]

	for i in range(wave_spawn.size()):
		var zombie_type : EnumsCharacter.ZombieType = wave_spawn[i]
		var lane :int = -1
		## 雪橇车僵尸
		if zombie_type == EnumsCharacter.ZombieType.Z014Bobsled:
			## 计算冰道权重
			if special_base_weight.is_empty():
				for row_ice_road:Array[IceRoad] in zombie_manager.all_ice_roads:
					if row_ice_road.is_empty():
						special_base_weight.append(0)
					else:
						special_base_weight.append(1)
				print(special_base_weight)
			## 如果没有冰道
			if GlobalUtils.sum_arr(special_base_weight) == 0:
				zombie_type = EnumsCharacter.ZombieType.Z013Zamboni
				lane = zombie_choose_row_system.select_spawn_row(Global.character_registry.ZombieInfo[zombie_type][EnumsCharacter.ZombieInfoAttribute.ZombieRowType])
			else:
				lane = zombie_choose_row_system.select_spawn_row(Global.character_registry.ZombieInfo[zombie_type][EnumsCharacter.ZombieInfoAttribute.ZombieRowType], special_base_weight)
		else:
			lane = zombie_choose_row_system.select_spawn_row(Global.character_registry.ZombieInfo[zombie_type][EnumsCharacter.ZombieInfoAttribute.ZombieRowType])
		curr_wave_zombie_date.append(
			{
				"zombie_type":zombie_type,
				"lane":lane,
			}
		)
	for curr_wave_one_zombie_date in curr_wave_zombie_date:
		var zombie = wave_create_zombie(
			curr_wave_one_zombie_date["zombie_type"],
			curr_wave_one_zombie_date["lane"],
			wave
		)
		wave_all_zombies.append(zombie)

	return wave_all_zombies


## 生成波次僵尸
func wave_create_zombie(
	zombie_type:EnumsCharacter.ZombieType,
	lane:int, 	## 僵尸行
	curr_wave:int,		## 僵尸波次
	init_zombie_special:Callable = Callable()		## 初始化僵尸特殊属性
):
	var zombie_init_para:Dictionary = {
		Zombie000Base.E_ZInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsNorm,
		Zombie000Base.E_ZInitAttr.Lane:lane,
		Zombie000Base.E_ZInitAttr.CurrWave:curr_wave,
	}
	var zombie_parent = zombie_manager.all_zombie_rows[lane]
	var zombie_glo_pos = zombie_manager.all_zombie_rows[lane].zombie_create_position.global_position + Vector2(randf_range(-10, 10), 0)

	var zombie = zombie_manager.create_norm_zombie(zombie_type,zombie_parent,zombie_init_para, zombie_glo_pos, init_zombie_special)

	return zombie

#region 创建当前波僵尸生成列表
## 创建当前波僵尸生成列表
func create_curr_wave_zombie_list(wave:int, is_big_wave:bool):
	## 计算当前波僵尸战力上限
	var curr_wave_power_limit = calculate_wave_power_limit(wave, is_big_wave)
	## 更新僵尸权重上限
	update_curr_zombie_weight_upper_limit(wave)
	## 获取当前波的生成僵尸列表
	var wave_spawn :Array[EnumsCharacter.ZombieType] = get_curr_wave_zombie_list(wave, is_big_wave, curr_wave_power_limit)

	return wave_spawn

## 计算每波的战力上限
func calculate_wave_power_limit(wave:int, is_big_wave: bool) -> int:
	## x从0开始
	## 计算战力上限 = y=int(x/3)+1
	@warning_ignore("integer_division")
	var base_power_limit:int = wave / 3 + 1
	## 如果是大波，战力上限是原战力上限的2.5倍
	if is_big_wave:
		return int(base_power_limit * 2.5) * zombie_multy

	return base_power_limit * zombie_multy

## 计算当前波僵尸权重上限
func update_curr_zombie_weight_upper_limit(wave:int):
	## 如果是第0波
	if wave == 0:
		curr_zombie_weight_upper_limit = 0
		# 计算所有可能僵尸的权重总和
		for zombie_type in zombie_manager.zombie_refresh_types:
			curr_zombie_weight_upper_limit += zombie_weights[zombie_type]
	elif wave < 4:
		pass
	elif wave < 26:
		_update_weights(wave)
		curr_zombie_weight_upper_limit = 0
		# 计算所有可能僵尸的权重总和
		for zombie_type in zombie_manager.zombie_refresh_types:
			curr_zombie_weight_upper_limit += zombie_weights[zombie_type]
	else:
		pass
## 更新权重到达上限后最后一次已经更新
var is_update_weight_on_limit:=false

## 更新僵尸权重
func _update_weights(wave: int):
	if wave >= 5:
		if wave >= 25:
			if is_update_weight_on_limit:
				return
			is_update_weight_on_limit = true
			print("更新权重")
			wave = 25

		var norm_weight = 4000 - (wave - 5) * 180
		zombie_weights[EnumsCharacter.ZombieType.Z001Norm] = norm_weight
		if EnumsCharacter.ZombieType.Z001Norm in zombie_manager.zombie_refresh_types:
			zombie_choose_random_pool.update_item_weight(EnumsCharacter.ZombieType.Z001Norm, norm_weight, false)
		var cone_weight = 4000 - (wave - 5) * 150
		zombie_weights[EnumsCharacter.ZombieType.Z003Cone] = cone_weight
		if EnumsCharacter.ZombieType.Z003Cone in zombie_manager.zombie_refresh_types:
			zombie_choose_random_pool.update_item_weight(EnumsCharacter.ZombieType.Z003Cone, cone_weight, false)

		zombie_choose_random_pool.rebuild_alias_table()

## 获取当前波僵尸列表
func get_curr_wave_zombie_list(wave:int, is_big_wave: bool, curr_wave_power_limit:int) ->Array[EnumsCharacter.ZombieType]:
	## 当前波的僵尸列表
	var wave_spawn :Array[EnumsCharacter.ZombieType]= []
	## 目前总战力
	var total_power = 0
	## 当前空隙位置
	var curr_spare_slot = max_zombies_per_wave

	## 如果是大波，先刷新特殊僵尸
	if is_big_wave:
		## 第一个旗帜僵尸
		wave_spawn.append(EnumsCharacter.ZombieType.Z002Flag)
		total_power += zombie_power[EnumsCharacter.ZombieType.Z002Flag]
		curr_spare_slot -= 1

		# 第一次大波（第10波），刷新4个普通僵尸
		if wave == 9:
			for i in range(4):
				wave_spawn.append(EnumsCharacter.ZombieType.Z001Norm)
				total_power += zombie_power[EnumsCharacter.ZombieType.Z001Norm]
				curr_spare_slot -= 1
		# 之后的大波（第20波、30波...），刷新8个普通僵尸
		else:
			for i in range(8):
				wave_spawn.append(EnumsCharacter.ZombieType.Z001Norm)
				total_power += zombie_power[EnumsCharacter.ZombieType.Z001Norm]
				curr_spare_slot -= 1

	# 生成剩余僵尸，直到总战力符合当前战力上限
	while curr_spare_slot > 0 and total_power < curr_wave_power_limit:

		var selected_zombie:EnumsCharacter.ZombieType = zombie_choose_random_pool.get_random_item()
		var zombie_power_value = zombie_power[selected_zombie]

		#prints("当前剩余僵尸", curr_spare_slot, "当前战力:", total_power, "当前所选僵尸:", selected_zombie, "当前所选僵尸战力:", zombie_power_value)

		# 检查如果加上该僵尸的战力后超过当前波的战力上限，重新选择
		if total_power + zombie_power_value <= curr_wave_power_limit:
			wave_spawn.append(selected_zombie)
			total_power += zombie_power_value
			curr_spare_slot -= 1
		elif curr_wave_power_limit - total_power < min_power:
			for i in range(curr_wave_power_limit - total_power):
				wave_spawn.append(EnumsCharacter.ZombieType.Z001Norm)
				total_power += zombie_power[EnumsCharacter.ZombieType.Z001Norm]
				curr_spare_slot -= 1
			continue
		else:
			continue

	return wave_spawn

#endregion

#endregion

#region 大波僵尸时生成特殊僵尸
## 大波僵尸时创建特殊僵尸
## [is_final:bool] 是否为最后一波
func spawn_special_zombie_in_big_wave(is_final:=false):
	## 珊瑚僵尸,若有水路自动创建,没有则不创建
	if is_final:
		if not zombie_manager.is_ice:
			print("生成珊瑚僵尸")
			spawn_sea_weed_zombies()
		else:
			print("被冰冻无法生成珊瑚僵尸")
	## 如果有蹦极僵尸
	if zombie_manager.is_bungi:
		spawn_bungi_zombies()

#region 珊瑚僵尸
## 最后一大波珊瑚僵尸
func spawn_sea_weed_zombies():
	var zombie_row_pool_i :Array[int]
	for i in range(zombie_manager.all_zombie_rows.size()):
		if zombie_manager.all_zombie_rows[i].zombie_row_type == EnumsCharacter.ZombieRowType.Pool:
			zombie_row_pool_i.append(i)
	if zombie_row_pool_i.is_empty():
		print("无水路,无法生成珊瑚僵尸")
		return

	var zombie_type_sea_weed_list :Array= [EnumsCharacter.ZombieType.Z001Norm, EnumsCharacter.ZombieType.Z003Cone, EnumsCharacter.ZombieType.Z005Bucket]

	for i in range(3):
		var zombie_type:EnumsCharacter.ZombieType = zombie_type_sea_weed_list.pick_random()
		var lane:int= zombie_row_pool_i.pick_random()
		var zombie_sea_weed:Zombie000Base = wave_create_zombie(zombie_type, lane, -1, _zombie_seaweed)

		zombie_sea_weed.global_position.x = randf_range(500, 750)

## 珊瑚僵尸
func _zombie_seaweed(z:Zombie001Norm):
	z.is_seaweed = true
#endregion

#region 蹦极僵尸
func spawn_bungi_zombies():
	## 选择plant_cell
	var num_bungi_rand:int = randi_range(range_num_bungi.x, range_num_bungi.y)
	var all_cell_have_plant:Array[PlantCell] = zombie_manager.main_game.plant_cell_manager.get_cell_have_plant()
	var num_bungi_res:int = min(num_bungi_rand, all_cell_have_plant.size())
	## 打乱顺序
	all_cell_have_plant.shuffle()
	## 蹦极僵尸选中的plant_cell
	var all_cell_be_bungi = all_cell_have_plant.slice(0, num_bungi_res)
	## 生成蹦极僵尸
	for plant_cell:PlantCell in all_cell_be_bungi:
		var zombie_init_para:Dictionary = {
			Zombie000Base.E_ZInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsNorm,
			Zombie000Base.E_ZInitAttr.Lane:plant_cell.row_col.x
		}

		zombie_manager.create_norm_zombie(
			EnumsCharacter.ZombieType.Z021Bungi,
			zombie_manager.all_zombie_rows[plant_cell.row_col.x],
			zombie_init_para,
			Vector2(plant_cell.global_position.x + plant_cell.size.x/2,
				zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_create_position.global_position.y
			),
			GlobalUtils.create_bungi.bind(plant_cell)
		)

#endregion

#endregion
