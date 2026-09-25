extends DoctorState
class_name DoctorStateDying
## 死亡演出：取消当前攻击与冻结，死亡动画完成后请求 Dead。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 接入死亡逻辑时，统一取消攻击、关闭受击并解除冻结，再播放死亡动画。
func enter() -> void:
	pass


## 清理死亡演出临时资源；不得恢复存活状态的受击、技能计时或旧动作回调。
func exit() -> void:
	pass


## 仅更新死亡演出需要的数据，不继续技能冷却和低头循环。
func update(_delta: float) -> void:
	pass


## 匹配死亡动画后请求 Dead；胜利结算交给死亡完成通知的接收方。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 只处理死亡爆炸等演出事件，忽略迟到的召唤、踩踏和吐球释放事件。
func on_animation_event(_event_name: StringName) -> void:
	pass
