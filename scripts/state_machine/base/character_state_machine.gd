extends Node
class_name CharacterStateMachine
## 通用节点状态机：只注册直属 CharacterState 子节点。
## 角色就绪后调用 initialize()，需要启动时调用 start()；不会自动播放动画。
## change_state() 只提交请求，下一个更新周期切换，避免回调中嵌套进入状态。
## 本类不决定角色的技能、动画播放、冰冻或死亡规则，这些由专用状态机扩展。

## 新状态 enter() 完成且状态机仍在运行时发出；首次启动的 previous_state 为 null。
signal state_changed(previous_state: CharacterState, next_state: CharacterState)

## 状态的所属角色，可在编辑器绑定，也可由 initialize() 传入。
@export var character: Character000Base
## 可选的主体播放器，仅用于接收动画结束信号；本类不控制其播放和速度。
@export var animation_player: AnimationPlayer
## start() 未指定状态时使用的入口，必须是本节点的直属状态子节点。
@export var initial_state: CharacterState

## 由本状态机维护；外部通过 start/change_state/stop 操作，不直接赋值。
var current_state: CharacterState
## 控制更新和事件分发，不等同于角色存活、动画播放或场景树暂停状态。
var is_running := false

## initialize() 建立的状态集合；新增子节点后需要重新初始化才能参与调度。
var _states: Array[CharacterState] = []
## 单个待切换请求；不会在提交请求的回调内部立即退出当前状态。
var _pending_state: CharacterState
## 保存实际连接的播放器，导出引用被替换后仍能断开旧连接。
var _connected_player: AnimationPlayer
var _initialized := false
## 标识 exit/enter 正在执行，防止启动、初始化和事件分发重入切换过程。
var _switching := false


## 加入场景树并不自动启动，等待角色或关卡完成初始化后显式调用 start()。
func _ready() -> void:
	set_physics_process(is_running)


## 专用状态机可覆盖此入口，限制能被它管理的角色类型。
func accepts_character(actor: Character000Base) -> bool:
	return is_instance_valid(actor)


## 可使用编辑器导出引用，也可在此显式传入角色和主体动画播放器。
## null 参数表示保留原引用，不表示清空。播放器可省略，角色和状态集合不可省略。
## 返回 true 表示注册和依赖注入完成，不代表已经启动。
## 除切换期间直接拒绝外，重新初始化会先停止旧状态并断开旧播放器；
## 因配置错误返回 false 时保持停止，不恢复先前运行中的状态。
func initialize(actor: Character000Base = null, player: AnimationPlayer = null) -> bool:
	if _switching:
		return false
	stop()
	_disconnect_animation_player()
	_initialized = false
	_states.clear()
	if actor != null:
		character = actor
	if player != null:
		animation_player = player
	if not accepts_character(character):
		return false
	# 只收集直属状态；辅助节点会被忽略，不递归接管其他状态机的状态。
	for child: Node in get_children():
		if child is CharacterState:
			var state := child as CharacterState
			if not state.accepts_character(character):
				_states.clear()
				return false
			_states.append(state)
	if _states.is_empty():
		return false
	if initial_state != null and not _states.has(initial_state):
		_states.clear()
		return false
	# 全部校验通过后再注入，避免配置无效时只初始化一部分子状态。
	for state: CharacterState in _states:
		state.setup(character, self)
	if is_instance_valid(animation_player):
		_connected_player = animation_player
		_connected_player.animation_finished.connect(_on_animation_finished)
	_initialized = true
	return true


## 从显式传入的状态或 initial_state 启动；未初始化时尝试使用现有引用初始化。
## 已在运行、正在切换或入口无效时返回 false，不重复执行当前状态的 enter()。
## 返回值反映 enter() 后是否仍运行，允许进入逻辑主动调用 stop()。
func start(state: CharacterState = null) -> bool:
	if is_running or _switching:
		return false
	if not _initialized and not initialize():
		return false
	var next_state := state if state != null else initial_state
	if not _is_registered(next_state):
		return false
	is_running = true
	set_physics_process(true)
	_switch_state(next_state)
	return is_running


