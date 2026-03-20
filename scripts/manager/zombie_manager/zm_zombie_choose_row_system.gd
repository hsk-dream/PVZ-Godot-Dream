extends Node
class_name ZombieChooseRowSystem

## 每行的基础权重
var base_weight: Array[float] = []
var base_weigth_all_type :Dictionary[EnumsCharacter.ZombieRowType, Array]

var last_picked: Array[int] = []
var second_last_picked: Array[int] = []

var curr_type: EnumsCharacter.ZombieRowType = EnumsCharacter.ZombieRowType.Land
## 基础权重之和
var total_base_weight :float= 0
var total_base_weight_all_type :Dictionary[EnumsCharacter.ZombieRowType, float]


## 初始化系统
func init_zombie_choose_row_system():
	var ori_weight_land:Array[float] = []
	var ori_weight_pool:Array[float] = []
	var ori_weight_both:Array[float] = []
	for zombie_row_node: ZombieRow in Global.main_game.zombie_manager.all_zombie_rows:
		match zombie_row_node.zombie_row_type:
			EnumsCharacter.ZombieRowType.Land:
				ori_weight_land.append(1)
				ori_weight_pool.append(0)
			EnumsCharacter.ZombieRowType.Pool:
				ori_weight_land.append(0)
				ori_weight_pool.append(1)
			EnumsCharacter.ZombieRowType.Both:
				ori_weight_land.append(1)
				ori_weight_pool.append(1)
		ori_weight_both.append(1.0)

	base_weigth_all_type = {
		EnumsCharacter.ZombieRowType.Land:ori_weight_land,
		EnumsCharacter.ZombieRowType.Pool:ori_weight_pool,
		EnumsCharacter.ZombieRowType.Both:ori_weight_both
	}

	last_picked = [0,0,0,0,0,0]
	second_last_picked = [0,0,0,0,0,0]
	for i in base_weigth_all_type.keys():
		#var curr_type_base_weigth:Array[float] = base_weigth_all_type[i]
		total_base_weight_all_type[i] = GlobalUtils.sum_arr(base_weigth_all_type[i])

## 更新行历史
func on_zombie_spawned(row_index: int):
	assert(row_index >= 0 and row_index < 6, "行号必须在0-5之间")

	for i in range(6):
		last_picked[i] += 1
		second_last_picked[i] += 1

	second_last_picked[row_index] = last_picked[row_index]
	last_picked[row_index] = 0

## 计算平滑权重
func calculate_smooth_weights(zombie_row_type: EnumsCharacter.ZombieRowType, special_base_weight: Array = []) -> Array:
	var smooth_weights: Array[float] = []
	if not special_base_weight.is_empty():
		print("使用临时特殊基础权重")
		base_weight = special_base_weight
		total_base_weight = GlobalUtils.sum_arr(base_weight)
	else:
		base_weight = base_weigth_all_type[zombie_row_type]
		total_base_weight = total_base_weight_all_type[zombie_row_type]

	for i in range(Global.main_game.zombie_manager.all_zombie_rows.size()):
		if base_weight[i] <= 0 or total_base_weight <= 0:
			smooth_weights.append(0.0)
			continue

		var weight_p = base_weight[i] / total_base_weight

		var p_last = (6.0 * last_picked[i] * weight_p + 6.0 * weight_p - 3.0) / 4.0
		var p_second_last = (second_last_picked[i] * weight_p + weight_p - 1.0) / 4.0

		var combined = p_last + p_second_last
		combined = clamp(combined, 0.01, 100.0)
		var smooth_weight = weight_p * combined

		smooth_weights.append(smooth_weight)

	return smooth_weights

## 选择下一个出怪行
func select_spawn_row(zombie_row_type: EnumsCharacter.ZombieRowType, special_base_weight: Array = []) -> int:
	var smooth_weights = calculate_smooth_weights(zombie_row_type, special_base_weight)
	var total_smooth_weight = 0.0
	for w in smooth_weights:
		total_smooth_weight += w

	if total_smooth_weight <= 0:
		return 5

	var rand_num = randf_range(0.0, total_smooth_weight)
	var cumulative_weight = 0.0

	for i in range(6):
		cumulative_weight += smooth_weights[i]
		if cumulative_weight >= rand_num:
			on_zombie_spawned(i)
			return i

	return 5

### 获取概率
#func get_row_probabilities() -> Array:
	#var smooth_weights = calculate_smooth_weights(0 as EnumsCharacter.ZombieRowType)
	#var total = 0.0
	#for w in smooth_weights:
		#total += w
#
	#var probabilities = []
	#for w in smooth_weights:
		#probabilities.append(w / total if total > 0 else 0.0)
#
	#return probabilities
