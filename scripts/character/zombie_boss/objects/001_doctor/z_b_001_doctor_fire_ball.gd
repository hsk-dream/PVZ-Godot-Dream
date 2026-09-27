extends ZB001DoctorBallBase
class_name ZB001DoctorFireBall
## 博士火球：提供火球类型与动画，成形或滚动期间可被全场寒冰菇技能消除。

## 返回技能准备参数中的火球标识。
func get_ball_type() -> StringName:
	return &"Fire"

## 火球从小到大形成的非循环动画。
func get_form_animation() -> StringName:
	return &"Zombie_boss_fireball_form"

## 火球沿地面滚动的循环动画，保留已有资源命名。
func get_roll_animation() -> StringName:
	return &"Zombie_boss_fireball_role"


## 复用寒冰菇的全场冰冻事件，不限制火球所在行。
func _subscribe_counter_events() -> void:
	EventBus.subscribe("ice_all_zombie", _on_ice_all_zombie)


## 取消寒冰菇事件订阅；销毁与退出场景时重复调用安全。
func _unsubscribe_counter_events() -> void:
	EventBus.unsubscribe("ice_all_zombie", _on_ice_all_zombie)


## 寒冰菇生效时直接消除火球，不对球施加冰冻或减速。[br]
## [param _time_ice] 为事件携带的冰冻秒数；火球消除不使用此参数。[br]
## [param _time_decelerate] 为事件携带的减速秒数；保留参数以匹配现有事件签名。
func _on_ice_all_zombie(_time_ice: float, _time_decelerate: float) -> void:
	dispel()
