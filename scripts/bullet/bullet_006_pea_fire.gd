extends BulletLinear000Base
class_name Bullet006PeaFire

## 火豌豆自身的循环表现动画。
@onready var anim_lib: AnimationPlayer = $Body/AnimLib
## 命中或撞地后结算周围目标的溅射组件。
@onready var spatter_component: SpatterComponent = $SpatterComponent

func _ready() -> void:
	super()
	anim_lib.play(&"ALL_ANIMS")

## [param enemy] 基类确认的命中目标；为空时仍允许撞地溅射，但不会尝试解冻。[br]
## 解冻先于扣血，防止解冻回调覆盖致死伤害启动的死亡动画速度。
func _attack_enemy(enemy:Character000Base):
	if _can_attack_character(enemy):
		enemy.cancel_ice()
	super(enemy)
	spatter_component.spatter_all_area_zombie(enemy)
