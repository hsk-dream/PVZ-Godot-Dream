## 博士专用状态机：选择五种技能、同步计时倍率和校验配置，死亡始终优先。
## 由博士正常出战初始化显式启动；状态请求动画，专用控制器负责播放，速度仍由原动画组件处理。
## 每个技能管理自己的内部阶段与共享数据，根层不决定技能如何收尾。
## 场景中绑定角色、播放器、入场、待机、五技能和死亡状态。
extends CharacterStateMachine
class_name ZB001DoctorStateMachine

## 主层只选择完整技能，内部动画阶段与收尾由各复合技能管理。
## 普通待机状态引用；入场或技能收尾后进入，等待下一次技能选择。
@export var idle_state: ZB001DoctorStateIdle
## 键为直属技能节点名，值为选择权重；名称必须与当前实例的技能节点完全一致。
## 默认放置权重为 3，其余为 1，可直接在编辑器调整；零权重或不满足触发条件时不参与 Idle 随机选择。
## 权重由主状态机配置，技能自身提供可用性查询并管理动作；初始顺序与吐球保底不受零权重限制。
## 必须保留五个技能配置，空字典不自动补齐；修改节点名或字典键后需要重新初始化。
@export var skill_state_weights: Dictionary[StringName, float] = {
	&"Spawn": 3.0,
	&"HeadSkill": 1.0,
	&"Bungee": 1.0,
	&"ThrowRV": 1.0,
	&"Stomp": 1.0,
}
## 开场按数组顺序选择完整技能，不可用项直接跳过；耗尽后改为加权随机，空数组直接随机。
## 可重复配置同一技能，固定顺序不执行随机去重；吐球保底插队时保留尚未执行的下一项。
@export var initial_skill_sequence: Array[ZB001DoctorSkillState] = []
## 死亡演出状态引用，死亡请求会优先切换到此状态。
@export var dying_state: ZB001DoctorStateDying
## 死亡演出完成后的终止状态引用，负责停止行动并清理角色。
@export var dead_state: ZB001DoctorStateDead
## 博士自身的动画控制器，负责姿势过渡、实例动画副本及本体联动。
@export var animation_controller: ZB001DoctorAnimationController
## 返回 Idle 后的最短待机动作秒数；到期仍等待当前动画周期结束，随主体倍率变化，必须为有限正数。
@export_range(0.1, 60.0, 0.1) var idle_duration := 2.0
## 连续未选择吐球的技能回合上限；达到后下一回合强制吐球，默认 5 表示第 6 回合保底。
## 一整轮放置僵尸只计 1 回合；首次吐球前也从入场后的技能选择开始累计。
@export_range(1, 20, 1, "or_greater") var max_rounds_without_head_skill: int = 5

## 是否已接收逻辑死亡请求；置位后禁止新的普通技能转换与释放。
var _death_requested := false
## 死亡演出是否已经启动，用于阻止 stop/start 重复播放死亡流程。
var _death_started := false
## 记录上次最终抽中的技能；重新初始化时清空，普通技能结束后保留。
var _last_selected_skill: ZB001DoctorSkillState
## 连续选中的非吐球技能次数；选择吐球或重新初始化时清零，空池重试不计回合。
var _rounds_without_head_skill: int = 0
## 初始技能数组中下一项的下标；取用或跳过不可用项时递增，重新初始化时归零。
var _initial_skill_index: int = 0
## 实际连接的动画控制器，重新初始化或离树时据此清理旧连接。
var _connected_animation_controller: ZB001DoctorAnimationController
## 初始化时收集的动作计时器；仅含状态机子树，不含博士根节点的 DeathRemainTimer。
var _action_timers: Array[SpeedTimer] = []
## 上次已同步给动作计时器的实际倍率；合法值非负，-1 表示缓存失效，需重新同步全部计时器。
var _last_action_speed: float = -1.0
## 初始化时解析的技能节点引用，键与导出权重表一致；只缓存节点，选择时仍读取最新权重。
## 重新初始化或断开播放器时清空，避免继续引用旧状态树中的技能。
var _skill_states: Dictionary[StringName, ZB001DoctorSkillState] = {}

## 提供博士类型引用，避免各状态重复转换；原始引用仍由通用状态机统一维护。
var boss: ZB001Doctor:
	get:
		return character as ZB001Doctor


