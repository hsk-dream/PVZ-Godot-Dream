extends Node
## 手持管理器，铲子（植物僵尸）
class_name HM_Item

@onready var ui_shovel: UIShovel = %UIShovel
@onready var real_shovel: RealShovel = %RealShovel

## 手持道具状态
enum E_HmItemStatus{
	Null,
	Shovel
}
var curr_hm_item_status := E_HmItemStatus.Null

## 当前鼠标所在格子
var curr_plant_cell :PlantCell

## 当前铲子选择植物
var plant_be_shovel_look:Plant000Base
## 当前铲子所在格子植物数量
var curr_shovel_look_plant_num:int = 0


func click_shovel():
	curr_hm_item_status = E_HmItemStatus.Shovel
	real_shovel.change_is_using(true)

## 切换预铲目标，先恢复旧目标，再高亮新目标。[br]
## [param candidate] 候选植物，可为空或已释放引用；失效引用按无目标处理。
func _set_shovel_look_target(candidate: Variant) -> void:
	# 本次有效的候选植物；先检查引用，再转换为植物类型。
	var next_plant: Plant000Base = null
	if is_instance_valid(candidate):
		next_plant = candidate as Plant000Base

	# 同格刷新仍选中同一植物时，保留现有预铲状态。
	if is_instance_valid(plant_be_shovel_look) \
			and plant_be_shovel_look == next_plant:
		return

	if is_instance_valid(plant_be_shovel_look):
		plant_be_shovel_look.be_shovel_look_end()

	plant_be_shovel_look = next_plant
	if is_instance_valid(plant_be_shovel_look):
		plant_be_shovel_look.be_shovel_look()

## 同格有多个植物时，根据鼠标位置更新预铲目标。
func item_process() -> void:
	if curr_shovel_look_plant_num >= 2 \
			and is_instance_valid(curr_plant_cell):
		_set_shovel_look_target(
			curr_plant_cell.return_plant_be_shovel_look()
		)

## [param plant_cell] 当前进入或重新刷新的格子；没有植物时清理旧预铲。
func mouse_enter(plant_cell: PlantCell) -> void:
	curr_plant_cell = plant_cell
	if curr_hm_item_status == E_HmItemStatus.Shovel:
		curr_shovel_look_plant_num = plant_cell.get_curr_plant_num()
		_set_shovel_look_target(
			plant_cell.return_plant_be_shovel_look()
		)

## [param plant_cell] 移出的格子，保留接口参数；结束当前预铲并清理格子状态。
@warning_ignore("unused_parameter")
func mouse_exit(plant_cell: PlantCell) -> void:
	curr_plant_cell = null
	curr_shovel_look_plant_num = 0
	if curr_hm_item_status == E_HmItemStatus.Shovel:
		_set_shovel_look_target(null)


## 点击铲掉当前有效的预铲植物。[br]
## [param plant_cell] 点击的格子，保留接口参数；目标已释放时不执行铲除。
@warning_ignore("unused_parameter")
func click_cell(plant_cell:PlantCell):
	match curr_hm_item_status:
		E_HmItemStatus.Shovel:
			if is_instance_valid(plant_be_shovel_look):
				SoundManager.play_other_SFX("plant2")
				plant_be_shovel_look.be_shovel_kill()


## 退出手持道具状态，恢复预铲植物和铲子 UI。
func exit_status() -> void:
	curr_hm_item_status = E_HmItemStatus.Null
	_set_shovel_look_target(null)
	curr_shovel_look_plant_num = 0
	real_shovel.change_is_using(false)
	ui_shovel.ui_shovel_appear()
