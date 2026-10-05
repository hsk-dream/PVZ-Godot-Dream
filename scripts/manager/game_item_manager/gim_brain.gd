extends Node
class_name GIM_Brain


## 脑子场景
const BRAIN_ON_ZOMBIE_MODE = preload("res://scenes/item/brain_on_zombie_mode.tscn")
## 脑子父节点
@onready var brain_on_zombie_mode: Node2D = %BrainOnZombieMode
## 脑子生成的全局x位置
@export var GlobalXBrain:float = 20
## 当前存在的脑子
var curr_brain:Array[BrainOnZombieMode] = []
## 当前脑子数量
var curr_brain_num:= 0


## 我是僵尸模式创建所有的脑子
func create_all_brain_on_zombie_mode():
	curr_brain.clear()
	curr_brain_num = 0
	for i in range(Global.main_game.zombie_manager.all_zombie_rows.size()):
		_create_one_brain(i)

## 创建一个脑子
##[lane:int] 行数
func _create_one_brain(lane:int):
	var curr_plant_cell:PlantCell = Global.main_game.plant_cell_manager.all_plant_cells[lane][0]
	var brain:BrainOnZombieMode = BRAIN_ON_ZOMBIE_MODE.instantiate()
	brain.init_brain(curr_plant_cell)

	brain.lane = lane
	brain.z_index = lane * 50 + 40
	brain.position = Vector2(GlobalXBrain, Global.main_game.zombie_manager.all_zombie_rows[lane].zombie_create_position.global_position.y) - brain_on_zombie_mode.global_position

	brain_on_zombie_mode.add_child(brain)
	brain.signal_brain_death.connect(_on_brain_death.bind(brain))

	curr_brain.append(brain)
	curr_brain_num += 1

## [param brain] 死亡后移除其计数；全部脑子耗尽时按原规则请求奖杯，与额外 Boss 胜利独立。
func _on_brain_death(brain:BrainOnZombieMode):
	curr_brain.erase(brain)
	curr_brain_num -= 1
	if curr_brain_num == 0:
		EventBus.push_event("create_trophy", brain.global_position)
