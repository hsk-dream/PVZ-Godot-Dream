extends Node
class_name ZB001DoctorAnimationController
## 博士专用动画控制器：管理实例动画副本、姿势过渡和机甲／驾驶员联动。
## 状态机保留技能选择与方法轨道入口，本节点不执行技能或决定死亡状态切换。

## 本体单次动作结束时发出；主状态机只在死亡期间将其交给 Dying。
signal driver_animation_finished(animation_name: StringName)

## 博士自身的独立本体播放器，不接入机甲动画结束事件的分发链。
@export var driver_animation_player: AnimationPlayer
@export_group("动画过渡")
## 普通待机或放置间隔切入技能的姿势过渡时间，单位为动作秒；0 表示立即切换。
@export_range(0.0, 0.5, 0.01) var idle_transition_duration: float = 0.15
## 低头待机切入吐球或抬头的姿势过渡时间，单位为动作秒；不延后技能关键帧。
@export_range(0.0, 0.5, 0.01) var head_transition_duration: float = 0.15
## 死亡打断技能时的姿势及手臂偏移收回时间，单位为动作秒；随死亡动画倍率加速。
@export_range(0.0, 0.5, 0.01) var death_transition_duration: float = 0.2
## 本体开始或重播操纵、吐球动作，以及中断动作返回待机的过渡时间，单位为动作秒。
@export_range(0.0, 0.5, 0.01) var driver_transition_duration: float = 0.1
## 本体举旗末帧进入举旗循环的过渡时间，单位为动作秒；计时仍从进入循环时开始。
@export_range(0.0, 0.5, 0.01) var flag_transition_duration: float = 0.12
@export_group("")


## 显式指定机甲动作需要的本体反应；控制器不读取任何技能状态。
enum DriverReaction {
	## 保留当前本体动画，死亡动作使用此选项。
	KEEP,
	## 机甲普通动作对应操纵一次，结束后返回待机。
	DRIVE,
	## 吐球动作对应本体 damage 一次，结束后返回待机。
	DAMAGE,
}

## 主状态机是否已开始；停止时不处理迟到的本体完成事件。
var _active: bool = false
## 本次本体单次动作结束后是否自动返回待机；死亡请求立即取消此行为。
var _return_driver_to_idle: bool = false
## 正在执行的技能偏移复位快照，节点由实例 ID 解析。
var _visual_returns: Array[ZB001DoctorVisualReturn] = []
## 本次复位已消耗的动作秒数，避免重复乘以角色动画倍率。
var _visual_return_elapsed: float = 0.0
## 初始化时绑定的主体播放器；速度仍由原动画组件控制。
var _mech_player: AnimationPlayer
## 实际连接过的本体播放器，导出引用被替换后仍能断开原有连接。
var _connected_driver_player: AnimationPlayer


## 配置通过后绑定 [param player] 主体播放器，复制实例动画并启动本体默认待机。
## 重复初始化会先断开旧信号，避免单个动画触发多次联动。
func initialize(player: AnimationPlayer) -> void:
	disconnect_players()
	_mech_player = player
	_prepare_capture_animations(_mech_player)
	_prepare_capture_animations(driver_animation_player)
	_connected_driver_player = driver_animation_player
	_connected_driver_player.animation_finished.connect(_on_driver_animation_finished)
	sync_driver_speed()
	driver_animation_player.play(ZB001DoctorAnimations.DRIVER_IDLE_ANIMATION)


