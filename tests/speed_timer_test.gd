extends Node
## 验证真实 Timer 子类的剩余进度、循环与暂停，不用替身模拟 timeout。
## Godot --headless --path . res://tests/speed_timer_test.tscn --fixed-fps 60

const SCRIPT_PATH := "res://scripts/util/speed_timer.gd"
var timer_script: Script
var checks := 0
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", description)


func _timer() -> Timer:
	var timer := timer_script.new() as Timer
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	return timer


func _run() -> void:
	# 首次红灯只报告组件缺失，不制造脚本解析错误。
	_check(ResourceLoader.exists(SCRIPT_PATH), "提供继承原生 Timer 的 SpeedTimer")
	if ResourceLoader.exists(SCRIPT_PATH):
		timer_script = load(SCRIPT_PATH)
		_test_conversion()
		await _test_zero_and_pause()
		await _test_cycles()
		await _test_callback_operations()
		await _test_global_scale_and_tree_pause()
		await _test_native_options()
		await _test_autostart_and_exit()
		_test_scene_roundtrip()
		_test_invalid_values()
	print("SPEED_TIMER_TESTS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)


## 原生 time_left 是换算后的时间；get_base_time_left 始终返回正常速度下的剩余量。
func _test_conversion() -> void:
	var timer := _timer()
	_check(timer.is_stopped(), "新组件不会自行启动")
	timer.call("start_scaled", 10.0)
	_check(is_equal_approx(timer.time_left, 10), "正常速度启动十秒")
	for speed: float in [0.5, 2.0, 2.0, 0.25, 1.0]:
		timer.set("speed_scale", speed)
		_check(is_equal_approx(timer.time_left, 10 / speed), "变速保留进度 " + str(speed))
		_check(is_equal_approx(float(timer.call("get_base_time_left")), 10), "动作时间不随设置倍率变化")
	timer.set("base_wait_time", 20.0)
	_check(is_equal_approx(timer.time_left, 10), "修改基础周期不重置当前剩余量")
	_check(is_equal_approx(timer.wait_time, 20), "修改基础周期影响下次循环")
	timer.call("start_scaled")
	_check(is_equal_approx(timer.time_left, 20), "无参数启动使用基础周期")
	timer.stop()
	timer.set("speed_scale", 3.0)
	_check(timer.is_stopped() and is_zero_approx(float(timer.call("get_base_time_left"))), "停止后变速不重启")
	timer.free()


## 等待真实物理帧，确保零速和手动暂停均不扣时间，且可独立解除。
func _test_zero_and_pause() -> void:
	var timer := _timer()
	timer.call("start_scaled", 10.0)
	await get_tree().create_timer(0.2).timeout
	var before := float(timer.call("get_base_time_left"))
	_check(before < 10 and before > 9, "真实 Timer 正常扣减时间")
	timer.set("speed_scale", 0.0)
	_check(not timer.is_stopped() and timer.paused, "零速是暂停，仍保留原生运行状态")
	await get_tree().create_timer(0.1).timeout
	_check(is_equal_approx(float(timer.call("get_base_time_left")), before), "零速不消耗剩余进度")
	timer.set("manual_paused", true)
	timer.set("speed_scale", 2.0)
	_check(timer.paused and is_equal_approx(timer.time_left, before / 2), "恢复倍率后仍保留手动暂停")
	timer.set("manual_paused", false)
	_check(not timer.paused, "两种暂停都解除后恢复")
	# 再次设置零速并重启，不能丢失新周期或自动解除暂停。
	timer.set("speed_scale", 0.0)
	timer.call("start_scaled", 5.0)
	_check(timer.paused and is_equal_approx(float(timer.call("get_base_time_left")), 5), "零速启动保存完整动作时长")
	timer.set("manual_paused", true)
	timer.set("manual_paused", false)
	_check(timer.paused, "解除手动暂停不会解除零速暂停")
	timer.stop()
	timer.set("speed_scale", 1.0)
	_check(timer.is_stopped(), "零速下原生 stop 后恢复倍率不复活计时")
	# 非零倍率时直接使用原生 paused，变速同样不能取消已有暂停。
	timer.call("start_scaled", 4.0)
	timer.paused = true
	timer.set("speed_scale", 0.0)
	timer.set("speed_scale", 1.0)
	_check(timer.paused, "进入零速前的原生暂停被保留")
	timer.free()


## 变速发生在周期中途，后续循环必须使用完整周期，不能循环这段剩余量。
func _test_cycles() -> void:
	var timer := _timer()
	var moments: Array[int] = []
	timer.timeout.connect(func(): moments.append(Engine.get_physics_frames()))
	timer.call("start_scaled", 0.4)
	await get_tree().create_timer(0.15).timeout
	var remaining := float(timer.call("get_base_time_left"))
	timer.set("speed_scale", 2.0)
	_check(is_equal_approx(timer.time_left, remaining / 2), "中途加速只换算剩余部分")
	_check(is_equal_approx(timer.wait_time, 0.2), "变速后恢复完整循环周期")
	await get_tree().create_timer(0.75).timeout
	_check(moments.size() >= 3, "原生循环持续触发")
	if moments.size() >= 3:
		_check(abs(moments[2] - moments[1] - 12) <= 1, "第二轮以后仍按完整周期触发")
	timer.free()
	# 回调内重启、改速、停止；封装不能在信号返回后覆盖调用方的新状态。
	timer = _timer()
	timer.one_shot = true
	var count := [0]
	timer.timeout.connect(func():
		count[0] += 1
		if count[0] == 1:
			timer.set("speed_scale", 2.0)
			timer.call("start_scaled", 0.2)
		else:
			timer.stop()
	)
	timer.call("start_scaled", 0.1)
	await get_tree().create_timer(0.5).timeout
	_check(count[0] == 2 and timer.is_stopped(), "单次回调内重启与停止有效")
	timer.free()


## 原生 Timer 负责全局倍速和场景树暂停；组件不能再重复乘全局倍率。
func _test_global_scale_and_tree_pause() -> void:
	var timer := _timer()
	timer.call("start_scaled", 10.0)
	timer.set("speed_scale", 2.0)
	var before := float(timer.call("get_base_time_left"))
	var old_scale := Engine.time_scale
	Engine.time_scale = 2.0
	for frame in 12:
		await get_tree().physics_frame
	var consumed := before - float(timer.call("get_base_time_left"))
	Engine.time_scale = old_scale
	_check(abs(consumed - 0.8) < 0.15, "全局双速和独立双速只叠乘一次")
	before = float(timer.call("get_base_time_left"))
	get_tree().paused = true
	await get_tree().create_timer(0.1, true).timeout
	_check(is_equal_approx(before, float(timer.call("get_base_time_left"))), "默认继承场景树暂停")
	get_tree().paused = false
	timer.free()


## 循环回调内变速/暂停/停止及释放不能被封装随后覆盖，也不能多发一次超时。
func _test_callback_operations() -> void:
	var timer := _timer()
	var count := [0]
	timer.timeout.connect(func():
		count[0] += 1
		if count[0] == 1:
			timer.set("speed_scale", 0.0)
		else:
			timer.stop()
	)
	timer.call("start_scaled", 0.1)
	await get_tree().create_timer(0.4).timeout
	_check(count[0] == 1 and timer.paused, "循环超时回调内冻结后不再触发")
	timer.set("speed_scale", 2.0)
	await get_tree().create_timer(0.3).timeout
	_check(count[0] == 2 and timer.is_stopped(), "循环回调内 stop 不被自动重启")
	timer.free()
	timer = _timer()
	timer.timeout.connect(timer.queue_free)
	timer.call("start_scaled", 0.1)
	await get_tree().create_timer(0.3).timeout
	_check(not is_instance_valid(timer), "超时回调可释放节点")
	timer = _timer()
	timer.set("manual_paused", true)
	timer.call("start_scaled", 0.1)
	await get_tree().create_timer(0.2).timeout
	_check(is_equal_approx(timer.time_left, 0.1) and timer.paused, "重启不解除明确的手动暂停")
	timer.free()


## 场景持久化不能把“零速造成的原生 paused”误存为手动暂停；使用内存打包避免生成临时文件。
func _test_scene_roundtrip() -> void:
	for frozen in [false, true]:
		var timer := _timer()
		timer.set("base_wait_time", 4.0)
		timer.set("speed_scale", 0.0 if frozen else 2.0)
		timer.autostart = true
		var packed := PackedScene.new()
		_check(packed.pack(timer) == OK, "变速 Timer 可以作为场景保存")
		var restored := packed.instantiate() as Timer
		add_child(restored)
		_check(is_equal_approx(float(restored.call("get_base_time_left")), 4), "保存的自动启动周期不重复除以倍率")
		restored.set("speed_scale", 1.0)
		_check(not restored.paused, "场景恢复后解除零速不残留手动暂停")
		timer.free()
		restored.free()


## 原生选项由 Timer 自身执行：忽略全局倍率、普通帧更新和短周期均不额外调度。
func _test_native_options() -> void:
	var scaled := _timer()
	var unscaled := _timer()
	unscaled.ignore_time_scale = true
	scaled.call("start_scaled", 10.0)
	unscaled.call("start_scaled", 10.0)
	scaled.set("speed_scale", 2.0)
	unscaled.set("speed_scale", 2.0)
	var original_scale := Engine.time_scale
	Engine.time_scale = 2.0
	for frame in 12:
		await get_tree().physics_frame
	Engine.time_scale = original_scale
	var scaled_consumed := 10.0 - float(scaled.call("get_base_time_left"))
	var unscaled_consumed := 10.0 - float(unscaled.call("get_base_time_left"))
	_check(abs(scaled_consumed - unscaled_consumed * 2) < 0.15, "ignore_time_scale 忽略全局倍率但保留独立倍率")
	scaled.free()
	unscaled.free()
	var timer := _timer()
	timer.process_callback = Timer.TIMER_PROCESS_IDLE
	timer.one_shot = true
	var count := [0]
	timer.timeout.connect(func(): count[0] += 1)
	timer.call("start_scaled", 0.1)
	timer.set("speed_scale", 2.0)
	await get_tree().create_timer(0.3).timeout
	_check(count[0] == 1 and timer.is_stopped(), "普通帧单次计时不重复触发")
	timer.free()
	# 小于帧长时沿用原生每帧最多触发一次的精度，验证封装仍能在回调内冻结。
	timer = _timer()
	var short_count := [0]
	timer.timeout.connect(func():
		short_count[0] += 1
		timer.set("speed_scale", 0.0)
	)
	timer.call("start_scaled", 0.001)
	await get_tree().create_timer(0.1).timeout
	_check(short_count[0] == 1 and timer.paused, "短周期循环也可在超时回调内冻结")
	timer.set("speed_scale", 2.0)
	await get_tree().create_timer(0.1).timeout
	_check(short_count[0] == 2 and timer.paused, "短周期恢复倍率后仍可再次冻结")
	timer.free()


## 自动启动沿用原生属性，退出场景树终止旧任务，重新入树不能继续旧计时。
func _test_autostart_and_exit() -> void:
	var timer := timer_script.new() as Timer
	timer.set("base_wait_time", 10.0)
	timer.set("speed_scale", 2.0)
	timer.autostart = true
	add_child(timer)
	_check(not timer.is_stopped() and is_equal_approx(timer.time_left, 5), "原生自动启动使用换算周期")
	remove_child(timer)
	_check(timer.is_stopped(), "离树停止旧任务")
	add_child(timer)
	_check(timer.is_stopped(), "重新入树不复活旧计时")
	timer.free()
	timer = timer_script.new() as Timer
	timer.set("base_wait_time", 3.0)
	timer.set("speed_scale", 0.0)
	timer.autostart = true
	add_child(timer)
	await get_tree().process_frame
	_check(timer.paused and not timer.is_stopped(), "零速自动启动仍保存任务")
	_check(is_equal_approx(float(timer.call("get_base_time_left")), 3), "零速自动启动保存基础时间")
	timer.free()


func _test_invalid_values() -> void:
	var timer := _timer()
	timer.call("start_scaled", 5.0)
	print("EXPECTED_SPEED_TIMER_ERRORS_BEGIN")
	for value: float in [-1.0, NAN, INF]:
		timer.set("speed_scale", value)
		_check(is_equal_approx(float(timer.get("speed_scale")), 1), "拒绝无效倍率")
	for value: float in [0.0, -2.0, NAN, INF]:
		timer.set("base_wait_time", value)
		_check(is_equal_approx(float(timer.get("base_wait_time")), 5), "拒绝无效基础周期")
		timer.call("start_scaled", value)
		_check(is_equal_approx(timer.time_left, 5), "无效启动不破坏正在运行的任务")
	# 倍率本身有限也可能导致换算溢出，拒绝时不能留下部分更新的属性。
	# 使用正常范围内可解析的浮点数，避免极小字面量本身已被解析器舍入成合法零速。
	timer.call("start_scaled", 1e10)
	timer.set("speed_scale", 1e-300)
	_check(is_equal_approx(float(timer.get("speed_scale")), 1) and is_equal_approx(timer.time_left, 1e10), "拒绝换算溢出并保留原状态")
	var outside := timer_script.new() as Timer
	outside.call("start_scaled", 3.0)
	_check(outside.is_stopped() and is_equal_approx(float(outside.get("base_wait_time")), 1), "未入树启动被拒绝且不修改配置")
	outside.free()
	print("EXPECTED_SPEED_TIMER_ERRORS_END")
	timer.free()
