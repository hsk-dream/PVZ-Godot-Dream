extends ZB000Base
class_name ZB001Doctor
## 博士本体负责出战初始化和死亡通知；动画与状态转换交给专用状态机。

## 死亡演出相对未受控制效果影响时的速度倍率；同时影响死亡前抬头、机甲与驾驶员死亡动作。
## 默认 2 表示两倍速；重复整理死亡状态时重新计算，不会累计乘算。
@export_range(1.0, 10.0, 0.1, "or_greater") var death_animation_speed_scale: float = 2.0
## 本体开始最终举旗循环后的保留时长，单位为游戏秒；不受死亡动画倍速影响，结束后另有一秒淡出。
## 0 表示进入循环后立即开始淡出；场景暂停及全局时间倍率仍然生效。
@export_range(0.0, 60.0, 0.1, "or_greater") var death_remain_duration: float = 10.0

@export_group("入场踩地")
## 每次落脚的横向、纵向镜头震动幅度，单位为像素；零向量关闭震动，仍播放声音。
@export var enter_footstep_shake_amplitude: Vector2 = Vector2(2.0, 6.0)
## 每次落脚震动的持续游戏秒数；0 关闭震动，不跟随博士个体动画倍率。
@export_range(0.0, 1.0, 0.01) var enter_footstep_shake_duration: float = 0.2
## 每秒振动次数；默认 20，震动幅度会在持续时间内衰减至零。
@export_range(1.0, 60.0, 1.0) var enter_footstep_shake_frequency: float = 20.0
@export_group("")

## 本次入场已经触发的落脚编号，阻止重复方法事件再次播放同一步的音效和震动。
var _played_enter_footsteps: Array[int] = []

## 死亡后保留角色的独立计时器，放在根节点下，避免被技能计时同步设为零速。
@onready var death_remain_timer: SpeedTimer = $DeathRemainTimer

## 按剩余血量切换机甲破损贴图；阶段阈值与各部件贴图在博士场景中配置。
@onready var hp_stage_change_component: HpStageChangeComponent = %HpStageChangeComponent

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


## 保留通用战斗信号连接，并让每次扣血同步更新机甲的破损外观。
func ready_norm_signal_connect() -> void:
	super.ready_norm_signal_connect()
	hp_component.signal_hp_loss.connect(_on_hp_loss_update_appearance)


## [param curr_hp] 本次扣血后的剩余血量，跨越多个阈值时由组件依次应用各阶段。
## [param _is_drop] 通用伤害的肢体掉落开关；博士破损只替换贴图，不受此开关影响。
func _on_hp_loss_update_appearance(curr_hp: int, _is_drop: bool) -> void:
	# 致死伤害也要更新最终破损外观，不能因为已进入死亡状态而跳过。
	hp_stage_change_component.judge_body_change(curr_hp, true)


## 由 Enter 在播放入场动画前调用，每次重新入场都允许各落脚关键帧触发一次。
func reset_enter_footsteps() -> void:
	_played_enter_footsteps.clear()


## 入场动画落脚关键帧的统一表现入口，同时播放声音并请求镜头震动，不造成伤害。
## [param step_index] 本次入场的非负落脚编号；当前外侧脚为 0、内侧脚为 1，重复编号忽略。
func play_enter_footstep(step_index: int) -> void:
	if step_index < 0 or _played_enter_footsteps.has(step_index) or is_death \
		or character_init_type != E_CharacterInitType.IsNorm or not is_inside_tree() or is_queued_for_deletion():
		return
	if not is_instance_valid(state_machine) or not state_machine.is_running \
		or not state_machine.current_state is ZB001DoctorStateEnter:
		return
	# 入场被打断后仍可能收到延迟方法调用；动画名和活动状态共同限制有效事件。
	var player: AnimationPlayer = state_machine.animation_player
	if not is_instance_valid(player) or player.assigned_animation != ZB001DoctorStateMachine.ENTER_ANIMATION:
		return
	_played_enter_footsteps.append(step_index)
	SoundManager.play_character_SFX(&"gargantuar_thump")
	EventBus.push_event(MainGameCamera.SHAKE_EVENT, [enter_footstep_shake_amplitude, enter_footstep_shake_duration, enter_footstep_shake_frequency])


## 由机甲动画的方法轨道播放角色音效；展示实例、离树实例及旧动画的延迟调用不播放。
## [param animation_name] 发出调用的机甲动画名称，用于拒绝动作切换后才到达的旧调用。
## [param sound_name] SoundManager 中注册的角色音效名称；音频保持正常播放速度。
func play_animation_sfx(animation_name: StringName, sound_name: StringName) -> void:
	if character_init_type != E_CharacterInitType.IsNorm or not is_inside_tree() or is_queued_for_deletion():
		return
	if not is_instance_valid(state_machine):
		return
	# 以机甲播放器当前指定的动画为准，驾驶员独立播放的动作不影响此处判断。
	var player: AnimationPlayer = state_machine.animation_player
	if not is_instance_valid(player) or player.assigned_animation != animation_name:
		return
	# 死亡动画同样需要音效，因此不按 is_death 拦截；复用全局音效池和短时间去重。
	SoundManager.play_character_SFX(sound_name)


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
