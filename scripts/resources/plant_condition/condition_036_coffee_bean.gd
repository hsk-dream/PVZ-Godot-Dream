extends ResourcePlantCondition
class_name ResourcePlantConditionCoffeeBean


## 特殊植物种植函数判断是否可以种植，特殊植物重写,如墓碑吞噬者，咖啡豆等
func _judge_special_plants_condition(plant_cell:PlantCell) -> bool:
	## 如果norm位置植物在睡觉,可以种植
	if is_instance_valid(plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm]) and plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm].is_sleeping:
		return true
	else:
		return false
