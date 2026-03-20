extends Node
class_name CardRandomPool
## 卡片随机池,随机生成一张新卡片

## 可能出现的植物卡片,及其概率
var all_card_plant_type_probability :Dictionary[EnumsCharacter.PlantType, int] = {}
## 可能出现的僵尸卡片,及其概率
var all_card_zombie_type_probability :Dictionary[EnumsCharacter.ZombieType, int] = {}
## 选择卡片随即池_植物
var card_choose_random_pool_plant:RandomPicker
## 选择卡片随即池_僵尸
var card_choose_random_pool_zombie:RandomPicker
## 总概率之和
var total_prob = 0
## 植物卡片概率之和
var total_prob_plant = 0


enum E_CardRandomPoolInitParaAttr{
	AllCardPlantProbability,
	AllCardZombieProbability,
}

## 管理器初始化调用
func init_card_random_pool(card_random_pool_init_para:Dictionary):
	self.all_card_plant_type_probability = card_random_pool_init_para[E_CardRandomPoolInitParaAttr.AllCardPlantProbability]
	self.all_card_zombie_type_probability = card_random_pool_init_para[E_CardRandomPoolInitParaAttr.AllCardZombieProbability]
	var card_choose_random_pool_plant_data:Array[Array] = []
	## 计算总概率值
	for plant_type in all_card_plant_type_probability.keys():
		total_prob += all_card_plant_type_probability[plant_type]
		card_choose_random_pool_plant_data.append([plant_type, all_card_plant_type_probability[plant_type]])
	total_prob_plant = total_prob
	if not card_choose_random_pool_plant_data.is_empty():
		print("初始化植物随机生成器")
		card_choose_random_pool_plant = RandomPicker.new(card_choose_random_pool_plant_data)
	var card_choose_random_pool_zombie_data:Array[Array] = []
	## 计算总概率值
	for zombie_type in all_card_zombie_type_probability.keys():
		total_prob += all_card_zombie_type_probability[zombie_type]
		card_choose_random_pool_zombie_data.append([zombie_type, all_card_zombie_type_probability[zombie_type]])
	if not card_choose_random_pool_zombie_data.is_empty():
		print("初始化僵尸随机生成器")
		card_choose_random_pool_zombie = RandomPicker.new(card_choose_random_pool_zombie_data)
	assert(total_prob != 0, "植物卡片和僵尸卡片总概率值为0")

	print("植物卡片概率：", total_prob_plant, "僵尸卡片概率", total_prob - total_prob_plant)

## 按概率随机获取可生成卡片索引
func get_random_card() -> Card:
	var rand_val = randi_range(1, total_prob)
	## 植物卡片
	if rand_val <= total_prob_plant:
		var card_plant_type = card_choose_random_pool_plant.get_random_item()
		return AllCards.all_plant_card_prefabs[card_plant_type]
	else:
		var card_zombie_type = card_choose_random_pool_zombie.get_random_item()
		return AllCards.all_zombie_card_prefabs[card_zombie_type]

func get_random_card_info() -> Dictionary:
	var rand_val = randi_range(1, total_prob)
	## 植物卡片
	if rand_val <= total_prob_plant:
		var card_plant_type = card_choose_random_pool_plant.get_random_item()
		return {"plant_type": card_plant_type,"zombie_type": EnumsCharacter.ZombieType.Null}
	else:
		var card_zombie_type = card_choose_random_pool_zombie.get_random_item()
		return {"plant_type": EnumsCharacter.PlantType.Null, "zombie_type": card_zombie_type}


