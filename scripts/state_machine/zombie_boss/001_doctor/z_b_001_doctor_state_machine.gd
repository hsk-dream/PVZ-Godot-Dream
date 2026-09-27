extends CharacterStateMachine
class_name ZB001DoctorStateMachine
## 博士专用状态机：选择五种技能、同步计时倍率和校验配置，死亡始终优先。
## 由博士正常出战初始化显式启动；动画播放由状态负责，速度仍由动画组件处理。
## 每个技能管理自己的内部阶段与共享数据，根层不决定技能如何收尾。
## 场景中绑定角色、播放器、入场、待机、五技能和死亡状态。

## 主体入场动画名；必须非循环，播放结束后进入普通待机。
const ENTER_ANIMATION: StringName = &"Zombie_boss_enter"
## 主体普通待机动画名；必须循环播放，技能选择由待机计时器触发。
const IDLE_ANIMATION: StringName = &"Zombie_boss_idle"
## 主体低头动画名；第 2 秒开启受击，播放到位后进入吐球前待机。
const HEAD_ENTER_ANIMATION: StringName = &"Zombie_boss_head_enter"
## 吐球前后共用的低头循环动画；两段等待分别由自己的 SpeedTimer 控制。
const HEAD_IDLE_ANIMATION: StringName = &"Zombie_boss_head_idle"
## 主体抬头收尾动画名；第 0.6667 秒关闭受击，完成后结束本轮低头技能。
const HEAD_LEAVE_ANIMATION: StringName = &"Zombie_boss_head_leave"
## 主体死亡动画名；其中的方法关键帧负责请求生成奖杯。
const DEATH_ANIMATION: StringName = &"Zombie_boss_death"
## 驾驶舱博士的死亡动画名，与主体死亡演出同步播放。
const DRIVER_DEATH_ANIMATION: StringName = &"Zombie_Boss_driver_death"

## 主层只选择完整技能，内部动画阶段与收尾由各复合技能管理。
## 普通待机状态引用；入场或技能收尾后进入，等待下一次技能选择。
@export var idle_state: ZB001DoctorStateIdle
## 键为直属技能状态，值为选择权重；零权重或当前不满足触发条件时不参与 Idle 随机选择。
## 权重由主状态机配置，技能自身提供可用性查询并管理动作；初始顺序与吐球保底不受零权重限制。
@export var skill_state_weights: Dictionary[ZB001DoctorSkillState, float] = {}
## 开场按数组顺序选择完整技能，不可用项直接跳过；耗尽后改为加权随机，空数组直接随机。
## 可重复配置同一技能，固定顺序不执行随机去重；吐球保底插队时保留尚未执行的下一项。
@export var initial_skill_sequence: Array[ZB001DoctorSkillState] = []
## 死亡演出状态引用，死亡请求会优先切换到此状态。
@export var dying_state: ZB001DoctorStateDying
## 死亡演出完成后的终止状态引用，负责停止行动并清理角色。
@export var dead_state: ZB001DoctorStateDead
## 驾驶员只同步死亡演出，不参与主体动画事件分发。
@export var driver_animation_player: AnimationPlayer
## 返回 Idle 后选择下一技能前等待的动作秒数；随主体动画倍率变化，必须为有限正数。
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
	return true


## 死亡请求优先于技能请求；尚未启动或正在切换时延迟启动，避免重入 enter/exit。
func request_death() -> void:
	if _death_requested or not is_instance_valid(boss) or not boss.is_death:
		return
	_death_requested = true
	_stop_action_timers()
	# 子状态机停止后会清空当前阶段，必须提前记录死亡是否需要先抬头。
	dying_state.prepare_head_return(current_state)
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
	if is_instance_valid(boss) and boss.is_death:
		if state != dying_state or not _death_requested or _death_started:
			return false
	# 通用状态机启动是否成功；成功进入 Dying 时同步记录死亡演出已开始。
	var started := super.start(state)
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
	# 从注册字典中识别唯一的吐球技能；即使权重为 0，也保留它作为保底目标。
	var head_skill: ZB001DoctorStateHeadSkill
	# 当前遍历的技能状态键，用于构建随机池或检查状态归属与技能配置。
	for skill: ZB001DoctorSkillState in skill_state_weights:
		if not is_instance_valid(skill):
			continue
		if skill is ZB001DoctorStateHeadSkill:
			head_skill = skill
		# 当前技能的选择权重；0 表示禁用，负数及非有限值属于非法配置。
		var weight := skill_state_weights[skill]
		if not is_finite(weight) or weight <= 0:
			continue
		if not skill.can_be_selected():
			continue
		items.append({"data": skill, "weight": weight})
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
	# 固定顺序仍允许重复和零随机权重，但没有目标的技能直接跳过，不占用一个回合。
	while _initial_skill_index < initial_skill_sequence.size():
		initial_skill = initial_skill_sequence[_initial_skill_index]
		_initial_skill_index += 1
		if not is_instance_valid(initial_skill) or not initial_skill.can_be_selected():
			continue
		_record_selected_skill(initial_skill)
		return initial_skill
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


