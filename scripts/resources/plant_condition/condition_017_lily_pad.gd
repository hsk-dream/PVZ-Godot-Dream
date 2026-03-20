extends ResourcePlantCondition
class_name ResourcePlantConditionLilyPad

## 特殊植物种植函数判断是否可以种植，特殊植物重写,如墓碑吞噬者，咖啡豆等
func _judge_special_plants_condition(plant_cell:PlantCell) -> bool:
	## 睡莲要求当前格子主体位置未被种植
	## 当前格子满足种植地形
	if plant_condition & plant_cell.curr_condition:
		## 当前格子对应位置没有被种植
		if plant_cell.plant_in_cell[place_plant_in_cell] == null:
			## 睡莲要求当前格子主体位置未被种植
			if plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm] == null:
				return true
	return false
