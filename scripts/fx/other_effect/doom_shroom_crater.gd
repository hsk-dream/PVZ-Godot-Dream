## 管理毁灭菇坑洞的两阶段显示；场景树暂停期间不计入坑洞寿命。
extends Node2D
class_name DoomShroomCrater

## 按背景索引选中的坑洞节点，包含两个显示阶段的贴图。
var curr_crater:Node2D
## 坑洞寿命前半段显示的完整坑洞贴图。
var curr_crater_0:Sprite2D
## 坑洞寿命后半段显示的消退坑洞贴图。
var curr_crater_1:Sprite2D
## 坑洞总寿命，单位为秒，默认 180 秒；两个显示阶段各占一半，暂停时间不计入。
@export var creater_time := 180.0

## 初始化坑洞，等待两个显示阶段结束后通知所属格子并释放自身。[br]
## [param cell_type] 是背景子节点索引：0/1 为陆地白天/黑夜，2/3 为泳池白天/黑夜，4/5 为屋顶中间/左边。[br]
## [param plant_cell] 是所属种植格子，调用时须传入有效实例，以便寿命结束后解除坑洞占用状态。
func init_crater(cell_type:int, plant_cell:PlantCell=null):
	curr_crater = get_child(cell_type)
	curr_crater.visible = true
	curr_crater_0 = curr_crater.get_child(0)
	curr_crater_1 = curr_crater.get_child(1)
	curr_crater_0.visible = true
	# 前半段显示完整坑洞；计时器随场景树暂停。
	await get_tree().create_timer(creater_time/2, false).timeout
	curr_crater_0.visible = false
	curr_crater_1.visible = true
	# 后半段显示消退坑洞，继续只累计未暂停的时间。
	await get_tree().create_timer(creater_time/2, false).timeout

	curr_crater_1.visible = false
	plant_cell.delete_crater_update_plant_cell_data()


	queue_free()
