extends ZB001DoctorState
class_name ZB001DoctorStateHeadIdle
## 吐球前后共用的低头待机状态；继承已有受击窗口，不参与主层技能选择。

## 正常动作速度下的等待秒数；0 跳过此阶段，必须为有限非负数。
@export_range(0.0, 60.0, 0.1, "or_greater") var wait_duration: float = 1.0
## 本节点专用的单次计时器，跟随博士动画倍率，并继承场景暂停。
@export var wait_timer: SpeedTimer
## 等待结束后进入的同层状态；吐球前连接 SpitBall，吐球后连接 RaiseHead。
@export var next_state: CharacterState


## 只在进入时播放一次循环动画；零时长直接提交切换，不启动不支持零周期的计时器。
func enter() -> void:
	boss.is_idle = false
	if wait_duration == 0.0:
		state_machine.change_state(next_state)
		return
	state_machine.animation_player.play(ZB001DoctorStateMachine.HEAD_IDLE_ANIMATION)
	doctor_state_machine.sync_action_timer_speed()
	wait_timer.start_scaled(wait_duration)


## 正常离开和死亡中断都会停止本阶段计时，不影响下一阶段独立的计时器。
func exit() -> void:
	if is_instance_valid(wait_timer):
		wait_timer.stop()


## 只允许当前活动阶段推进流程，死亡或退出后到达的旧通知不能继续吐球或收尾。
func _on_wait_timer_timeout() -> void:
	if state_machine.is_running and state_machine.current_state == self and skill_state.is_active_skill():
		state_machine.change_state(next_state)


## 检查等待时长、计时器归属与连接；计时器运行模式由博士主状态机统一检查。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not skill_state is ZB001DoctorStateHeadSkill:
		detected_error = "低头待机必须属于 HeadSkill。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_finite(wait_duration) or wait_duration < 0.0:
		detected_error = "低头待机时长必须为有限非负数。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(wait_timer) or wait_timer.get_parent() != self:
		detected_error = "低头待机必须绑定自身的 SpeedTimer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not wait_timer.timeout.is_connected(_on_wait_timer_timeout):
		detected_error = "低头待机计时器必须连接本状态的超时回调。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(next_state) or next_state.get_parent() != state_machine or next_state == self:
		detected_error = "低头待机必须连接有效的同层后续状态。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""