## 在状态注册前拒绝其他角色，避免专用状态读取博士接口时才发生错误。
## [param actor] 待检查或注入的所属角色；具体允许的角色类型由当前状态或状态机限定。
func accepts_character(actor: Character000Base) -> bool:
	return is_instance_valid(actor) and actor is ZB001Doctor


## 先让通用层重置旧连接并注册状态，再完成博士专用检查；通过前不会播放动画。
## 失败会清除初始化标记，保证后续 start() 不能绕过失败的配置检查。
## [param actor] 本次初始化的角色；null 表示保留已有角色引用。
## [param player] 主体动画播放器；传入 null 表示保留状态机已有引用。
func initialize(actor: Character000Base = null, player: AnimationPlayer = null) -> bool:
	if _switching:
		return false
	if not super.initialize(actor, player):
		push_error("ZB001DoctorStateMachine：角色必须为博士，且状态节点和入口必须属于当前状态机。")
		return false
	_cache_skill_states()
	_cache_action_timers()
	# 具体检测分支已输出错误；这里只处理失败清理，避免日志统一指向 initialize()。
	var configuration_error := _get_configuration_error()
	if not configuration_error.is_empty():
		stop()
		_disconnect_animation_player()
		_initialized = false
		return false
	_last_selected_skill = null
	_rounds_without_head_skill = 0
	_initial_skill_index = 0
	# 只有全部校验通过后才修正技能运行时配置，查询错误不会改变战力预算。
	# 当前已解析并通过校验的技能名称，按缓存引用初始化本实例的效果组件。
	for state_name: StringName in _skill_states:
		_skill_states[state_name].effect_component.initialize_skill()
	_connected_animation_controller = animation_controller
	_connected_animation_controller.driver_animation_finished.connect(_on_driver_animation_finished)
	animation_controller.initialize(animation_player)
	return true


## 按导出的技能名称解析当前实例节点；每次初始化重建，不改变编辑器权重或自动补齐配置。
## 缺失、类型不符的节点不写入缓存，后续配置校验在具体分支报告名称并阻止启动。
func _cache_skill_states() -> void:
	_skill_states.clear()
	# 当前配置的技能名称，正常情况下是本状态机直属子节点的名称。
	for state_name: StringName in skill_state_weights:
		# 名称对应的实例技能；所属状态机及名称一致性由后续配置校验检查。
		var skill: ZB001DoctorSkillState = get_node_or_null(NodePath(state_name)) as ZB001DoctorSkillState
		if is_instance_valid(skill):
			_skill_states[state_name] = skill


## [param animation_name] 为已结束的本体动作；只有死亡状态可以推进本体死亡序列。
func _on_driver_animation_finished(animation_name: StringName) -> void:
	if is_running and (_death_requested or boss.is_death) and current_state == dying_state:
		dying_state.on_driver_animation_finished(animation_name)


## 清理本体事件、控制器播放器连接和通用机甲结束信号；重新初始化时重建计时器缓存。
func _disconnect_animation_player() -> void:
	if is_instance_valid(_connected_animation_controller):
		if _connected_animation_controller.driver_animation_finished.is_connected(_on_driver_animation_finished):
			_connected_animation_controller.driver_animation_finished.disconnect(_on_driver_animation_finished)
		_connected_animation_controller.disconnect_players()
	_connected_animation_controller = null
	_skill_states.clear()
	_action_timers.clear()
	_last_action_speed = -1.0
	super._disconnect_animation_player()


## 死亡请求优先于技能请求；尚未启动或正在切换时延迟启动，避免重入 enter/exit。
func request_death() -> void:
	if _death_requested or not is_instance_valid(boss) or not boss.is_death:
		return
	_death_requested = true
	animation_controller.cancel_driver_reaction()
	_stop_action_timers()
	# 子状态机停止后会清空当前阶段，必须提前记录死亡是否需要先抬头。
	dying_state.prepare_interruption(current_state)
	# 立即停止当前技能子层，不能等下一物理帧再取消内部排队动作。
	if current_state is CharacterCompositeState:
		current_state.child_state_machine.stop()
	if is_running and not _switching:
		_pending_state = null
		change_state(dying_state)
	else:
		_start_death.call_deferred()


