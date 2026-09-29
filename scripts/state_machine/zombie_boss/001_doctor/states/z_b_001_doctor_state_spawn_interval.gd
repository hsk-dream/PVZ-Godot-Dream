extends ZB001DoctorState
class_name ZB001DoctorStateSpawnInterval
## 放置技能内部的等待阶段：播放待机动画，到时准备下一只，不触发主层技能选择。

## 两次放置之间的单次计时器；倍率与暂停由博士状态机统一同步。
@onready var spawn_interval_timer: SpeedTimer = get_node_or_null("SpawnIntervalTimer") as SpeedTimer


## 在整轮技能内保持行动状态，仅借用待机动画表现两次放置之间的停顿。
func enter() -> void:
	doctor_state_machine.animation_controller.play_mech_action(ZB001DoctorAnimations.IDLE_ANIMATION, ZB001DoctorAnimationController.DriverReaction.DRIVE)
	# 播放后再同步倍率，避免沿用上一段动画结束时的零倍率。
	doctor_state_machine.sync_action_timer_speed()
	spawn_interval_timer.start_scaled((skill_state as ZB001DoctorStateSpawn).spawn_interval_duration)


## 正常结束或死亡中断时停止等待，避免遗留计时推动下一次放置。
func exit() -> void:
	if is_instance_valid(spawn_interval_timer):
		spawn_interval_timer.stop()


## 仅活动技能的当前间隔状态可继续循环；死亡或退出后的迟到通知直接忽略。
func _on_spawn_interval_timer_timeout() -> void:
	if state_machine.is_running and state_machine.current_state == self and skill_state.is_active_skill():
		state_machine.change_state(state_machine.initial_state)


## 验证计时依赖与循环入口，具体计时器模式由博士根状态机统一检查。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not skill_state is ZB001DoctorStateSpawn:
		detected_error = "Interval 必须属于放置僵尸技能。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not state_machine.initial_state is ZB001DoctorStateSkillPrepare:
		detected_error = "Interval 必须通过 Prepare 入口准备下一次放置。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(spawn_interval_timer):
		detected_error = "Interval 必须配置 SpawnIntervalTimer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not spawn_interval_timer.timeout.is_connected(_on_spawn_interval_timer_timeout):
		detected_error = "SpawnIntervalTimer 必须连接间隔状态的超时回调。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""
