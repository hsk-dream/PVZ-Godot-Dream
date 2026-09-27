extends Timer
class_name SpeedTimer
## 支持独立倍率的原生 Timer：用 start_scaled() 启动，用原生 stop()/timeout 管理生命周期。
## base_wait_time 是正常速度下的周期；wait_time/time_left 仍保留原生换算后的时间单位。
## 需要稳定的剩余动作时间时使用 get_base_time_left()，不要再在调用方除以倍率。
## 示例：timer.base_wait_time = 5.0；timer.speed_scale = 0.5；timer.start_scaled()。
## 角色可连接 signal_update_speed 到 set_speed_scale；解除冰冻的计时器不能连接零速信号。
## 不覆盖原生非虚方法 start()，直接 start()/改 wait_time 会绕过基础周期管理。

## 正常倍率下的完整动作周期，单位为秒；由基础周期属性或启动参数更新。
var _base_wait_time: float = 1.0
## 当前独立动作倍率，0 表示冻结；不包含引擎全局时间倍率。
var _speed_scale: float = 1.0
## 原生剩余时间当前所用的正倍率；零速期间保留，恢复时用于还原动作进度。
var _applied_speed_scale: float = 1.0
## 业务主动暂停意图；与零速暂停合成原生 paused，恢复速度时仍保留此意图。
var _manual_paused := false

@export_group("变速计时")
## 正常倍率下的完整周期，单位为秒且必须为有限正数；重置进度需调用 start_scaled()。
@export_range(0.001, 60.0, 0.001, "or_greater") var base_wait_time: float = 1.0:
	get:
		return _base_wait_time
	# value 是调用方写入该属性的新值，需经过下方处理再更新内部状态。
	set(value):
		if not _is_valid_duration(value) or not _is_valid_duration(value / _applied_speed_scale):
			push_error("SpeedTimer：base_wait_time 及换算后的周期必须为有限正数。")
			return
		_base_wait_time = value
		wait_time = value / _applied_speed_scale

## 0 表示冻结进度；全局 Engine.time_scale 已由原生 Timer 处理，不在这里重复计算。
@export_range(0.0, 8.0, 0.05, "or_greater") var speed_scale: float = 1.0:
	get:
		return _speed_scale
	# value 是调用方写入该属性的新值，需经过下方处理再更新内部状态。
	set(value):
		set_speed_scale(value)

## 业务暂停统一使用此属性，使手动暂停和零速互不覆盖。
## 原生 paused 表示最终合成状态；尤其在零速期间，不要直接写原生 paused。
@export var manual_paused: bool = false:
	get:
		return _manual_paused
	# value 是调用方写入该属性的新值，需经过下方处理再更新内部状态。
	set(value):
		_manual_paused = value
		paused = value or _speed_scale == 0.0


## 在原生 READY 自动启动之前设置周期；兼容场景保存的非零速 paused 状态。
func _enter_tree() -> void:
	if _speed_scale > 0:
		_manual_paused = _manual_paused or paused
	wait_time = _base_wait_time / _applied_speed_scale
	paused = _manual_paused or _speed_scale == 0.0


## 启动/重启完整动作周期。-1 使用当前基础周期，正参数同时更新基础周期。
## 保留手动暂停与零速；输入错误或未入树时不改变当前任务。
## [param time_sec] 本次动作时长，单位为正常倍率下的秒；-1 沿用基础周期，其他值需有限且为正。
func start_scaled(time_sec: float = -1.0) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		push_error("SpeedTimer：start_scaled() 必须在有效节点进入场景树后调用。")
		return
	# 本次启动使用的完整动作时长，单位为正常倍率下的秒；参数 -1 时沿用基础周期。
	var duration := _base_wait_time if time_sec == -1.0 else time_sec
	if not _is_valid_duration(duration) or not _is_valid_duration(duration / _applied_speed_scale):
		push_error("SpeedTimer：start_scaled() 的时长及换算结果必须为有限正数，或使用默认参数 -1。")
		return
	# 非零速时也尊重外部对原生 paused 的操作；零速时则保留明确的手动暂停意图。
	if _speed_scale > 0:
		_manual_paused = paused
	_base_wait_time = duration
	wait_time = duration / _applied_speed_scale
	paused = _manual_paused or _speed_scale == 0.0
	super.start()


## 可直接连接角色速度信号；不重置动作进度，也不会启动已停止的计时器。
## 零速用原生 paused 冻结，因此原生 time_left/is_stopped 和 stop() 仍可使用。
## [param value] 新的独立动作倍率，需有限且非负；0 冻结当前进度。
func set_speed_scale(value: float) -> void:
	if not is_finite(value) or value < 0:
		push_error("SpeedTimer：speed_scale 必须为有限非负数。")
		return
	if value == _speed_scale:
		return
	# 用于换算新周期的正倍率；目标为零速时保留旧倍率，避免除零并保存进度。
	var next_applied_speed := value if value > 0 else _applied_speed_scale
	# 新倍率下交给原生 Timer 的完整周期，单位为秒，提交前检查有限且为正。
	var next_period := _base_wait_time / next_applied_speed
	# 修改倍率前是否存在计时任务，用于决定是否换算并恢复剩余进度。
	var running := not is_stopped()
	# 按新倍率换算的原生剩余秒数；没有计时任务时为 0，不启动新任务。
	var next_remaining := get_base_time_left() / next_applied_speed if running else 0.0
	# 除法也可能溢出或下溢；提交修改前验证全部结果，避免留下半更新状态。
	if not _is_valid_duration(next_period) or (running and not _is_valid_duration(next_remaining)):
		push_error("SpeedTimer：该倍率使周期或剩余时间超出有效浮点范围。")
		return
	if _speed_scale > 0:
		_manual_paused = paused
	_speed_scale = value
	_applied_speed_scale = next_applied_speed
	if value > 0 and running:
		# start(剩余量) 同时改写 wait_time，随后必须恢复完整周期，供原生循环下一轮使用。
		super.start(next_remaining)
	wait_time = next_period
	paused = _manual_paused or value == 0.0


## 返回正常速度下的剩余动作时间；零速时仍有效，原生 stop() 后自然返回零。
func get_base_time_left() -> float:
	return time_left * _applied_speed_scale


## 离树时终止旧任务；重新挂载需要显式重新启动，不补发 timeout。
func _exit_tree() -> void:
	stop()


## [param value] 待检查的秒数，只有有限正数才是可用计时时长。
func _is_valid_duration(value: float) -> bool:
	return is_finite(value) and value > 0.0
