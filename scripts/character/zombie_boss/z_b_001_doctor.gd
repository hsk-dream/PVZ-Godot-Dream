extends ZB000Base
class_name ZB001Doctor
## 博士本体负责出战初始化和死亡通知；动画与状态转换交给专用状态机。

## 死亡演出相对未受控制效果影响时的速度倍率；同时影响死亡前抬头、机甲与驾驶员死亡动作。
## 默认 2 表示两倍速；重复整理死亡状态时重新计算，不会累计乘算。
@export_range(1.0, 10.0, 0.1, "or_greater") var death_animation_speed_scale: float = 2.0
## 本体开始最终举旗循环后的保留时长，单位为游戏秒；不受死亡动画倍速影响，结束后另有一秒淡出。
## 0 表示进入循环后立即开始淡出；场景暂停及全局时间倍率仍然生效。
@export_range(0.0, 60.0, 0.1, "or_greater") var death_remain_duration: float = 10.0

## 死亡后保留角色的独立计时器，放在根节点下，避免被技能计时同步设为零速。
@onready var death_remain_timer: SpeedTimer = $DeathRemainTimer

## 博士场景的主状态机引用，负责入场、技能调度和死亡演出；缺失时为 null。
@onready var state_machine: ZB001DoctorStateMachine = get_node_or_null("%StateMachine") as ZB001DoctorStateMachine


## 保留父类的血量、方向和速度信号连接；展示、花园初始化不会经过此入口。
func ready_norm() -> void:
	# 延迟启动前先关闭受击，避免物理检测在 Enter 执行前把博士当作可攻击目标。
	# 使用独立的 Character 因素，不能用默认禁用阻止后续低头开放受击。
	hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	# 在父类连接死亡通知和延迟启动之前接线，覆盖首次入场及入场前死亡。
	if is_instance_valid(state_machine) and not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)
	super.ready_norm()
	# 父类先排队初始化随机速度，再启动入场，避免第一帧使用未初始化的速度。
	_start_state_machine.call_deferred()


## 通用状态机在 enter() 完成后发出通知，此时受击组件已经应用新状态的设置。
## [param _previous_state] 切换前的主状态；此回调只广播状态更新，不读取旧状态。
## [param _next_state] 切换后的主状态；此回调只广播状态更新，不读取新状态。
func _on_state_changed(_previous_state: CharacterState, _next_state: CharacterState) -> void:
	signal_status_update.emit()


## 延迟执行期间角色可能离树或死亡；重复请求也不能重新初始化并重播入场。
func _start_state_machine() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or is_death:
		return
	if character_init_type != E_CharacterInitType.IsNorm:
		return
	if not is_instance_valid(state_machine):
		push_error("ZB001Doctor：缺少有效的 %StateMachine 博士状态机。")
		return
	if state_machine.is_running:
		return
	# 配置校验由博士状态机报告具体原因；此处不覆盖场景中绑定的角色或播放器。
	if not state_machine.initialize():
		return
	if not state_machine.start():
		push_error("ZB001Doctor：状态机初始化成功，但无法启动入场状态。")


## 保留僵王共同死亡逻辑，再提交死亡状态请求；不通过可能被取消的亡语启动演出。
func character_death() -> void:
	if is_death:
		return
	super.character_death()
	if is_instance_valid(state_machine) and character_init_type == E_CharacterInitType.IsNorm:
		state_machine.request_death()


## 父类先解除控制效果，再按初始随机速度计算博士的死亡倍率；不修改初始速度记录。
## 死亡开始、抬头过渡和致死冰冻清理可能重复调用，始终从同一基础值计算以避免加速叠加。
func prepare_death_animation() -> void:
	super.prepare_death_animation()
	# 父类已校正为有限正数的初始随机倍率；保留个体速度差异，但不保留冰冻或黄油停滞。
	var base_speed: float = influence_speed_factors[E_Influence_Speed_Factor.InitRandomSpeed]
	# 非法导出值回退为正常速度，避免死亡动画停住而无法触发奖杯关键帧。
	var death_multiplier: float = death_animation_speed_scale if is_finite(death_animation_speed_scale) and death_animation_speed_scale >= 1.0 else 1.0
	signal_update_speed.emit(base_speed * death_multiplier)


## 由 Dead 在本体进入最终循环后调用；保留时长只受游戏时间影响，不乘死亡动画倍率。
func start_death_remain() -> void:
	if not is_death or is_queued_for_deletion():
		return
	if death_remain_duration <= 0.0:
		_fade_and_remove()
		return
	death_remain_timer.set_speed_scale(1.0)
	death_remain_timer.start_scaled(death_remain_duration)


## 保留时间结束后沿用僵王一秒淡出；切换场景会直接销毁计时器及角色。
func _on_death_remain_timer_timeout() -> void:
	if is_death:
		_fade_and_remove()