## 停止状态调度并清除待切换状态；动画、技能实体的清理由具体状态 exit() 负责。
## 保留注册结果及播放器连接，停止期间丢弃事件，之后可再次 start()。
func stop() -> void:
	is_running = false
	set_physics_process(false)
	_pending_state = null
	var previous_state := current_state
	# 先清空引用，再调用退出逻辑；即使退出逻辑再次 stop()，也不会重复退出。
	current_state = null
	if is_instance_valid(previous_state):
		previous_state.exit()


## 同一更新周期内多次请求，以最后一个有效请求为准。
## true 仅表示请求已受理；进入下一周期前，stop() 或目标释放仍可能取消转换。
## 返回 false 的请求不覆盖已有请求，也不会重新进入当前状态。
func change_state(next_state: CharacterState) -> bool:
	if not is_running or not _is_registered(next_state):
		return false
	if next_state == current_state:
		return false
	_pending_state = next_state
	return true


## 默认随场景树的物理更新调度，继承场景树的暂停行为。
func _physics_process(delta: float) -> void:
	advance(delta)


## 统一的更新入口，便于在测试或自定义更新循环中使用。
## 手动调用时应先关闭本节点 physics_process，避免每帧更新两次。
## 每次只消化一个已提交请求，然后更新当前状态；update() 内产生的请求留到下次。
## 手动调用不会自动检查场景树暂停，调用方需控制调用时机；负 delta 按零处理。
func advance(delta: float) -> void:
	if not is_running or _switching:
		return
	if not is_instance_valid(character):
		stop()
		return
	if _pending_state != null:
		var next_state := _pending_state
		# 在进入回调前取走旧请求，保留新状态 enter() 中可能产生的下一次请求。
		_pending_state = null
		if _is_registered(next_state):
			_switch_state(next_state)
	if is_running and is_instance_valid(current_state):
		current_state.update(maxf(delta, 0.0))
	elif is_running:
		stop()


## 方法轨道或角色逻辑的统一事件入口，只转发给当前状态。
## 停止或切换期间的事件直接忽略、不补发；业务上的事件匹配和去重由子状态处理。
func notify_animation_event(event_name: StringName) -> void:
	if is_running and not _switching and is_instance_valid(current_state):
		current_state.on_animation_event(event_name)


## 仅连接 initialize() 指定的播放器，避免把驾驶员表情动画误送给主体状态。
## 此处只路由信号，不判断该动画是否属于当前动作，子状态应自行核对。
func _on_animation_finished(anim_name: StringName) -> void:
	if is_running and not _switching and is_instance_valid(current_state):
		current_state.on_animation_finished(anim_name)


## 内部切换事务：退出旧状态，再进入新状态；外部应调用 change_state()。
## 回调可能停止状态机或移除目标，因此退出旧状态后重新检查运行状态和注册关系。
func _switch_state(next_state: CharacterState) -> void:
	_switching = true
	var previous_state := current_state
	current_state = null
	if is_instance_valid(previous_state):
		previous_state.exit()
	if is_running and _is_registered(next_state):
		current_state = next_state
		current_state.enter()
	_switching = false
	# enter() 主动停止时不能再发出成功切换通知，避免外部误认为角色仍在执行动作。
	if is_running and current_state == next_state:
		state_changed.emit(previous_state, current_state)


## 同时检查生命周期、所属父节点和初始化时的注册结果。
## 防止切换到其他状态机的状态，或进入已经排队销毁、移走的节点。
func _is_registered(state: CharacterState) -> bool:
	return is_instance_valid(state) and not state.is_queued_for_deletion() \
		and state.get_parent() == self and _states.has(state)


## 重新初始化和离树时断开实际连接过的播放器，避免旧播放器继续发送通知。
func _disconnect_animation_player() -> void:
	if is_instance_valid(_connected_player):
		if _connected_player.animation_finished.is_connected(_on_animation_finished):
			_connected_player.animation_finished.disconnect(_on_animation_finished)
	_connected_player = null


## 离开场景树后终止调度和信号连接；再次使用需重新初始化注册结果。
func _exit_tree() -> void:
	stop()
	_disconnect_animation_player()
	_initialized = false