## 为 [param player] 创建独立动画库，仅将姿势数值轨道改为捕获模式。
## 显隐、贴图和方法轨道保留原配置；显式关闭自动捕获，避免完整收尾也产生额外过渡。
func _prepare_capture_animations(player: AnimationPlayer) -> void:
	player.playback_auto_capture = false
	# 当前播放器注册的动画库名称；保留名称以维持状态和方法轨道中的动画标识。
	for library_name: StringName in player.get_animation_library_list():
		# 原动画库只用于读取，替换前先完整构建当前实例的副本。
		var source_library: AnimationLibrary = player.get_animation_library(library_name)
		# 当前实例专用的库，动画贴图仍共享，不复制纹理数据。
		var capture_library := AnimationLibrary.new()
		# 当前库中的动画名称；包括正常动作和死亡动作。
		for animation_name: StringName in source_library.get_animation_list():
			# 复制动画的轨道数据，后续设置不会写回外部 .tres 文件。
			var animation: Animation = source_library.get_animation(animation_name).duplicate() as Animation
			# 当前轨道下标，只捕获位置、旋转、缩放和斜切等连续姿势属性。
			for track: int in animation.get_track_count():
				if animation.track_get_type(track) != Animation.TYPE_VALUE:
					continue
				# 属性路径可能包含多个子属性，只接受直接的 Node2D 变换属性。
				var track_path: NodePath = animation.track_get_path(track)
				if track_path.get_subname_count() == 1 and track_path.get_subname(0) in [&"position", &"rotation", &"scale", &"skew"]:
					animation.value_track_set_update_mode(track, Animation.UPDATE_CAPTURE)
			capture_library.add_animation(animation_name, animation)
		player.remove_animation_library(library_name)
		player.add_animation_library(library_name, capture_library)


## 播放 [param animation_name] 指定的机甲动作；[param transition_duration] 为动作秒，负数按来源动画选择。
## [param driver_reaction] 明确指定本体配合动作；仅离开循环待机默认捕获姿势。
func play_mech_action(animation_name: StringName, driver_reaction: DriverReaction, transition_duration: float = -1.0) -> void:
	# 本次过渡时长；死亡可以显式覆盖，不改变新动画自身的播放时间轴。
	var duration: float = transition_duration
	if duration < 0.0:
		duration = 0.0
		if _mech_player.assigned_animation == ZB001DoctorAnimations.IDLE_ANIMATION and animation_name != ZB001DoctorAnimations.IDLE_ANIMATION:
			duration = idle_transition_duration
		elif _mech_player.assigned_animation == ZB001DoctorAnimations.HEAD_IDLE_ANIMATION and animation_name != ZB001DoctorAnimations.HEAD_IDLE_ANIMATION:
			duration = head_transition_duration
	_play_pose_transition(_mech_player, animation_name, duration)
	if _active and driver_reaction != DriverReaction.KEEP:
		sync_driver_speed()
		play_driver_animation(ZB001DoctorAnimations.DRIVER_DAMAGE_ANIMATION if driver_reaction == DriverReaction.DAMAGE else ZB001DoctorAnimations.DRIVER_DRIVE_ANIMATION)


## 播放 [param animation_name] 指定的本体动作；同名动作也从头开始，同时保留切换瞬间的可见姿势。
## 完整操纵、吐球动作结束回待机时不增加过渡；中途打断及举旗进入循环使用专门时长。
func play_driver_animation(animation_name: StringName) -> void:
	# 本次本体过渡时间，单位为动作秒，默认保持已经对齐的首尾姿势。
	var duration: float = 0.0
	if animation_name in [ZB001DoctorAnimations.DRIVER_DRIVE_ANIMATION, ZB001DoctorAnimations.DRIVER_DAMAGE_ANIMATION] \
		or (animation_name == ZB001DoctorAnimations.DRIVER_IDLE_ANIMATION and driver_animation_player.is_playing()):
		duration = driver_transition_duration
	elif animation_name == ZB001DoctorAnimations.DRIVER_FLAG_LOOP_ANIMATION:
		duration = flag_transition_duration
	_return_driver_to_idle = animation_name in [ZB001DoctorAnimations.DRIVER_DRIVE_ANIMATION, ZB001DoctorAnimations.DRIVER_DAMAGE_ANIMATION]
	_play_pose_transition(driver_animation_player, animation_name, duration)


## 从当前节点姿势启动新动画；[param player] 为目标播放器，[param animation_name] 为已校验的动画名。
## [param duration] 为动作秒，非有限值或非正数禁用过渡；捕获时间跟随播放器 speed_scale。
## 不混播旧动画，避免旧技能方法轨道继续触发；新动画的关键帧时刻和完成时间保持原值。
func _play_pose_transition(player: AnimationPlayer, animation_name: StringName, duration: float) -> void:
	# 保留当前显示值再停止，使同名动作可以重播，并让捕获读取当前姿势而非重置后的首帧。
	player.stop(true)
	if is_finite(duration) and duration > 0.0:
		player.play_with_capture(animation_name, duration, 0.0)
	else:
		player.play(animation_name, 0.0)


