extends Node
class_name CharacterState
## 通用角色状态。由父状态机调用生命周期，不自行运行每帧回调。
## 本类只提供接口；具体行为由角色的子状态实现。
## 子类通过 state_machine.change_state() 请求转换，不直接修改当前状态引用。

## 由 setup() 注入的角色；不通过固定的父节点层级查找，以便其他角色复用。
var character: Character000Base
## 负责本状态调度的父状态机。setup() 完成前不要使用这两个引用。
var state_machine: CharacterStateMachine


## 初始化前的兼容性检查。通用状态接受任意有效 Character000Base；
## 角色专用状态可覆盖此方法限制类型，避免初始化后才出现类型转换失败。
## [param actor] 待检查或注入的所属角色；具体允许的角色类型由当前状态或状态机限定。
func accepts_character(actor: Character000Base) -> bool:
	return is_instance_valid(actor)


## 由状态机完成全部子状态校验后统一调用，只注入依赖，不启动动作。
## 重新初始化时可能再次调用；动作临时数据应在 enter() 中重置。
## [param actor] 待检查或注入的所属角色；具体允许的角色类型由当前状态或状态机限定。
## [param machine] 管理当前状态的直属状态机，提供播放器与同层状态切换入口。
func setup(actor: Character000Base, machine: CharacterStateMachine) -> void:
	character = actor
	state_machine = machine


## 每次成为当前状态时调用一次，用于准备本次目标、局部计时和动画。
## 此时属于切换过程，不应依赖同步返回的动画事件驱动技能。
func enter() -> void:
	pass


## 离开当前状态或停止状态机时调用，用于清理本状态拥有的临时效果和回调。
## 不清除下一状态仍需使用的共享上下文，例如一整轮低头的剩余暴露时间。
func exit() -> void:
	pass


## 仅当前状态接收更新。delta 由状态机传入，不再自行乘全局时间倍率。
## 子状态不额外实现每帧调度，以免非当前状态仍在运行或重复计时。
## [param _delta] 本次更新的时间步长（秒）；当前状态没有逐帧行为，因此不使用。
func update(_delta: float) -> void:
	pass


## 接收主体播放器的完成通知。子类须核对动画名及本次动作是否有效，
## 再决定是否请求转换；循环动画的退出应由计时或业务条件驱动。
## [param _anim_name] 收到的动画完成名称；当前状态不依赖该通知推进流程。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 接收方法轨道等来源的逻辑事件，如 ball_release；模板不解释事件内容。
## 需要只生效一次的技能，应由具体状态记录本次动作是否已执行。
## [param _event_name] 收到的动画事件名；当前状态不处理技能释放事件。
func on_animation_event(_event_name: StringName) -> void:
	pass
