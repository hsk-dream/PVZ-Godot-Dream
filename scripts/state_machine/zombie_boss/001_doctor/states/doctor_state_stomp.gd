extends DoctorState
class_name DoctorStateStomp
## 踩踏：进入时锁定落点并预警，在落脚关键帧结算效果。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 锁定踩踏格子及动画变体，显示对应预警；预警出现后保持落点一致。
func enter() -> void:
	pass


## 移除本次踩踏预警，取消尚未落地的效果；被打断时不补算踩踏伤害。
func exit() -> void:
	pass


## 维护预警或动作局部计时，实际植物破坏应与落脚关键帧一致。
func update(_delta: float) -> void:
	pass


## 匹配当前踩踏动画后请求 Recover；死亡打断由专用状态机统一处理。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 仅在有效落脚事件中调用博士本体结算范围，并记录本次已经落地，防止重复结算。
func on_animation_event(_event_name: StringName) -> void:
	pass
