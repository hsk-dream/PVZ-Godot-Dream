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
	CharacterRegistry.ZombieType.Z001Norm: 1,		# 普僵战力
	CharacterRegistry.ZombieType.Z002Flag: 1,		# 旗帜战力
	CharacterRegistry.ZombieType.Z003Cone: 2,		# 路障战力
	CharacterRegistry.ZombieType.Z004PoleVaulter: 2,	# 撑杆战力
	CharacterRegistry.ZombieType.Z005Bucket: 4,		# 铁桶战力

	CharacterRegistry.ZombieType.Z006Paper: 2,		# 读报战力
	CharacterRegistry.ZombieType.Z007ScreenDoor: 4,	# 铁门战力
	CharacterRegistry.ZombieType.Z008Football: 7,	# 橄榄球战力
	CharacterRegistry.ZombieType.Z009Jackson: 5,		# 舞王战力
	CharacterRegistry.ZombieType.Z010Dancer: 1,		# 伴舞权重

	CharacterRegistry.ZombieType.Z012Snorkle: 3,		# 潜水
	CharacterRegistry.ZombieType.Z013Zamboni: 7,		# 冰车
	CharacterRegistry.ZombieType.Z014Bobsled: 3,		# 滑雪四兄弟
	CharacterRegistry.ZombieType.Z015Dolphinrider: 3,# 海豚僵尸

	CharacterRegistry.ZombieType.Z016Jackbox: 3,		# 小丑
	CharacterRegistry.ZombieType.Z017Balloon: 2,		# 气球
	CharacterRegistry.ZombieType.Z018Digger: 4,		# 矿工
	CharacterRegistry.ZombieType.Z019Pogo: 4,			# 跳跳
	CharacterRegistry.ZombieType.Z020Yeti: 4,			# 雪人

	CharacterRegistry.ZombieType.Z022Ladder: 4,		# 扶梯
	CharacterRegistry.ZombieType.Z023Catapult: 5,		# 投篮
	CharacterRegistry.ZombieType.Z024Gargantuar: 10,	# 伽刚特尔
	CharacterRegistry.ZombieType.Z025Imp: 1,			# 小鬼
}

## 本管理器独立维护的运行时权重，实例创建时复制注册表基础数据，后续按自然波次调整。[br]
## 键和值均为整数值类型，普通复制即可隔离修改，无需深度复制。
var zombie_weights: Dictionary[CharacterRegistry.ZombieType, int] = CharacterRegistry.ZombieSpawnWeights.duplicate()

## 僵尸随机选择池
var zombie_choose_random_pool:RandomPicker

## 每波最大僵尸数量
@export var max_zombies_per_wave = 50
## 刷新类型最小战力
var min_power:=100
## 当前波次生成的僵尸
var wave_all_zombies:Array[Zombie000Base]

## 使用 [param game_para] 初始化波次生成配置、选行系统和随机池，保留本实例已有的运行时权重。
func init_zombie_wave_create_manager(game_para:ResourceLevelData):
	zombie_multy = game_para.zombie_multy
	range_num_bungi = game_para.range_num_bungi
	zombie_choose_row_system.init_zombie_choose_row_system(zombie_manager.all_zombie_rows)
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
	var wave_spawn :Array[CharacterRegistry.ZombieType] = create_curr_wave_zombie_list(wave, is_big_wave)
	## 特殊基础权重,若有雪橇车僵尸,更新该权重
	var special_base_weight:Array[float] = []
	wave_all_zombies.clear()
	## 当前波次僵尸数据
	var curr_wave_zombie_date:Array[Dictionary]

	for i in range(wave_spawn.size()):
		var zombie_type : CharacterRegistry.ZombieType = wave_spawn[i]
		var lane :int = -1
		## 雪橇车僵尸
		if zombie_type == CharacterRegistry.ZombieType.Z014Bobsled:
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
				zombie_type = CharacterRegistry.ZombieType.Z013Zamboni
				lane = zombie_choose_row_system.select_spawn_row(Global.character_registry.ZombieInfo[zombie_type][CharacterRegistry.ZombieInfoAttribute.ZombieRowType])
			else:
				lane = zombie_choose_row_system.select_spawn_row(Global.character_registry.ZombieInfo[zombie_type][CharacterRegistry.ZombieInfoAttribute.ZombieRowType], special_base_weight)
		else:
			lane = zombie_choose_row_system.select_spawn_row(Global.character_registry.ZombieInfo[zombie_type][CharacterRegistry.ZombieInfoAttribute.ZombieRowType])
		# 选行失败时跳过该项，不能把 -1 作为最后一行索引使用。
		if lane < 0:
			continue
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
		if is_instance_valid(zombie):
			wave_all_zombies.append(zombie)

	return wave_all_zombies


## 生成波次僵尸
func wave_create_zombie(
	zombie_type:CharacterRegistry.ZombieType,
	lane:int, 	## 僵尸行
	curr_wave:int,		## 僵尸波次
	init_zombie_special:Callable = Callable()		## 初始化僵尸特殊属性
):
	# 直接调用者也必须使用真实存在的行，防止错误下标进入通用创建入口。
	if lane < 0 or lane >= zombie_manager.all_zombie_rows.size():
		return null
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
## 根据零起始波次 [param wave] 和大波标记 [param is_big_wave] 返回本波僵尸类型列表。[br]
## 每次生成前同步权重与随机池，确保直接载入后期波次也使用对应的衰减权重。
func create_curr_wave_zombie_list(wave:int, is_big_wave:bool):
	# 本波可分配给僵尸的战力总额。
	var curr_wave_power_limit = calculate_wave_power_limit(wave, is_big_wave)
	# 按当前波次直接计算，不能依赖先前波次曾经更新过权重。
	_update_weights(wave)
	# 按本波权重和战力预算抽取的僵尸类型列表。
	var wave_spawn :Array[CharacterRegistry.ZombieType] = get_curr_wave_zombie_list(wave, is_big_wave, curr_wave_power_limit)

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

