extends ZB000Base
class_name ZB001Doctor
## 博士本体负责出战初始化和死亡通知；动画与状态转换交给专用状态机。

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
