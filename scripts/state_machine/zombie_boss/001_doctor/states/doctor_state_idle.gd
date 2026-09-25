extends DoctorState
class_name DoctorStateIdle
## 待机：在 update() 中检查冷却并请求下一个可用技能状态。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 准备待机表现和本次决策间隔；技能冷却属于共享数据，不在每次待机时重置。
func enter() -> void:
	pass


## 清理尚未提交的本地决策数据，已锁定的下一招参数需交给后续技能状态。
func exit() -> void:
	pass


## 后续在此筛选冷却结束、目标有效的技能，再请求切换；避免每帧重复随机选择。
func update(_delta: float) -> void:
	pass


## 待机动画通常循环，不依赖其结束通知推进战斗；下一招由决策条件决定。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 默认不释放技能；如扩展待机表现事件，应与攻击事件分开处理。
func on_animation_event(_event_name: StringName) -> void:
	pass
