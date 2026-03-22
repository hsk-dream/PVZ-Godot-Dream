extends ItemPlantCellBase
class_name MoneySign

@export var dave_dialog:CrazyDaveDialogResource
## 当前选择的植物数据
var choosed_plant_data:Dictionary
var curr_plant_price := 0
## 售卖植物的格子，若没没卖出去，植物重新初始化
var sell_plant_cell :PlantCellGarden
## 给戴夫手上的plant_cell
var plant_cell_give_dave:PlantCellGarden

const price_from_stage = {
	GardenManager.E_GrowthStage.Sprout: 1500,
	GardenManager.E_GrowthStage.Small: 3000,
	GardenManager.E_GrowthStage.Medium: 5000,
	GardenManager.E_GrowthStage.Large: 8000,
	GardenManager.E_GrowthStage.Perfect: 8000,

}
@onready var crazy_dave: CrazyDave = $DaveCanvasLayer/CrazyDave


func use_it():
	## 当前选择的植物数据
	choosed_plant_data = curr_plant_cell.get_curr_plant()
	sell_plant_cell = curr_plant_cell
	curr_plant_cell.free_curr_plant()

	curr_plant_price = price_from_stage[choosed_plant_data["curr_growth_stage"]]

	dave_dialog.dialog_detail_list[0].text = "我给你$" + str(curr_plant_price) + "换你这棵植物！"

	## 给戴夫手上的plant_cell
	plant_cell_give_dave = SceneRegistry.PLANT_CELL_GARDEN.instantiate()
	plant_cell_give_dave.position += Vector2(-40,-60)
	crazy_dave.reset_dave(dave_dialog, plant_cell_give_dave)
	#print(plant_cell_give_dave.global_position)
	plant_cell_give_dave.init_curr_plant_cell(choosed_plant_data)
	crazy_dave.is_activate = true
	crazy_dave.visible = true
	deactivate_it()

	## 戴夫离开
	await crazy_dave.signal_dave_leave_end
	crazy_dave.visible = false
	choosed_plant_data = {}
	curr_plant_price = 0
	sell_plant_cell = null


## 同意售卖
func sell_agree():
	Global.global_game_state.coin_value += curr_plant_price
	print("当前金币：", Global.global_game_state.coin_value)

	print(plant_cell_give_dave.global_position)
	plant_cell_give_dave.queue_free()
## 不同意售卖
func sell_disagree():
	sell_plant_cell.init_curr_plant_cell(choosed_plant_data)

	plant_cell_give_dave.queue_free()
