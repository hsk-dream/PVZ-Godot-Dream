extends Camera2D
class_name MainGameCamera
## 主游戏镜头：横移使用全局位置，落地震动使用独立偏移，两者可以同时进行。

## 主游戏短促震动事件；参数依次为二维幅度、持续游戏秒数和每秒振动次数。
const SHAKE_EVENT: String = "main_game_camera_shake"
## 当前震动开始前的相机偏移；重复触发期间不重新取值，避免偏移累积。
var _shake_base_offset: Vector2 = Vector2.ZERO
## 当前震动的横向和纵向最大幅度，单位为相机坐标像素。
var _shake_amplitude: Vector2 = Vector2.ZERO
## 本次震动的持续时间，单位为游戏秒，不额外乘角色动画速度。
var _shake_duration: float = 0.0
## 本次震动已消耗的游戏秒数；场景暂停时不推进。
var _shake_elapsed: float = 0.0
## 当前震动的振动频率，单位为每秒次数。
var _shake_frequency: float = 20.0


## 监听表现事件；没有震动时关闭逐帧更新，镜头横移 Tween 不受影响。
func _ready() -> void:
	set_process(false)
	EventBus.subscribe(SHAKE_EVENT, shake_once)


## 离开关卡时解除事件监听并恢复原偏移，避免重新入树后残留震动位置。
func _exit_tree() -> void:
	EventBus.unsubscribe(SHAKE_EVENT, shake_once)
	stop_shake()


## 触发一次当前镜头的震动；非当前镜头或无效参数不处理。
## [param amplitude] 横纵最大偏移，单位为像素；负数按绝对值处理，零向量不触发。
## [param duration] 持续游戏秒数，必须为有限正数；暂停与全局时间倍率自然生效。
## [param frequency] 每秒振动次数，必须为有限正数；重复请求取较大幅度和频率并刷新衰减。
func shake_once(amplitude: Vector2, duration: float, frequency: float = 20.0) -> void:
	if not is_current() or not amplitude.is_finite() or amplitude.is_zero_approx() \
		or not is_finite(duration) or duration <= 0.0 or not is_finite(frequency) or frequency <= 0.0:
		return
	if _shake_duration <= 0.0:
		_shake_base_offset = offset
		_shake_amplitude = amplitude.abs()
		_shake_frequency = frequency
	else:
		# 合并当前剩余震动，不新建并行补间，也不把当前抖动后的偏移当作原点。
		_shake_amplitude = Vector2(maxf(_shake_amplitude.x, absf(amplitude.x)), maxf(_shake_amplitude.y, absf(amplitude.y)))
		_shake_frequency = maxf(_shake_frequency, frequency)
	_shake_duration = maxf(_shake_duration - _shake_elapsed, duration)
	_shake_elapsed = 0.0
	# 事件当帧先给出纵向冲击；暂停期间到达的请求留到恢复后推进，不立即改变画面。
	if not get_tree().paused:
		offset = _shake_base_offset + Vector2(0.0, _shake_amplitude.y)
	set_process(true)


## 更新震动；[param delta] 为引擎传入的游戏秒，避免与角色速度重复换算。
func _process(delta: float) -> void:
	if not is_current():
		stop_shake()
		return
	# 重新选卡和失败演出会让相机在暂停时仍能横移，震动需要独立遵循战斗暂停。
	if get_tree().paused:
		return
	_shake_elapsed += delta
	if _shake_elapsed >= _shake_duration:
		stop_shake()
		return
	# 线性衰减至零，使最后一帧平稳回到原相机偏移。
	var decay: float = 1.0 - _shake_elapsed / _shake_duration
	# 纵向振动为主要冲击，横向使用不同频率，避免画面沿固定斜线移动。
	var phase: float = TAU * _shake_frequency * _shake_elapsed
	offset = _shake_base_offset + Vector2(sin(phase * 0.75) * _shake_amplitude.x, cos(phase) * _shake_amplitude.y) * decay


## 停止当前震动并准确恢复起始偏移；未触发震动时不覆盖外部配置。
func stop_shake() -> void:
	if _shake_duration > 0.0:
		offset = _shake_base_offset
	_shake_duration = 0.0
	_shake_elapsed = 0.0
	_shake_amplitude = Vector2.ZERO
	set_process(false)


## 将镜头移动到 [param target_pos] 的全局位置，[param duration] 为移动所需的游戏秒。
## 返回 Tween 完成信号，供调用方等待；不会覆盖落地震动使用的 offset。
func move_to(target_pos: Vector2, duration: float) -> Signal:
	# 本次镜头横移补间，与逐帧震动分别控制不同属性。
	var tween = create_tween()

	tween.tween_property(self, "global_position", target_pos, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	return tween.finished


## 开始游戏查看僵尸
func move_look_zombie():
	return move_to(Vector2(120, 0), 2)

## 返回原点
func move_back_ori():
	return move_to(Vector2(-150, 0), 2)
