extends Plant000Base
class_name Plant999Imitater

## 模仿的植物类型
var imitater_plant_type :EnumsCharacter.PlantType = EnumsCharacter.PlantType.Null
@onready var imitater_effect: Node2D = $ImitaterEffect


## 更新模仿者植物
func update_imitater():
	## plant_cell创造植物,该函数会先等待一帧,当前模仿者死亡后创建
	plant_cell.imitater_create_plant(imitater_plant_type)
	imitater_effect.visible = true
	imitater_effect.z_index += 1
	imitater_effect.activate_it()
	## 角色死亡直接消失
	character_death_disappear()
