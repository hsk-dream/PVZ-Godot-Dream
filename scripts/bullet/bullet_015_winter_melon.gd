extends Bullet000ParabolaBase
class_name Bullet015WinterMelon


## 直接命中与溅射共享的减速持续秒数。
@export var time_be_decelerated :float = 3.0
## 冰西瓜溅射伤害与减速组件。
@onready var spatter_component: SpatterComponentWinterMelon = $SpatterComponent

func _ready() -> void:
	super()
	spatter_component.time_be_decelerated = time_be_decelerated

## [param enemy] 已确认的直击目标，可为空；减速只追加给结算后仍存活且可受击的目标。
func _attack_enemy(enemy:Character000Base):
	super(enemy)
	spatter_component.spatter_all_area_zombie(enemy, lane)
	if is_instance_valid(enemy) and _can_attack_character(enemy):
		enemy.be_ice_decelerate(time_be_decelerated)
