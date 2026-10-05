extends Bullet000ParabolaBase
class_name Bullet012Melon


## 西瓜直接命中或落空后使用的范围溅射组件。
@onready var spatter_component: SpatterComponent = $SpatterComponent

## [param enemy] 基类确认的直击目标，可为空；被保护伞弹开或重复命中时不会进入此伤害流程。
func _attack_enemy(enemy:Character000Base):
	super(enemy)
	spatter_component.spatter_all_area_zombie(enemy, lane)