## [param active] 为主状态机是否运行；停止时取消待机回落，不停止仍需演出的机甲动画。
func set_active(active: bool) -> void:
	_active = active
	if not active:
		cancel_driver_reaction()


## 死亡请求立即禁止旧操纵动作结束后回落待机，死亡序列由显式播放请求接管。
func cancel_driver_reaction() -> void:
	_return_driver_to_idle = false


## [param animation_name] 为本体已结束动作；完成通知与自动回落各有明确责任。
func _on_driver_animation_finished(animation_name: StringName) -> void:
	if not _active or driver_animation_player.assigned_animation != animation_name:
		return
	if _return_driver_to_idle:
		play_driver_animation(ZB001DoctorAnimations.DRIVER_IDLE_ANIMATION)
	driver_animation_finished.emit(animation_name)


## 跟随机甲的角色倍率；蹦极等待暂停机甲时，本体仍可待机，因此不读取机甲实际播放速度。
func sync_driver_speed() -> void:
	if is_instance_valid(_mech_player) and is_instance_valid(driver_animation_player):
		driver_animation_player.speed_scale = _mech_player.speed_scale


## 断开实际绑定的播放器，供重新初始化、配置失败和离树时共同清理。
func disconnect_players() -> void:
	set_active(false)
	finish_visual_returns()
	if is_instance_valid(_connected_driver_player) and _connected_driver_player.animation_finished.is_connected(_on_driver_animation_finished):
		_connected_driver_player.animation_finished.disconnect(_on_driver_animation_finished)
	_mech_player = null
	_connected_driver_player = null


## 离树时解除外部播放器信号，不依赖兄弟节点的销毁顺序。
func _exit_tree() -> void:
	disconnect_players()


## 只读检查 [param actor] 的本体播放器及必需动画；[param mech_player] 用于排除误绑同一播放器。
## 返回空字符串表示有效；错误在检测位置报告，不修改资源与播放状态。
func get_configuration_error(actor: ZB001Doctor, mech_player: AnimationPlayer) -> String:
	# 当前分支的配置错误文本，供主状态机中止初始化。
	var detected_error: String = ""
	if not is_instance_valid(mech_player) or mech_player != actor.get_node_or_null("AnimationPlayer"):
		detected_error = "主体播放器必须绑定博士根节点的 AnimationPlayer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(driver_animation_player) or not actor.is_ancestor_of(driver_animation_player) \
		or driver_animation_player == mech_player:
		detected_error = "必须绑定博士自身独立的驾驶员 AnimationPlayer。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 驾驶员必需的动作名称；idle 和最终举旗允许循环，其他动作必须产生一次结束通知。
	for animation_name: StringName in [ZB001DoctorAnimations.DRIVER_IDLE_ANIMATION, ZB001DoctorAnimations.DRIVER_DRIVE_ANIMATION, ZB001DoctorAnimations.DRIVER_DAMAGE_ANIMATION, ZB001DoctorAnimations.DRIVER_DEATH_ANIMATION, ZB001DoctorAnimations.DRIVER_FLAG_ANIMATION, ZB001DoctorAnimations.DRIVER_FLAG_LOOP_ANIMATION]:
		if not driver_animation_player.has_animation(animation_name):
			detected_error = "驾驶员播放器缺少动画：%s。" % animation_name
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		# 各动作应使用的循环模式；动作结束回到待机由信号回调处理。
		var expected_loop: int = Animation.LOOP_LINEAR if animation_name in [ZB001DoctorAnimations.DRIVER_IDLE_ANIMATION, ZB001DoctorAnimations.DRIVER_FLAG_LOOP_ANIMATION] else Animation.LOOP_NONE
		if driver_animation_player.get_animation(animation_name).loop_mode != expected_loop:
			detected_error = "驾驶员 idle、flag_loop 必须循环，drive、damage、death 和 flag 必须单次播放：%s。" % animation_name
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	# 基础机甲动作的循环规则；技能变体由各技能配置提供。
	var mech_modes: Dictionary[StringName, int] = {
		ZB001DoctorAnimations.ENTER_ANIMATION: Animation.LOOP_NONE,
		ZB001DoctorAnimations.IDLE_ANIMATION: Animation.LOOP_LINEAR,
		ZB001DoctorAnimations.HEAD_ENTER_ANIMATION: Animation.LOOP_NONE,
		ZB001DoctorAnimations.HEAD_IDLE_ANIMATION: Animation.LOOP_LINEAR,
		ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION: Animation.LOOP_NONE,
		ZB001DoctorAnimations.DEATH_ANIMATION: Animation.LOOP_NONE,
	}
	# 每个基础动画只检查存在性与循环模式，方法事件由对应状态检查。
	for animation_name: StringName in mech_modes:
		detected_error = get_animation_error(mech_player, animation_name, mech_modes[animation_name])
		if not detected_error.is_empty():
			return detected_error
	return ""


