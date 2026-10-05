## 一种场地中单个技能的部件平移参数；触发时刻由动画方法轨道决定，资源不保存运行时节点。
extends Resource
class_name ZB001DoctorPartMotionConfig

## 从当前位置到本轮目标位置的动作秒数；0 表示立即定位，必须为有限非负数。
@export_range(0.0, 2.0, 0.01, "or_greater") var move_duration: float = 0.3
## 从当前位置回到初始化待机位置的动作秒数；0 表示立即复位，必须为有限非负数。
@export_range(0.0, 2.0, 0.01, "or_greater") var return_duration: float = 0.2
## 定位与复位共用的插值曲线；默认正弦曲线使起止速度平缓。
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
## 定位与复位共用的缓动方向；默认同时缓入和缓出。
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT


## [param context] 为使用该配置的技能路径；空字符串表示有效，错误在本检测分支报告。
func get_configuration_error(context: String) -> String:
	if not is_finite(move_duration) or move_duration < 0.0 \
		or not is_finite(return_duration) or return_duration < 0.0:
		push_error("%s：部件定位与复位时长必须为有限非负动作秒数。" % context)
		return "部件平移时长无效。"
	if transition_type < Tween.TRANS_LINEAR or transition_type > Tween.TRANS_SPRING \
		or ease_type < Tween.EASE_IN or ease_type > Tween.EASE_OUT_IN:
		push_error("%s：部件平移的曲线或缓动方向无效。" % context)
		return "部件平移曲线无效。"
	return ""
