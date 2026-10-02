extends ZB001DoctorBallBase
class_name ZB001DoctorIceBall
## 博士冰球：提供冰球类型与动画，成形或滚动期间可被同行火爆辣椒消除。

## 返回技能准备参数中的冰球标识。
func get_ball_type() -> StringName:
	return BALL_TYPE_ICE

## 冰球从小到大形成的非循环动画。
func get_form_animation() -> StringName:
	return &"Zombie_boss_iceball_form"

## 冰球沿地面滚动的循环动画，保留已有资源命名。
func get_roll_animation() -> StringName:
	return &"Zombie_boss_iceball_role"


## 复用火爆辣椒清除本行道具的事件，无需给冰球添加植物攻击检测层。
func _subscribe_counter_events() -> void:
	EventBus.subscribe("jalapeno_bomb_item_lane", _on_jalapeno_bomb_item_lane)


## 取消辣椒事件订阅；EventBus 允许重复取消，也会清理订阅元数据。
func _unsubscribe_counter_events() -> void:
	EventBus.unsubscribe("jalapeno_bomb_item_lane", _on_jalapeno_bomb_item_lane)


## 火爆辣椒生效时消除同行冰球。[param target_lane] 为技能所在行，从 0 开始。
func _on_jalapeno_bomb_item_lane(target_lane: int) -> void:
	if target_lane == lane:
		dispel()