## [param snapshots] 为技能取消前取得的复位信息；取消已清理逻辑，这里恢复起点并开始视觉过渡。
func begin_visual_returns(snapshots: Array[ZB001DoctorVisualReturn]) -> void:
	finish_visual_returns()
	_visual_returns.assign(snapshots)
	_visual_return_elapsed = 0.0
	# 每个快照独立恢复，支持未来一个技能同时移动多个部件。
	for snapshot: ZB001DoctorVisualReturn in _visual_returns:
		# 先按实例 ID 查询，节点提前释放时不再写入。
		var node: Node2D = instance_from_id(snapshot.node_id) as Node2D
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.position = snapshot.start_position
	advance_visual_returns(0.0)


## [param action_delta] 已换算的动作秒；此处不再次乘角色速度。
func advance_visual_returns(action_delta: float) -> void:
	if _visual_returns.is_empty():
		return
	if not is_finite(death_transition_duration) or death_transition_duration <= 0.0:
		finish_visual_returns()
		return
	_visual_return_elapsed += maxf(action_delta, 0.0)
	# 与动画姿势捕获同步的线性复位进度。
	var progress: float = clampf(_visual_return_elapsed / death_transition_duration, 0.0, 1.0)
	# 当前需要复位的部件，不依赖它由哪一种技能移动。
	for snapshot: ZB001DoctorVisualReturn in _visual_returns:
		# 无效节点跳过，不影响其他部件继续复位。
		var node: Node2D = instance_from_id(snapshot.node_id) as Node2D
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.position = snapshot.start_position.lerp(snapshot.target_position, progress)
	if progress >= 1.0:
		_visual_returns.clear()


## 过渡结束或控制器卸载时准确恢复目标位置，重复调用安全。
func finish_visual_returns() -> void:
	# 快照中的每个部件都按技能定义的目标位置收尾。
	for snapshot: ZB001DoctorVisualReturn in _visual_returns:
		# 只恢复尚存活的节点，不持有旧场景节点引用。
		var node: Node2D = instance_from_id(snapshot.node_id) as Node2D
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.position = snapshot.target_position
	_visual_returns.clear()
	_visual_return_elapsed = 0.0


## 只读检查 [param player] 中的 [param animation_name] 是否存在且使用 [param expected_loop] 循环模式。
## 配置阶段也可调用，不依赖运行时播放器初始化；错误在此检查位置报告。
func get_animation_error(player: AnimationPlayer, animation_name: StringName, expected_loop: int) -> String:
	if not is_instance_valid(player) or animation_name.is_empty() or not player.has_animation(animation_name):
		push_error("%s：缺少动画 %s。" % [get_path(), animation_name])
		return "动画不存在：%s。" % animation_name
	if player.get_animation(animation_name).loop_mode != expected_loop:
		push_error("%s：动画 %s 循环模式应为 %s。" % [get_path(), animation_name, expected_loop])
		return "动画循环模式错误：%s。" % animation_name
	return ""