## 计时节点只在博士层管理，通用状态机仍只负责状态调度。
## 递归收集技能拥有的计时器，结构调整时不用在主层维护内部节点路径。
func _get_action_timers() -> Array[SpeedTimer]:
	# 博士状态机子树中的全部 SpeedTimer 引用，用于统一停止、同步速度或校验配置。
	var timers: Array[SpeedTimer] = []
	# 状态机子树中当前找到的 Timer 节点，筛选为 SpeedTimer 后才加入管理列表。
	for node in find_children("*", "Timer", true, false):
		if node is SpeedTimer:
			timers.append(node)
	return timers


func _stop_action_timers() -> void:
	# 当前待停止、同步倍率或校验配置的动作计时器。
	for timer in _get_action_timers():
		timer.stop()


## 跟随主体实际播放倍率，包括播放器暂停和自定义播放倍率；全局倍率由 Timer 自行处理。
func sync_action_timer_speed() -> void:
	# 主体当前实际播放倍率；播放器停止、暂停或倍率非法时最终按 0 处理。
	var action_speed := _get_action_speed()
	# 当前待停止、同步倍率或校验配置的动作计时器。
	for timer in _get_action_timers():
		timer.set_speed_scale(action_speed)


func _get_action_speed() -> float:
	# 主体当前实际播放倍率；播放器停止、暂停或倍率非法时最终按 0 处理。
	var action_speed := animation_player.get_playing_speed() if is_instance_valid(animation_player) else 0.0
	return maxf(action_speed, 0.0) if is_finite(action_speed) else 0.0


## 更新前恢复死亡优先级；Timer 自行倒计时，这里只同步倍率并消化状态请求。
## [param delta] 本次更新步长，单位为秒；角色倍率是否已换算由调用层约定。
func advance(delta: float) -> void:
	if _death_requested and is_running and current_state != dying_state and current_state != dead_state:
		_pending_state = dying_state
	sync_action_timer_speed()
	# 仍保留状态逐帧行为的动作时间语义；零速也必须处理死亡等待切换请求。
	super.advance(maxf(delta, 0.0) * _get_action_speed())
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
	if not is_instance_valid(animation_player):
		detected_error = "未绑定有效的主体 AnimationPlayer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if animation_player != character.get_node_or_null("AnimationPlayer"):
		detected_error = "animation_player 必须绑定博士根节点下的主体 AnimationPlayer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
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
		detected_error = "必须绑定五个独立复合技能。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 所有已校验技能权重的累加值；必须有限且大于 0 才能启动战斗。
	var total_weight := 0.0
	# 字典中吐球技能的数量，必须恰好为 1，避免保底目标缺失或产生歧义。
	var head_skill_count := 0
	# 字典天然保证键唯一；此处检查状态归属与权重，避免非法数值污染随机选择。
	# 当前遍历的技能状态键，用于构建随机池或检查状态归属与技能配置。
	for skill: ZB001DoctorSkillState in skill_state_weights:
		if not _is_registered(skill):
			detected_error = "技能权重字典的键必须是已注册的直属复合状态。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		if skill is ZB001DoctorStateHeadSkill:
			head_skill_count += 1
		# 当前技能的选择权重；0 表示禁用，负数及非有限值属于非法配置。
		var weight := skill_state_weights[skill]
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
		if not _is_registered(skill) or not skill_state_weights.has(skill):
			detected_error = "初始技能顺序必须绑定技能权重字典中的直属技能，不能留空或引用其他节点。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	if not idle_state.get_node_or_null("IdleWaitTimer") is SpeedTimer:
		detected_error = "Idle 必须配置 IdleWaitTimer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 博士状态机子树中的全部 SpeedTimer 引用，用于统一停止、同步速度或校验配置。
	var timers := _get_action_timers()
	# 当前待停止、同步倍率或校验配置的动作计时器。
	for timer in timers:
		if not timer.one_shot or timer.autostart or timer.process_callback != Timer.TIMER_PROCESS_PHYSICS \
			or timer.process_mode != Node.PROCESS_MODE_INHERIT or timer.ignore_time_scale:
			detected_error = "动作计时器必须单次触发、禁止自动启动，使用物理更新并继承场景暂停与全局时间倍率。"
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	if not _is_registered(dying_state) or not _is_registered(dead_state):
		detected_error = "dying_state 和 dead_state 必须绑定直属的死亡状态。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(driver_animation_player) or not driver_animation_player.has_animation(DRIVER_DEATH_ANIMATION):
		detected_error = "必须绑定具有死亡动画的驾驶员 AnimationPlayer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not character.get_node_or_null("%TrophySpawnPoint") is Marker2D:
		detected_error = "博士场景必须具有唯一命名的 TrophySpawnPoint。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 当前待检查的必需动画名称，用于确认资源存在及循环方式正确。
	for animation_name: StringName in [ENTER_ANIMATION, IDLE_ANIMATION, DEATH_ANIMATION, HEAD_ENTER_ANIMATION, HEAD_LEAVE_ANIMATION]:
		if not animation_player.has_animation(animation_name):
			detected_error = "主体播放器缺少动画：%s。" % animation_name
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	if animation_player.get_animation(ENTER_ANIMATION).loop_mode != Animation.LOOP_NONE:
		detected_error = "入场动画必须为非循环，否则无法依靠结束通知进入待机。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if animation_player.get_animation(IDLE_ANIMATION).loop_mode != Animation.LOOP_LINEAR:
		detected_error = "待机动画必须为线性循环。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 当前待检查的必需动画名称，用于确认资源存在及循环方式正确。
	for animation_name: StringName in [HEAD_ENTER_ANIMATION, HEAD_LEAVE_ANIMATION]:
		if animation_player.get_animation(animation_name).loop_mode != Animation.LOOP_NONE:
			detected_error = "低头和抬头动画必须为非循环：%s。" % animation_name
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	# 主体死亡动画资源，用于校验非循环播放和奖杯请求关键帧。
	var death_animation := animation_player.get_animation(DEATH_ANIMATION)
	if death_animation.loop_mode != Animation.LOOP_NONE:
		detected_error = "死亡动画必须为非循环。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not _has_trophy_keyframe(death_animation):
		detected_error = "死亡动画必须包含调用博士 request_trophy() 的有效方法关键帧。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""


