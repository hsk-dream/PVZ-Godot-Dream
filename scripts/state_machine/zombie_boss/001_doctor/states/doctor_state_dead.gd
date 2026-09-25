extends DoctorState
class_name DoctorStateDead
## 死亡完成：向博士本体或关卡发出一次完成通知。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 预留死亡完成通知入口；一次性结算标记应由本体或关卡持有，避免重入造成重复奖励。
func enter() -> void:
	pass


## 允许关卡卸载时清理残留引用，不在退出时恢复角色或重新播放死亡动画。
func exit() -> void:
	pass


## 终结状态不再调度普通技能；需要停止每帧更新时由父层统一决定。
func update(_delta: float) -> void:
	pass


## 终结状态不依赖动画继续推进，不因收到迟到的完成通知返回存活状态。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 不再接受技能事件；死亡后额外的表现或场景切换由关卡流程管理。
func on_animation_event(_event_name: StringName) -> void:
	pass
