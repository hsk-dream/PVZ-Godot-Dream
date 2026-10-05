## 博士动画方法事件协议；集中定义固定事件名及查询入口，只读资源，不判断业务有效性或报错。
extends RefCounted
class_name ZB001DoctorAnimationEvents

## 当前动作开始定位部件的事件，允许配置在动画起点。
const POSITION_MOVE: StringName = &"position_move"
## 当前动作开始复位部件的事件，业务校验要求位于动画内部。
const POSITION_RETURN: StringName = &"position_return"
## 低头过程中开启角色受击窗口的事件。
const HURT_ENABLE: StringName = &"hurt_enable"
## 抬头过程中关闭角色受击窗口的事件。
const HURT_DISABLE: StringName = &"hurt_disable"
## 机甲死亡动画启动驾驶员死亡序列的事件。
const DRIVER_DEATH: StringName = &"driver_death"

## 技能动画方法轨道的目标，路径相对博士机甲动画根节点。
const SKILL_EVENT_TARGET: NodePath = ^"StateMachine"
## 技能事件方法名；参数依次为动画名和事件名。
const SKILL_EVENT_METHOD: StringName = &"notify_skill_event"
## 主层状态动画方法轨道的目标，路径相对博士机甲动画根节点。
const STATE_EVENT_TARGET: NodePath = ^"StateMachine"
## 主层状态事件方法名；唯一参数为事件名。
const STATE_EVENT_METHOD: StringName = &"notify_animation_event"
## 奖杯请求方法轨道的目标，即博士动画根节点自身。
const TROPHY_REQUEST_TARGET: NodePath = ^"."
## 根角色的奖杯请求方法名；方法不接收参数。
const TROPHY_REQUEST_METHOD: StringName = &"request_trophy"


## 返回技能协议完全匹配的关键帧秒数；空动画或无匹配时返回空数组，不修改资源或报错。[br]
## [param animation] 待查询动画；[param animation_name] 轨道方法的动画参数。[br]
## [param event_name] 轨道方法的事件参数；[param include_edges] 是否接受动画起点和终点。
static func get_skill_event_times(animation: Animation, animation_name: StringName, event_name: StringName, include_edges: bool = true) -> Array[float]:
	return AnimationMethodQuery.get_times(animation, SKILL_EVENT_TARGET, SKILL_EVENT_METHOD, [animation_name, event_name], include_edges)


## 返回主层状态协议完全匹配的关键帧秒数；空动画或无匹配时返回空数组，不修改资源或报错。[br]
## [param animation] 待查询动画；[param event_name] 轨道方法的事件参数。[br]
## [param include_edges] 是否接受动画起点和终点。
static func get_state_event_times(animation: Animation, event_name: StringName, include_edges: bool = true) -> Array[float]:
	return AnimationMethodQuery.get_times(animation, STATE_EVENT_TARGET, STATE_EVENT_METHOD, [event_name], include_edges)


## 返回根节点奖杯请求协议完全匹配的关键帧秒数；空动画或无匹配时返回空数组，不修改资源或报错。[br]
## [param animation] 待查询动画；[param include_edges] 是否接受动画起点和终点。
static func get_trophy_request_times(animation: Animation, include_edges: bool = true) -> Array[float]:
	return AnimationMethodQuery.get_times(animation, TROPHY_REQUEST_TARGET, TROPHY_REQUEST_METHOD, [], include_edges)
