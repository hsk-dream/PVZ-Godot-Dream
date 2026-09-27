extends CharacterState
class_name CharacterCompositeState
## 通用复合状态：拥有一个子状态机，父状态退出时立即停止整个内部流程。

## 本复合状态直属的子状态机，随父状态进入启动、退出停止。
@export var child_state_machine: CharacterStateMachine
## 子状态机是否已完成角色与播放器注入；成功前不转发更新和动画事件。
var child_initialized := false

## [param actor] 待检查或注入的所属角色；具体允许的角色类型由当前状态或状态机限定。
## [param machine] 管理当前状态的直属状态机，提供播放器与同层状态切换入口。
func setup(actor: Character000Base, machine: CharacterStateMachine) -> void:
	super.setup(actor, machine)
	child_initialized = false
	if is_instance_valid(child_state_machine) and child_state_machine.get_parent() == self:
		child_state_machine.externally_driven = true
		child_initialized = child_state_machine.initialize(actor, machine.animation_player)

func enter() -> void:
	if child_initialized:
		child_state_machine.start()

func exit() -> void:
	if is_instance_valid(child_state_machine):
		child_state_machine.stop()

## 子层只由活动父状态推进；delta 已由上层处理，不再乘角色或全局倍率。
## [param delta] 本次更新步长，单位为秒；角色倍率是否已换算由调用层约定。
func update(delta: float) -> void:
	if child_initialized:
		child_state_machine.advance(delta)

## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func on_animation_finished(anim_name: StringName) -> void:
	if child_initialized:
		child_state_machine.notify_animation_finished(anim_name)

## [param event_name] 动画方法轨道传入的事件名，由当前活动状态判断是否处理。
func on_animation_event(event_name: StringName) -> void:
	if child_initialized:
		child_state_machine.notify_animation_event(event_name)