## 血量可能在延迟入场前归零，此时直接从 Dying 启动，等待中的 Enter 启动会自行取消。
func _start_death() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(boss) \
		or not boss.is_inside_tree() or boss.is_queued_for_deletion():
		return
	if is_running:
		change_state(dying_state)
	elif not start(dying_state):
		push_error("ZB001DoctorStateMachine：无法启动死亡演出，请检查状态与动画配置。")


## 已死亡的博士不能重新启动入场；死亡演出也不能通过 stop/start 重播。
## [param state] 指定启动状态；null 时使用已配置的 initial_state。
func start(state: CharacterState = null) -> bool:
	if is_running or _switching:
		return false
	if is_instance_valid(boss) and boss.is_death:
		if state != dying_state or not _death_requested or _death_started:
			return false
	# 提前死亡可能在普通初始化之前启动；初始化清理结束后才允许本体完成事件。
	if not _initialized and not initialize():
		return false
	animation_controller.set_active(true)
	# 通用启动成功后才记录死亡已开始，失败则恢复控制器停止状态。
	var started: bool = super.start(state)
	if not started:
		animation_controller.set_active(false)
	if started and current_state == dying_state:
		_death_started = true
	return started


## 死亡后只允许普通状态 -> Dying -> Dead，迟到的普通动作回调不能覆盖死亡请求。
## [param next_state] 请求进入的目标状态，必须是本状态机已注册的直属状态。
func change_state(next_state: CharacterState) -> bool:
	if _death_requested or (is_instance_valid(boss) and boss.is_death):
		if current_state == dead_state:
			return false
		if current_state == dying_state:
			if next_state != dead_state:
				return false
		elif next_state != dying_state:
			return false
	return super.change_state(next_state)


## 停止、重新初始化与离树都会经过此入口，清理共享计时和非当前状态的遗留任务。
func stop() -> void:
	if is_instance_valid(animation_controller):
		animation_controller.set_active(false)
	_stop_action_timers()
	super.stop()


## 先执行初始顺序并跳过不可用项，耗尽后使用 RandomPicker 按权重选择。
## 随机池只包含正权重且满足触发条件的技能，跳过技能不改变回合与上次技能记录。
## 每次从当前字典构建池，使运行中调整权重立即生效，无需额外维护缓存同步。
## 有多个可用技能且抽到上次技能时，移除它再重抽；唯一可用技能允许连续使用。
## 连续非吐球回合达到上限时优先返回吐球技能，保证周期性开放受击窗口。
func select_skill() -> ZB001DoctorSkillState:
	# 本轮 RandomPicker 输入项，只包含正且有限权重、满足触发条件的技能。
	var items: Array[Dictionary] = []
	# 候选收集完成后得到本轮吐球保底目标；不缓存到成员，也不延后可用性查询。
	var head_skill: ZB001DoctorStateHeadSkill = _collect_skill_candidates(items)
	# 按保底、开场、随机优先级得到本轮技能；各选择分支自行记录成功选择。
	var selected: ZB001DoctorSkillState = _select_guaranteed_head_skill(head_skill)
	if selected != null:
		return selected
	selected = _select_initial_skill()
	if selected != null:
		return selected
	return _select_random_skill(items)


## 一次遍历中先识别吐球，再按当前权重和触发条件收集候选；必须在任何选择分支之前完成。
## [param items] 为本轮新建的输出数组；按配置遍历顺序追加 RandomPicker 项，不清空或修改已有项。
## 返回本轮识别的吐球技能；没有有效引用时返回 null，零权重仍可作为保底目标。
func _collect_skill_candidates(items: Array[Dictionary]) -> ZB001DoctorStateHeadSkill:
	# 从已解析的配置中识别唯一的吐球技能；即使权重为 0，也保留它作为保底目标。
	var head_skill: ZB001DoctorStateHeadSkill
	# 当前配置的技能名称；权重每轮重新读取，运行中调整数值无需重建节点缓存。
	for state_name: StringName in skill_state_weights:
		# 初始化时解析的当前实例技能；运行中新增键要重新初始化，不能临时接管未校验的节点。
		var skill: ZB001DoctorSkillState = _skill_states.get(state_name)
		if not is_instance_valid(skill):
			continue
		if skill is ZB001DoctorStateHeadSkill:
			head_skill = skill
		# 当前技能的选择权重；0 表示禁用，负数及非有限值属于非法配置。
		var weight: float = skill_state_weights[state_name]
		if not is_finite(weight) or weight <= 0:
			continue
		if not skill.can_be_selected():
			continue
		items.append({"data": skill, "weight": weight})
	return head_skill


