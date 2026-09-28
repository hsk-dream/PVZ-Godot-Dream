extends Character000Base
class_name ZB000Base
## 僵王共用逻辑死亡、控制效果清理和奖杯请求；具体死亡动画由各自状态机负责。

## 由死亡动画方法轨道请求奖励，是否允许生成由关卡管理器判断。
signal signal_trophy_requested(global_pos: Vector2)
## 状态进入完成后通知检测器重新索敌；状态内单独修改受击开关时也应发出此信号。
signal signal_status_update

## 死亡动画请求奖杯时使用的世界位置标记；缺失时回退到角色根节点位置。
@onready var trophy_spawn_point: Marker2D = get_node_or_null("%TrophySpawnPoint") as Marker2D
## 是否已经启动死亡淡出，防止重复创建补间或重复安排释放。
var _is_fading := false


## 所有普通与特殊植物伤害共用的最后检查，防止动画关键帧或旧碰撞结果绕过受击窗口。[br]
## [param attack_value] 本次伤害；[param bullet_mode] 伤害类型。[br]
## [param is_drop] 是否允许掉落表现；[param trigger_be_attack_SFX] 是否播放受击音效。
## 致死伤害仅通过血量组件启动僵王死亡状态机，不套用普通僵尸的直接删除逻辑。
func be_attacked_bullet(attack_value: int, bullet_mode: BulletRegistry.AttackMode = BulletRegistry.AttackMode.Norm, is_drop: bool = true, trigger_be_attack_SFX := true):
	if is_death or character_init_type != E_CharacterInitType.IsNorm \
		or not is_inside_tree() or is_queued_for_deletion() \
		or not is_instance_valid(hurt_box_component) or not hurt_box_component.is_enabling:
		return
	super.be_attacked_bullet(attack_value, bullet_mode, is_drop, trigger_be_attack_SFX)


## 先发出原有死亡信号供管理器扣数，再关闭受击；重复调用不重复触发亡语或计数。
func character_death() -> void:
	if is_death:
		return
	super.character_death()
	hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Death)
	prepare_death_animation()


## 死亡演出只保留初始随机速度，解除停滞并停止旧计时器，防止结束回调覆盖演出速度。
## 可在 Dying 再调用一次，处理致死伤害调用返回后才生成的控制特效。
func prepare_death_animation() -> void:
	# 当前控制效果计时器；可能尚未创建，死亡清理时只停止有效实例。
	for timer: Timer in all_timer.values():
		if is_instance_valid(timer):
			timer.stop()
	if is_instance_valid(ice_effect):
		ice_effect.queue_free()
		ice_effect = null
	body.set_other_color(BodyCharacter.E_ChangeColors.IceColor, Color.WHITE)
	# 死亡演出保留的初始随机速度倍率；无配置时使用 1，非法值会回退为 1。
	var death_speed: float = influence_speed_factors.get(E_Influence_Speed_Factor.InitRandomSpeed, 1.0)
	# 编辑器误设零速度时仍允许死亡演出完成，不改全局时间倍率。
	if not is_finite(death_speed) or death_speed <= 0:
		death_speed = 1.0
	influence_speed_factors.clear()
	influence_speed_factors[E_Influence_Speed_Factor.InitRandomSpeed] = death_speed
	signal_update_speed.emit(death_speed)


## 死亡后延迟的随机初始化或控制效果不能重新改变死亡动画速度。
## [param value] 当前影响因素的新速度倍率；1 不改变速度，0 使动作停滞。
## [param factor] 本次更新的速度影响因素，用于覆盖该因素而保留其他倍率。
func update_speed_factor(value: float, factor: E_Influence_Speed_Factor) -> void:
	if not is_death:
		super.update_speed_factor(value, factor)


## 已死亡角色不再创建减速计时器或重新染上冰冻颜色。
## [param time] 本次冰冻减速持续时间，单位为秒。
func be_ice_decelerate(time: float) -> void:
	if not is_death:
		super.be_ice_decelerate(time)


## 仅在正常出战且受击窗口开启时接受冰冻；全场事件也不能绕过状态控制的受击开关。[br]
## 父类先扣血后创建冰冻效果；致死时在父类返回后补做清理，避免死后残留冰块。
## [param time] 本次完全冰冻持续时间，单位为秒。
## [param new_time_ice_end_decelerate] 冰冻解除后继续减速的时长，单位为秒。
func be_ice_freeze(time: float, new_time_ice_end_decelerate: float) -> void:
	if is_death or character_init_type != E_CharacterInitType.IsNorm \
		or not is_inside_tree() or is_queued_for_deletion() \
		or not is_instance_valid(hurt_box_component) or not hurt_box_component.is_enabling:
		return
	super.be_ice_freeze(time, new_time_ice_end_decelerate)
	if is_death:
		prepare_death_animation()


## 任意行的火爆辣椒均可命中；受击窗口在此检查，通过后先解除冰冻和减速，再扣血。[br]
## [param attack_value] 本次辣椒伤害；致死时由血量组件触发僵王死亡流程，不直接删除或播放普通僵尸灰烬。
func be_jalapeno(attack_value: int) -> void:
	if is_death or character_init_type != E_CharacterInitType.IsNorm \
		or not is_inside_tree() or is_queued_for_deletion() \
		or not is_instance_valid(hurt_box_component) or not hurt_box_component.is_enabling:
		return
	# 先解除控制再结算伤害，避免解冻回调覆盖随后启动的死亡演出速度。
	cancel_ice()
	hp_component.Hp_loss(attack_value, BulletRegistry.AttackMode.Penetration, false, false)


## 轨道仅发请求，不直接创建奖杯；存活、展示和正在卸载的角色不能请求奖励。
func request_trophy() -> void:
	if not is_death or character_init_type != E_CharacterInitType.IsNorm \
		or not is_inside_tree() or is_queued_for_deletion():
		return
	# 本次奖杯请求使用的全局坐标，优先取奖杯生成标记的位置。
	var spawn_position := trophy_spawn_point.global_position if is_instance_valid(trophy_spawn_point) else global_position
	signal_trophy_requested.emit(spawn_position)


## 死亡状态完成后沿用普通僵尸的一秒淡出；不更改基类的直接删除入口。
func _fade_and_remove() -> void:
	if _is_fading or not is_inside_tree() or is_queued_for_deletion():
		return
	_is_fading = true
	# 本次死亡淡出补间，在一秒内降低角色透明度，然后释放角色节点。
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
