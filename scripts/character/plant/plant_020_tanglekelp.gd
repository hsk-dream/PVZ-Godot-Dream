extends Plant000Base
class_name Plant020Tanglekelp

## 仅普通僵尸使用的拖拽表现与处决组件。
@onready var grap_component: GrapComponent = $GrapComponent
## 查找当前仍处于受击范围内的目标。
@onready var detect_component: DetectComponent = $DetectComponent
## 僵王不会被拖入水中，改为一次穿透伤害；命中后海草仍消耗自身。
@export_range(0, 10000, 1, "or_greater") var boss_attack_value: int = 1800
## 海草是一次性攻击，防止等待动画期间重复响应索敌信号。
var _is_attacking: bool = false


func ready_norm_signal_connect():
	super()
	detect_component.signal_can_attack.connect(start_grap_zombie)

## 开始攻击
func start_grap_zombie():
	if _is_attacking or is_death:
		return
	# 同步检查范围和受击窗口，避免对已抬头的僵王开始攻击。
	var enemy: Character000Base = detect_component.update_first_enemy()
	if not (enemy is Zombie000Base or enemy is ZB000Base):
		return
	_is_attacking = true
	detect_component.disable_component(ComponentNormBase.E_IsEnableFactor.Attack)
	blink_component.disable_component(ComponentNormBase.E_IsEnableFactor.Attack)
	grap_in_pool(enemy)

## [param target_zombie] 已确认的本次目标。普通僵尸拖入水中，僵王只扣血，两者都会消耗海草。
func grap_in_pool(target_zombie:Character000Base):
	if target_zombie is ZB000Base:
		target_zombie.be_attacked_bullet(boss_attack_value, BulletRegistry.AttackMode.Penetration, false, false)
	elif target_zombie is Zombie000Base:
		grap_component.activate_it_to_grap_zombie(target_zombie)
	await get_tree().create_timer(0.3).timeout
	if is_death or is_queued_for_deletion() or not is_instance_valid(plant_cell):
		return
	# 海草自身下沉时的水花，不把特效或拖拽组件挂到僵王身体上。
	var splash:Splash = SceneRegistry.SPLASH.instantiate()
	plant_cell.add_child(splash)
	splash.global_position = global_position + Vector2(0, 10)

	# 仅移动海草，僵王机甲的位置与动画始终由其自身状态机控制。
	var tween:Tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, 10), 0.5)
	await tween.finished

	if not is_death and not is_queued_for_deletion():
		character_death()

