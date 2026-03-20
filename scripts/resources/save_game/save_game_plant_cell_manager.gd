extends Resource
class_name ResourceSaveGamePlantCellManager
## 植物格子管理器存档数据

## 每个植物格子的数据
## 若植物格子有数据,则保存行列和数据,若没有数据,则跳过该格子
@export var all_plant_cells_datas:Array[ResourceSaveGamePlantCell]

## 当前植物种植的信息[植物种类:植物数量],读档时验证是否正确
@export var curr_plant_num:Dictionary[EnumsCharacter.PlantType, int]

## 墓碑管理器数据
@export var tomb_stone_manager_data:Dictionary
