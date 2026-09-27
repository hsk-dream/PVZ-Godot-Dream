## 保持进入动画末帧，直到本批蹦极僵尸全部死亡或结束偷取，再播放离开动画。
extends ZB001DoctorState
class_name ZB001DoctorStateBungeeWait

## 批次完成后进入的同层状态，场景中绑定 Leave。
@export var next_state: CharacterState
## 本次等待的效果组件；退出时清除连接，不让旧批次影响后续技能。
var _bungee_effect: ZB001DoctorSkillBungee


## 只等待第 1 秒关键帧已经召唤的批次；先监听再读取状态，兼顾提前完成和后续完成。
func enter() -> void:
	state_machine.animation_player.pause()
	_bungee_effect = skill_state.effect_component as ZB001DoctorSkillBungee
	if _bungee_effect.batch_state == ZB001DoctorSkillBungee.BatchState.NOT_STARTED:
		# 缺少运行时释放事件属于流程错误，不在动画结束时补召唤，也不无限等待。
		push_error("BungeeWait：进入动画结束但召唤尚未开始，请检查第 1 秒的 bungee_release 关键帧。")
		skill_state.finish_skill()
		return
	_bungee_effect.batch_finished.connect(_on_batch_finished)
	if _bungee_effect.batch_state == ZB001DoctorSkillBungee.BatchState.COMPLETED:
		_on_batch_finished()


## 正常离开或死亡中断都清理监听；不删除已经生成的蹦极僵尸。
func exit() -> void:
	if is_instance_valid(_bungee_effect):
		if _bungee_effect.batch_finished.is_connected(_on_batch_finished):
			_bungee_effect.batch_finished.disconnect(_on_batch_finished)
		_bungee_effect.cancel_batch_tracking()
	_bungee_effect = null


## 死亡或退出后的迟到事件不能切换到 Leave；零只生成也经由此入口结束等待。
func _on_batch_finished() -> void:
	if state_machine.is_running and state_machine.current_state == self and skill_state.is_active_skill():
		state_machine.change_state(next_state)


## 校验组件类型和后续状态，等待已完全由事件驱动，不再需要占位计时器。
func get_configuration_error() -> String:
	if not skill_state is ZB001DoctorStateBungee:
		push_error("BungeeWait：必须位于蹦极技能内。")
		return "蹦极等待状态所属技能错误。"
	if not skill_state.effect_component is ZB001DoctorSkillBungee:
		push_error("BungeeWait：必须绑定蹦极效果组件。")
		return "蹦极等待效果组件错误。"
	if not next_state is ZB001DoctorStateBungeeLeave or next_state.get_parent() != state_machine:
		push_error("BungeeWait：必须连接同层的蹦极离开状态。")
		return "蹦极等待状态后续连线错误。"
	return ""