## 检查吐球保底；成功时记录回合，下一开场项相同则同时消费该项，未触发时返回 null。
## [param head_skill] 为本轮候选遍历识别的吐球引用；无效引用不触发保底，不再查询可用性。
func _select_guaranteed_head_skill(head_skill: ZB001DoctorStateHeadSkill) -> ZB001DoctorSkillState:
	# 尚未消耗的开场技能；空数组或序列耗尽后为 null，不改变后续随机权重。
	var initial_skill: ZB001DoctorSkillState = null
	if _initial_skill_index < initial_skill_sequence.size():
		initial_skill = initial_skill_sequence[_initial_skill_index]
	# 保底优先于固定顺序与随机选择；若下一项本来就是吐球，直接消费该项，避免重复插入。
	if _rounds_without_head_skill >= max_rounds_without_head_skill and is_instance_valid(head_skill):
		if initial_skill == head_skill:
			_initial_skill_index += 1
		_record_selected_skill(head_skill)
		return head_skill
	return null


## 消费开场顺序，跳过无效或不可用项；成功时记录回合，空数组或耗尽后返回 null。
## 每项都先推进索引再查询可用性，保留重复项与零随机权重项的固定顺序语义。
func _select_initial_skill() -> ZB001DoctorSkillState:
	# 本次消费的开场技能；无效或不可用时继续检查下一项。
	var initial_skill: ZB001DoctorSkillState
	# 固定顺序仍允许重复和零随机权重，但没有目标的技能直接跳过，不占用一个回合。
	while _initial_skill_index < initial_skill_sequence.size():
		initial_skill = initial_skill_sequence[_initial_skill_index]
		_initial_skill_index += 1
		if not is_instance_valid(initial_skill) or not initial_skill.can_be_selected():
			continue
		_record_selected_skill(initial_skill)
		return initial_skill
	return null


## 从已收集的临时池加权抽取；多候选重复上次技能时移除后重抽一次，成功时记录回合。
## [param items] 为本轮按当前权重和可用性构建的 RandomPicker 项；不重新查询技能或配置。
## 空池仍交由 RandomPicker 处理并返回 null，保留其空池行为及上次选择记录。
func _select_random_skill(items: Array[Dictionary]) -> ZB001DoctorSkillState:
	# 字典键天然唯一；重抽只修改临时池，不改变检查器中的配置权重。
	# 本轮临时加权选择器；重抽仅修改该实例，不改变导出的技能权重字典。
	var picker := RandomPicker.new(items, false)
	# 本轮抽中的技能；空池时为 null，满足重抽条件时会替换为另一项技能。
	var selected := picker.get_random_item() as ZB001DoctorSkillState
	if selected != null and selected == _last_selected_skill and picker.get_remaining_count() > 1:
		picker.remove_item(selected)
		selected = picker.get_random_item() as ZB001DoctorSkillState
	# 单个可用技能直接沿用；空池才返回 null，并保留上次记录供 Idle 稍后重试。
	if selected != null:
		_record_selected_skill(selected)
	return selected


## 统一记录初始顺序、随机与保底选择，子状态循环不调用此方法，因此不会重复累计回合。[br]
## [param selected] 本回合最终选择的有效技能；吐球重置保底计数，其他技能累计一次。
func _record_selected_skill(selected: ZB001DoctorSkillState) -> void:
	_last_selected_skill = selected
	if selected is ZB001DoctorStateHeadSkill:
		_rounds_without_head_skill = 0
	else:
		_rounds_without_head_skill += 1


## 内部子状态改变受击规则后补发根节点通知，主层切换期间已有统一通知。
func notify_skill_status_changed() -> void:
	if is_running and not _switching and not boss.is_death:
		boss.signal_status_update.emit()


