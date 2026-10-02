extends Node
## 僵尸波次刷新管理器
class_name ZombieWaveRefreshManager
"""
刷新类型分为四种：
	## 不刷新（最后一波）
	正常刷新(刷新时间到后的刷新)
	提前刷新(条件触发)：
		## 残半刷新(普通波或旗帜波)
		## 全死亡刷新(旗前波)
	触发提前刷新时需要当前波次已经开始 time_min_wave(6.0) 秒
"""

## 所属关卡的僵尸管理器，提供自然刷新数量和本关卡战斗阶段。
@onready var zombie_manager: ZombieManager = %ZombieManager

## 正常刷新计时器
@onready var wave_norm_refresh_timer: Timer = $WaveNormRefreshTimer
## 波次最小时间计时器
@onready var wave_min_time_timer: Timer = $WaveMinTimeTimer
## 提醒文字（大波靠近等等）
@onready var ui_remind_word: UIRemindWord = %UIRemindWord

## 提前刷新类型
enum E_RefreshType{
	Null,			## 不刷新（最后一波）
	HalfRefresh,	## 残半刷新(普通波或旗帜波)
	TotalRefresh,	## 全死亡刷新(旗前波)
}
## 刷新状态
enum E_RefreshStatus{
	DisableRefresh,	## 不能刷新
	AwaitRefresh,	## 等待触发刷新
	CompleteRefresh,## 完成刷新
}

## 残半刷新的血量流失比例范围
@export var refresh_threshold_range := Vector2(0.5, 0.67)
## 残半刷新的下一波正常刷新的时间范围
@export var norm_refresh_time_range_in_half_refresh :=  Vector2(25.0, 31.0)
## 全部死亡刷新的下一波正常刷新的时间范围
@export var norm_refresh_time_range_in_total_refresh :=  Vector2(40, 46)
## 波次最小时间
@export var time_min_wave := 6.0

## 当前刷新状态
var curr_refresh_status:=E_RefreshStatus.DisableRefresh
## 当前可以的刷新类型,不可以选Norm正常刷新
var curr_can_refresh_type = E_RefreshType.Null
## 波次总血量
var wave_total_health := 0
## 当前总血量
var wave_current_health := 0
## 波次触发激活刷新的血量流失
var refresh_health :int
## 当前波次类型，决定下次刷新类型
var curr_wave_type := ZombieWaveManager.E_WaveType.Norm
## 当前波次,判断残半刷新时僵尸所属波次
var curr_wave := -1

## 刷新下一波信号（当前波结束时调用）
@warning_ignore("unused_signal")
signal signal_refresh
## 当前波自然刷新时间（更新完当前波后触发,给波次管理器当前波自然刷新时间）
signal signal_norm_time(time:float)
## 开始等待刷新，当前波次时间已达最小值，可以触发下次提前刷新
signal signal_start_await_refresh

func _ready() -> void:
	wave_min_time_timer.wait_time = time_min_wave


## 停止自然刷新和最短波间隔计时，并关闭提前刷新；已排队的回调仍检查战斗阶段。
func stop_refresh() -> void:
	wave_norm_refresh_timer.stop()
	wave_min_time_timer.stop()
	curr_can_refresh_type = E_RefreshType.Null
	curr_refresh_status = E_RefreshStatus.DisableRefresh


## 每次刷新僵尸后获取当前波次生成僵尸血量值
func update_wave_health_data(curr_wave_total_health:int, new_curr_wave_type:ZombieWaveManager.E_WaveType, new_curr_wave:int):
	self.curr_wave_type = new_curr_wave_type
	self.curr_wave = new_curr_wave
	curr_refresh_status = E_RefreshStatus.DisableRefresh

	match self.curr_wave_type:
		## 普通波或旗帜波会触发残半刷新，更新当前残半刷新数据
		ZombieWaveManager.E_WaveType.Norm, ZombieWaveManager.E_WaveType.Flag:
			curr_can_refresh_type = E_RefreshType.HalfRefresh
			self.wave_total_health = curr_wave_total_health
			self.wave_current_health = self.wave_total_health
			## 残半刷新血量倍率
			var refresh_threshold = randf_range(refresh_threshold_range.x, refresh_threshold_range.y)
			refresh_health = int(refresh_threshold * self.wave_total_health)
			## 旗前波 僵尸全部死亡触发提前刷新
		ZombieWaveManager.E_WaveType.FlagFront:
			curr_can_refresh_type = E_RefreshType.TotalRefresh
			print("旗前波")
		## 最后一波，不刷新
		ZombieWaveManager.E_WaveType.Final:
			curr_can_refresh_type = E_RefreshType.Null
			print("最后一波")
	_update_timer()

