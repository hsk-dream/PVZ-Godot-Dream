extends ResourcePlantCondition
class_name ResourcePlantConditionGraveBuster

## 特殊植物种植函数判断是否可以种植，特殊植物重写,如墓碑吞噬者，咖啡豆等
func _judge_special_plants_condition(plant_cell:PlantCell) -> bool:
	## 格子有墓碑并且普通植物位置没植物（没有墓碑吞正在吞）就可以种植
	if is_instance_valid(plant_cell.tombstone) and not plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm]:
		return true
	else:
		return false