## 按零起始自然波次 [param wave] 更新权重及随机池；本函数独立维护自然出怪的成长规则。[br]
## 每次从注册表基础值计算，重复调用不会累加衰减，超过索引 25 后保持末档权重。
func _update_weights(wave: int) -> void:
	zombie_weights = CharacterRegistry.ZombieSpawnWeights.duplicate()
	# 前六波保持基础权重，之后最多衰减二十档，保留原自然出怪公式。
	var decay_steps: int = clampi(wave - 5, 0, 20)
	zombie_weights[CharacterRegistry.ZombieType.Z001Norm] -= decay_steps * 180
	zombie_weights[CharacterRegistry.ZombieType.Z003Cone] -= decay_steps * 150
	# 只有这两种类型随进度衰减，其余随机池条目保持基础权重。
	for zombie_type: CharacterRegistry.ZombieType in [CharacterRegistry.ZombieType.Z001Norm, CharacterRegistry.ZombieType.Z003Cone]:
		if zombie_type in zombie_manager.zombie_refresh_types:
			zombie_choose_random_pool.update_item_weight(zombie_type, zombie_weights[zombie_type], false)
	zombie_choose_random_pool.rebuild_alias_table()

## 获取当前波僵尸列表
func get_curr_wave_zombie_list(wave:int, is_big_wave: bool, curr_wave_power_limit:int) ->Array[CharacterRegistry.ZombieType]:
	## 当前波的僵尸列表
	var wave_spawn :Array[CharacterRegistry.ZombieType]= []
	## 目前总战力
	var total_power = 0
	## 当前空隙位置
	var curr_spare_slot = max_zombies_per_wave

	## 如果是大波，先刷新特殊僵尸
	if is_big_wave:
		## 第一个旗帜僵尸
		wave_spawn.append(CharacterRegistry.ZombieType.Z002Flag)
		total_power += zombie_power[CharacterRegistry.ZombieType.Z002Flag]
		curr_spare_slot -= 1

		# 第一次大波（第10波），刷新4个普通僵尸
		if wave == 9:
			for i in range(4):
				wave_spawn.append(CharacterRegistry.ZombieType.Z001Norm)
				total_power += zombie_power[CharacterRegistry.ZombieType.Z001Norm]
				curr_spare_slot -= 1
		# 之后的大波（第20波、30波...），刷新8个普通僵尸
		else:
			for i in range(8):
				wave_spawn.append(CharacterRegistry.ZombieType.Z001Norm)
				total_power += zombie_power[CharacterRegistry.ZombieType.Z001Norm]
				curr_spare_slot -= 1

	# 生成剩余僵尸，直到总战力符合当前战力上限
	while curr_spare_slot > 0 and total_power < curr_wave_power_limit:

		var selected_zombie:CharacterRegistry.ZombieType = zombie_choose_random_pool.get_random_item()
		var zombie_power_value = zombie_power[selected_zombie]

		#prints("当前剩余僵尸", curr_spare_slot, "当前战力:", total_power, "当前所选僵尸:", selected_zombie, "当前所选僵尸战力:", zombie_power_value)

		# 检查如果加上该僵尸的战力后超过当前波的战力上限，重新选择
		if total_power + zombie_power_value <= curr_wave_power_limit:
			wave_spawn.append(selected_zombie)
			total_power += zombie_power_value
			curr_spare_slot -= 1
		elif curr_wave_power_limit - total_power < min_power:
			for i in range(curr_wave_power_limit - total_power):
				wave_spawn.append(CharacterRegistry.ZombieType.Z001Norm)
				total_power += zombie_power[CharacterRegistry.ZombieType.Z001Norm]
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
		if zombie_manager.all_zombie_rows[i].zombie_row_type == CharacterRegistry.ZombieRowType.Pool:
			zombie_row_pool_i.append(i)
	if zombie_row_pool_i.is_empty():
		print("无水路,无法生成珊瑚僵尸")
		return

	var zombie_type_sea_weed_list :Array= [CharacterRegistry.ZombieType.Z001Norm, CharacterRegistry.ZombieType.Z003Cone, CharacterRegistry.ZombieType.Z005Bucket]

	for i in range(3):
		var zombie_type:CharacterRegistry.ZombieType = zombie_type_sea_weed_list.pick_random()
		var lane:int= zombie_row_pool_i.pick_random()
		var zombie_sea_weed:Zombie000Base = wave_create_zombie(zombie_type, lane, -1, _zombie_seaweed)

		if is_instance_valid(zombie_sea_weed):
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
			CharacterRegistry.ZombieType.Z021Bungi,
			zombie_manager.all_zombie_rows[plant_cell.row_col.x],
			zombie_init_para,
			Vector2(plant_cell.global_position.x + plant_cell.size.x/2,
				zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_create_position.global_position.y
			),
			GlobalUtils.create_bungi.bind(plant_cell)
		)

#endregion

#endregion
