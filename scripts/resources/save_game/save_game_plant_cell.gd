extends Resource
class_name ResourceSaveGamePlantCell
## 植物格子存档数据

## 植物格子的行和列
@export var row_col:Vector2i
## 在当前格子中对应位置的植物 [位置, 植物数据字典]
@export var plant_type_in_cell:Dictionary[EnumsCharacter.PlacePlantInCell, Dictionary] =  {}
## 是否有梯子
@export var is_ladder:bool = false