## 方法轨道携带动画名，拒绝其他动作的迟到事件；随后沿当前技能逐层路由。
## [param animation_name] 需要匹配的动画资源名称，与方法关键帧中的动画参数保持一致。
## [param event_name] 动画方法轨道传入的事件名，由当前活动状态判断是否处理。
func notify_skill_event(animation_name: StringName, event_name: StringName) -> void:
	if not is_running or _death_requested or boss.is_death or not current_state is ZB001DoctorSkillState:
		return
	# current_animation 在自然播放结束后为空；同帧跨过释放帧和末尾时方法轨道仍会延迟调用。
	# assigned_animation 保留刚结束的动画，结合当前活动状态的事件去重接受这次合法释放。
	if animation_player.assigned_animation != animation_name:
		return
	notify_animation_event(event_name)


## 初始化时收集固定状态树的动作计时器；运行时不遍历节点，结构改变后需重新初始化。
func _cache_action_timers() -> void:
	_action_timers.clear()
	# 新收集的计时器尚未同步；即使重初始化后的倍率相同，也必须完成一次完整同步。
	_last_action_speed = -1.0
	# 只遍历主状态机子树，死亡保留计时器在博士根节点下，由博士单独管理。
	for node: Node in find_children("*", "Timer", true, false):
		if node is SpeedTimer:
			_action_timers.append(node)


## 停止本次初始化收集的动作计时器；忽略运行时已被释放的引用。
func _stop_action_timers() -> void:
	# 缓存可能保留已释放对象，先以 Variant 检查有效性，再访问计时器。
	for timer in _action_timers:
		if is_instance_valid(timer):
			timer.stop()


## 跟随主体实际播放倍率，包括暂停与自定义播放倍率；倍率未变时跳过整个计时器列表。
## 返回本次读取的非负动作倍率，供逐帧更新复用；全局倍率由 Timer 自行处理。
func sync_action_timer_speed() -> float:
	# 当前动作计时倍率；播放器暂停或停止时为零。
	var action_speed: float = _get_action_speed()
	if action_speed == _last_action_speed:
		return action_speed
	_last_action_speed = action_speed
	# 缓存可能保留已释放对象，先以 Variant 检查有效性，再访问计时器。
	for timer in _action_timers:
		if is_instance_valid(timer):
			timer.set_speed_scale(action_speed)
	return action_speed


## 读取主体实际播放速度；蹦极等待改由事件结束，不需要额外推进计时。
func _get_action_speed() -> float:
	# 停止、暂停或非法倍率统一视为零速，状态切换仍由 advance 处理。
	var action_speed := animation_player.get_playing_speed() if is_instance_valid(animation_player) else 0.0
	return maxf(action_speed, 0.0) if is_finite(action_speed) else 0.0


## 更新前恢复死亡优先级；每帧读取实际动作倍率，仅在变化时同步计时器，再消化状态请求。
## [param delta] 本次更新步长，单位为秒；角色倍率是否已换算由调用层约定。
func advance(delta: float) -> void:
	if is_instance_valid(animation_controller):
		animation_controller.sync_driver_speed()
	if _death_requested and is_running and current_state != dying_state and current_state != dead_state:
		_pending_state = dying_state
	# 本帧已经读取并同步的实际倍率，后续状态更新和视觉复位复用，不再重复读取播放器。
	var action_speed: float = sync_action_timer_speed()
	# 仍保留状态逐帧行为的动作时间语义；零速也必须处理死亡等待切换请求。
	# 动作秒只在主层换算一次，状态更新和视觉复位共用同一时间尺度。
	var action_delta: float = maxf(delta, 0.0) * action_speed
	super.advance(action_delta)
	if is_instance_valid(animation_controller):
		animation_controller.advance_visual_returns(action_delta)
	if current_state == dying_state or current_state == dead_state:
		_death_started = true


## 死亡已请求但还未切换时，禁止旧动画继续分发技能关键帧。
## [param event_name] 动画方法轨道传入的事件名，由当前活动状态判断是否处理。
func notify_animation_event(event_name: StringName) -> void:
	if _death_requested and current_state != dying_state and current_state != dead_state:
		return
	super.notify_animation_event(event_name)


## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func _on_animation_finished(anim_name: StringName) -> void:
	if _death_requested and current_state != dying_state:
		return
	super._on_animation_finished(anim_name)