## 仅检查启用、指向角色根节点且位于动画时长内的方法轨道，不用定时器代替缺失的轨道。
## [param animation] 待检查方法轨道的动画资源，不会在检查过程中修改。
func _has_trophy_keyframe(animation: Animation) -> bool:
	# 当前动画轨道的索引，从 0 开始；仅符合路径与类型要求的方法轨道参与检查。
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_METHOD \
			or not animation.track_is_enabled(track) or animation.track_get_path(track) != NodePath("."):
			continue
		# 当前方法轨道中的关键帧索引，用于读取回调内容与触发时间。
		for key in animation.track_get_key_count(track):
			# 方法关键帧的调用数据，包含 method 方法名与 args 参数数组。
			var event: Dictionary = animation.track_get_key_value(track, key)
			# 当前奖杯请求关键帧的时间，单位为动画秒，必须位于动画长度范围内。
			var time := animation.track_get_key_time(track, key)
			if event.get("method") == &"request_trophy" and event.get("args", []).is_empty() \
				and time >= 0 and time <= animation.length:
				return true
	return false


## 校验方法轨道确实路由到本状态机，且动画与事件参数一致；缺帧时拒绝开战。
## [param animation] 待检查方法轨道的动画资源，不会在检查过程中修改。
## [param animation_name] 需要匹配的动画资源名称，与方法关键帧中的动画参数保持一致。
## [param event_name] 动画方法轨道传入的事件名，由当前活动状态判断是否处理。
func has_skill_keyframe(animation: Animation, animation_name: StringName, event_name: StringName) -> bool:
	# 匹配技能动画名、事件名和有效时间范围的释放关键帧数量，必须恰好为 1。
	var count := 0
	# 当前动画轨道的索引，从 0 开始；仅符合路径与类型要求的方法轨道参与检查。
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_METHOD or not animation.track_is_enabled(track) \
			or animation.track_get_path(track) != NodePath("StateMachine"):
			continue
		# 当前方法轨道中的关键帧索引，用于读取回调内容与触发时间。
		for key in animation.track_get_key_count(track):
			# 方法关键帧的调用数据，包含 method 方法名与 args 参数数组。
			var event: Dictionary = animation.track_get_key_value(track, key)
			if event.get("method") == &"notify_skill_event" and event.get("args") == [animation_name, event_name] \
				and animation.track_get_key_time(track, key) > 0 and animation.track_get_key_time(track, key) < animation.length:
				count += 1
	return count == 1
