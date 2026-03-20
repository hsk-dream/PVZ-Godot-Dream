extends ResourcePlantCondition
class_name ResourcePlantConditionCobCannon

## 玉米加农炮判定是否可以种植
func judge_special_plants_condition(plant_cell:PlantCell) -> bool:
	if get_preplant_purple(plant_cell, EnumsCharacter.PlantType.P048CobCannon) != null:
		return true
	return false

## 判段是否存在紫卡预种植植物,并且不存在南瓜壳
func _judge_pre_plant(plant_cell:PlantCell) -> bool:
	return is_instance_valid(plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm]) \
	and plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm].plant_type == EnumsCharacter.PlantType.P035CornPult \
	and not is_instance_valid(plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Shell])

## 获取当前格子紫卡预种植植物
## 返回预种植植物,若当前植物格子可以种植紫卡,返回预种植紫卡,
func get_preplant_purple(plant_cell:PlantCell, _curr_plant_type:EnumsCharacter.PlantType) ->Plant000Base:
	## 非最后一列,前轮有植物,且没有南瓜
	if plant_cell.row_col.y < Global.main_game.plant_cell_manager.row_col.y-1 and\
	_judge_pre_plant(plant_cell) and _judge_pre_plant(Global.main_game.plant_cell_manager.all_plant_cells[plant_cell.row_col.x][plant_cell.row_col.y+1]):
		return plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm]
	else:
		return null