## 启动前校验主流程、五技能及死亡链路，避免运行中卡在缺少动画或引用的状态。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func _get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if character != get_parent():
		detected_error = "character 必须绑定状态机所属的博士根节点。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(animation_controller) or animation_controller.get_parent() != boss:
		detected_error = "animation_controller 必须绑定博士根节点下的动画控制器。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 先验证播放器和基础动画，后续状态才可安全读取动画资源检查方法事件。
	var animation_error: String = animation_controller.get_configuration_error(boss, animation_player)
	if not animation_error.is_empty():
		return animation_error
	if not initial_state is ZB001DoctorStateEnter or not _is_registered(initial_state):
		detected_error = "initial_state 必须绑定直属的 ZB001DoctorStateEnter 入场状态。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not idle_state is ZB001DoctorStateIdle or not _is_registered(idle_state):
		detected_error = "idle_state 必须绑定直属的 ZB001DoctorStateIdle 待机状态。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_finite(idle_duration) or idle_duration <= 0:
		detected_error = "待机时间必须为有限正数。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if max_rounds_without_head_skill < 1:
		detected_error = "吐球保底的非吐球回合上限必须至少为 1。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if skill_state_weights.size() != 5:
		detected_error = "技能权重字典必须配置五个直属复合技能的节点名称。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 所有已校验技能权重的累加值；必须有限且大于 0 才能启动战斗。
	var total_weight := 0.0
	# 字典中吐球技能的数量，必须恰好为 1，避免保底目标缺失或产生歧义。
	var head_skill_count := 0
	# 字典天然保证名称唯一；同时检查节点名称和注册归属，拒绝路径别名及其他状态机的节点。
	# 当前配置的技能名称，必须与已经注册的直属技能节点名称一致。
	for state_name: StringName in skill_state_weights:
		# 名称对应的实例技能；缓存缺失或节点类型不符时为 null。
		var skill: ZB001DoctorSkillState = _skill_states.get(state_name)
		if not _is_registered(skill) or skill.name != state_name:
			detected_error = "技能权重名称 \"%s\" 必须对应已注册的直属复合技能节点。" % state_name
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		if skill is ZB001DoctorStateHeadSkill:
			head_skill_count += 1
		# 当前技能的选择权重；0 表示禁用，负数及非有限值属于非法配置。
		var weight: float = skill_state_weights[state_name]
		if not is_finite(weight) or weight < 0:
			detected_error = "%s 的技能权重必须为有限非负数。" % skill.name
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		# 当前技能及其子状态的配置错误；非空时阻止主状态机启动。
		var skill_error := skill.get_configuration_error()
		if not skill_error.is_empty():
			return skill_error
		total_weight += weight
	if head_skill_count != 1:
		detected_error = "技能权重字典必须包含唯一的吐球技能，供保底选择使用。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_finite(total_weight) or total_weight <= 0:
		detected_error = "至少启用一种有效权重的技能。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 开场数组中的当前技能，允许重复但必须来自已注册且通过配置检查的五种技能。
	for skill: ZB001DoctorSkillState in initial_skill_sequence:
		if not _is_registered(skill) or _skill_states.get(skill.name) != skill:
			detected_error = "初始技能顺序必须绑定权重表中名称对应的直属技能，不能留空或引用其他节点。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	if not idle_state.get_node_or_null("IdleWaitTimer") is SpeedTimer:
		detected_error = "Idle 必须配置 IdleWaitTimer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 当前待停止、同步倍率或校验配置的动作计时器。
	for timer: SpeedTimer in _action_timers:
		if not timer.one_shot or timer.autostart or timer.process_callback != Timer.TIMER_PROCESS_PHYSICS \
			or timer.process_mode != Node.PROCESS_MODE_INHERIT or timer.ignore_time_scale:
			detected_error = "动作计时器必须单次触发、禁止自动启动，使用物理更新并继承场景暂停与全局时间倍率。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	if not _is_registered(dying_state) or not _is_registered(dead_state):
		detected_error = "dying_state 和 dead_state 必须绑定直属的死亡状态。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 死亡阶段负责本体启动事件，博士根节点负责奖杯与保留计时依赖。
	var dying_error: String = dying_state.get_configuration_error()
	if not dying_error.is_empty():
		return dying_error
	return boss.get_death_configuration_error()
