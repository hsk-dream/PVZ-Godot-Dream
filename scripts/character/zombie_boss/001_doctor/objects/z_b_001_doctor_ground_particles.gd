extends GPUParticles2D
class_name ZB001DoctorGroundParticles
## 冰火球共用地面轨迹：滚动时持续发射，停止后保留已有粒子，全部消散再释放。

## 是否已经开始过发射；成形阶段被取消时可直接释放空粒子节点。
var _has_started: bool = false
## 是否进入清理阶段，防止球销毁和退出树重复延长残留时间。
var _is_stopping: bool = false
## 清理阶段剩余的粒子模拟秒数，按 speed_scale 消耗，与粒子的实际消散速度一致。
var _remaining_lifetime: float = 0.0


## 初始不发射；关闭脚本帧更新不会关闭 GPU 粒子自身的模拟。
func _ready() -> void:
	emitting = false
	set_process(false)


## 由球进入滚动阶段时调用；已经开始或正在清理时不重启，避免抹掉已有轨迹。
func start_emitting() -> void:
	if _has_started or _is_stopping or is_queued_for_deletion():
		return
	_has_started = true
	emitting = true
	restart()


## 停止产生新碎屑；尚未发射时立即释放，否则等待最后生成的粒子完成其生命周期。
func stop_and_release() -> void:
	if _is_stopping or is_queued_for_deletion():
		return
	_is_stopping = true
	emitting = false
	if not _has_started:
		queue_free()
		return
	# 保留少量模拟余量，避免 GPU 更新与脚本帧顺序不同导致最后一批粒子被提前删除。
	_remaining_lifetime = lifetime + 0.1
	set_process(true)


## 只在停止发射后计时；持续发射模式不使用 finished 信号。[param delta] 为本帧游戏秒数。
func _process(delta: float) -> void:
	# 跟随粒子模拟倍率；倍率为 0 时残留也暂停，场景暂停则按节点默认行为共同暂停。
	_remaining_lifetime -= delta * maxf(speed_scale, 0.0)
	if _remaining_lifetime <= 0.0:
		set_process(false)
		queue_free()
