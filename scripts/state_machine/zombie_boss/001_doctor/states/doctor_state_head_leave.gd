extends DoctorState
class_name DoctorStateHeadLeave
## 抬头：关闭可受击状态，动画完成后请求 Recover。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 通过统一受击入口关闭暴露窗口，再播放抬头动画，避免视觉已离场仍持续受伤。
func enter() -> void:
	pass


## 正常离开时结束本轮低头上下文；死亡打断时不再提交下一轮技能或恢复请求。
func exit() -> void:
	pass


## 抬头阶段不再推进已结束的暴露窗口，只维护需要的局部表现时间。
func update(_delta: float) -> void:
	pass


## 匹配抬头动画完成后请求 Recover，不能把驾驶员等其他动画当作主体抬头完成。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 可扩展抬头表现事件，但此阶段不重新开放受击或释放冰火球。
func on_animation_event(_event_name: StringName) -> void:
	pass
