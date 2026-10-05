## 用僵王已损失的血量表示击败进度：满血为 0%，死亡为 100%；显示切换由 LevelInfo 负责。
extends Control
class_name BossHpProgressBar

## 每次血量变化的过渡秒数；0 表示立即更新，首次绑定及死亡始终立即更新。
@export_range(0.0, 1.0, 0.01) var hp_transition_duration: float = 0.2
## 进度为空（僵王满血）时头像的横坐标，单位为本地像素，对应进度条右端。
@export var empty_icon_x: float = 142.0
## 进度填满（僵王死亡）时头像的横坐标，单位为本地像素，对应进度条左端。
@export var full_icon_x: float = -4.0

## 使用原进度条贴图的填充控件，范围固定为 0 到 100。
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
## 跟随填充边界移动的头像，后续可以在独立场景中替换贴图。
@onready var boss_icon: TextureRect = $BossIcon
## 复用场景预留的名称标签显示存活数量，不额外占用关卡 UI 空间。
@onready var living_boss_count_label: Label = $BossNameLabel

## 当前绑定的血量组件；解绑时清空，避免场景卸载后访问旧对象。
var _hp_component: HpComponent
## 最近一次同步的血量；用于识别读档直接赋值，不打断正常掉血信号创建的过渡。
var _last_hp: int = -1
## 当前已经显示的击败进度，范围为 0 到 1，用于连续受伤时接续过渡。
var _display_ratio: float = 0.0
## 当前血量过渡；下一次扣血、解绑或死亡时终止，防止旧过渡覆盖新值。
var _hp_tween: Tween


## 初始化为 0% 进度；绑定角色时根据真实血量立即计算击败进度。
func _ready() -> void:
	_apply_ratio(0.0)
	set_living_boss_count(0)


## [param boss] 已进入场景树并完成初始化的僵王；绑定成功返回 true。
## 无效角色或非正数最大血量返回 false；重复绑定同一实例不会重置血量过渡。
func bind_boss(boss: ZB000Base) -> bool:
	if not is_instance_valid(boss) or not boss.is_node_ready() or boss.is_queued_for_deletion():
		return false
	if not is_instance_valid(boss.hp_component) or boss.hp_component.max_hp <= 0:
		return false
	if _hp_component == boss.hp_component:
		# 读档写入 curr_hp 不发掉血信号；仅在真实血量未同步时立即修正显示。
		if _last_hp != _hp_component.curr_hp:
			_stop_hp_tween()
			_last_hp = _hp_component.curr_hp
			_apply_ratio(1.0 - float(_last_hp) / _hp_component.max_hp)
		return true
	unbind_boss()
	_hp_component = boss.hp_component
	_last_hp = _hp_component.curr_hp
	_hp_component.signal_hp_loss.connect(_on_boss_hp_loss)
	_apply_ratio(1.0 - float(_hp_component.curr_hp) / _hp_component.max_hp)
	return true


## [param count] 为当前存活僵王数量；负值按 0 显示，血条始终只绑定一只僵王。
func set_living_boss_count(count: int) -> void:
	living_boss_count_label.text = "僵王 × %d" % maxi(count, 0)
	living_boss_count_label.show()


## 解除血量信号并停止过渡，保留当前显示值；显示或隐藏由 LevelInfo 决定。
func unbind_boss() -> void:
	_stop_hp_tween()
	if is_instance_valid(_hp_component) and _hp_component.signal_hp_loss.is_connected(_on_boss_hp_loss):
		_hp_component.signal_hp_loss.disconnect(_on_boss_hp_loss)
	_hp_component = null
	_last_hp = -1


## 死亡信号先于最后一次扣血通知发出；先解绑并立即填满进度，避免随后启动新的过渡。
func show_depleted() -> void:
	unbind_boss()
	_apply_ratio(1.0)


## [param curr_hp] 扣血后的剩余血量；[param _is_drop] 肢体掉落开关，不影响血条显示。
func _on_boss_hp_loss(curr_hp: int, _is_drop: bool) -> void:
	if not is_instance_valid(_hp_component):
		return
	_last_hp = curr_hp
	# 已损失血量占比作为目标进度；分母至少为 1，避免非法运行时修改造成除零。
	var target_ratio: float = clampf(1.0 - float(curr_hp) / maxi(_hp_component.max_hp, 1), 0.0, 1.0)
	_stop_hp_tween()
	if curr_hp <= 0 or hp_transition_duration <= 0.0:
		_apply_ratio(target_ratio)
		return
	# 节点绑定的 Tween 跟随场景暂停；只平滑显示值，不影响真实血量和死亡时机。
	_hp_tween = create_tween()
	_hp_tween.tween_method(_apply_ratio, _display_ratio, target_ratio, hp_transition_duration)


## [param ratio] 已损失血量对应的击败进度；限制到 0 到 1 后同步填充条与头像位置。
func _apply_ratio(ratio: float) -> void:
	_display_ratio = clampf(ratio, 0.0, 1.0)
	texture_progress_bar.value = _display_ratio * 100.0
	boss_icon.position.x = lerpf(empty_icon_x, full_icon_x, _display_ratio)


## 终止当前显示过渡，保留已绘制的比例供下一次过渡接续。
func _stop_hp_tween() -> void:
	if is_instance_valid(_hp_tween):
		_hp_tween.kill()
	_hp_tween = null


## UI 先于角色卸载时也主动解绑，避免退出场景期间仍接收扣血通知。
func _exit_tree() -> void:
	unbind_boss()