## 更新计时器
func _update_timer():
	var wave_norm_refresh_time := 0.0
	match curr_can_refresh_type:
		E_RefreshType.HalfRefresh:
			wave_norm_refresh_time = randf_range(norm_refresh_time_range_in_half_refresh.x, norm_refresh_time_range_in_half_refresh.y)

		E_RefreshType.TotalRefresh:
			wave_norm_refresh_time = randf_range(norm_refresh_time_range_in_total_refresh.x, norm_refresh_time_range_in_total_refresh.y)

	## 不可以刷新
	if curr_can_refresh_type == E_RefreshType.Null:
		wave_min_time_timer.stop()
		wave_norm_refresh_timer.stop()
	else:
		wave_min_time_timer.start()
		wave_norm_refresh_timer.start(wave_norm_refresh_time)
		signal_norm_time.emit(wave_norm_refresh_time)

## 判断残半刷新
func judge_half_refresh(all_loss_hp:int, wave:int):
	## 可以残半刷新时，更新当前波次僵尸血量，僵尸掉血信号连接触发
	if wave == curr_wave and curr_can_refresh_type == E_RefreshType.HalfRefresh:
		wave_current_health -= all_loss_hp

		if wave_current_health <= refresh_health or zombie_manager.natural_refresh_zombie_count <= 0:
			_trigger_refresh()

## [param zombie_num] 为自然刷新参与数量，博士及其召唤物不阻塞旗前波的清空刷新。
func judge_total_refresh(zombie_num: int) -> void:
	if curr_can_refresh_type == E_RefreshType.TotalRefresh and zombie_num <= 0:
		_trigger_refresh()

## 等待最短波间隔后触发提前刷新；关卡结束或本波不再允许刷新时不新增等待。
func _trigger_refresh():
	if not zombie_manager.is_game_running() or curr_can_refresh_type == E_RefreshType.Null:
		return
	if curr_refresh_status == E_RefreshStatus.AwaitRefresh:
		refresh_once()
	else:
		# 多个掉血回调可能同时等待；恢复后只允许尚未消费的刷新状态继续。
		await signal_start_await_refresh
		# 如果还没触发刷新
		if curr_refresh_status == E_RefreshStatus.AwaitRefresh:
			refresh_once()

## 波次最小时间到达后允许提前刷新；结束战斗后不重新激活刷新状态。
func _on_wave_min_time_timer_timeout() -> void:
	if not zombie_manager.is_game_running() or curr_can_refresh_type == E_RefreshType.Null:
		return
	curr_refresh_status = E_RefreshStatus.AwaitRefresh
	signal_start_await_refresh.emit()
	# 选行失败可能产生空波；达到最短等待后重新检查，避免依赖一次不存在的死亡信号。
	if curr_refresh_status != E_RefreshStatus.AwaitRefresh:
		return
	if curr_can_refresh_type == E_RefreshType.TotalRefresh:
		judge_total_refresh(zombie_manager.natural_refresh_zombie_count)
	elif curr_can_refresh_type == E_RefreshType.HalfRefresh:
		if wave_current_health <= refresh_health or zombie_manager.natural_refresh_zombie_count <= 0:
			_trigger_refresh()

## 正常计时到达后请求下一波；关卡已结束时忽略回调。
func _on_wave_norm_refresh_timer_timeout() -> void:
	if curr_refresh_status == E_RefreshStatus.AwaitRefresh:
		refresh_once()

## 消费本波刷新机会并延迟发出下一波信号；结束战斗后不再排队刷新请求。
func refresh_once():
	if not zombie_manager.is_game_running():
		return
	curr_refresh_status = E_RefreshStatus.CompleteRefresh
	curr_can_refresh_type = E_RefreshType.Null
	# 物理查询刷新期间不能改变状态，空闲后由下一波入口再次确认战斗阶段。
	call_deferred(&"emit_signal", "signal_refresh")
