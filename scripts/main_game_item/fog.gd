## 管理浓雾进出战场及三叶草等待；重新选卡时只允许轮次退场继续移动。
extends Node2D
class_name Fog
## 目前动态雾只接受8个驱散雾的area2d,如果要增加，需要更改fog的着色器脚本
## 是否为静态雾（原版雾）,使用Global.fog_is_static
#@export var is_static_fog := true
## 清除雾的Area2d
var fog_clearers:Array[Area2D] = []
## 尚未结束的三叶草保护阶段；等待结束后的回场不再属于保护期。
enum E_BloverPhase {
	## 没有尚未结束的三叶草保护期。
	NONE,
	## 正在吹散，完整等待尚未开始。
	BLOWING,
	## 已在场外等待，可在重新选卡时冻结剩余时间。
	WAITING,
}

## 三叶草将雾吹到场外所需的游戏秒。
const BLOVER_BLOW_DURATION: float = 0.5
## 查看下一轮僵尸前退雾所需的游戏秒。
const ROUND_RETREAT_DURATION: float = 3.0
## 无三叶草保护时，新轮入场所需的游戏秒。
const ROUND_ENTER_DURATION: float = 5.0
## 三叶草等待结束后回场所需的游戏秒。
const BLOVER_RETURN_DURATION: float = 10.0

## 唯一的浓雾移动补间；替换时连同旧动作的完成回调一起取消。
var move_tween: Tween
## 当前是否已恢复主游戏；首次选卡和轮间展示期间为 false。
var is_round_active: bool = false
## 当前尚未结束的三叶草保护阶段。
var blover_phase: E_BloverPhase = E_BloverPhase.NONE

## 浓雾完全回到战场时的全局 X 坐标，单位为像素。
@export var start_global_positon_x:float = 290.0
## 浓雾被吹散及选卡期间的场外全局 X 坐标，单位为像素。
@export var end_global_positon_x:float = 1000.0
## 吹散完成后的等待计时器；新三叶草重置等待，重新选卡仅冻结剩余时间。
@onready var blover_end_timer: Timer = $BloverEndTimer

## 动态雾节点
@onready var dynamic_fog: Panel = $DynamicFog
## 静态迷雾（原版迷雾）
#region 静态迷雾（原版迷雾
@onready var static_fog: Node2D = $StaticFog
var fog_sprites:Array[Sprite2D] = []
## 删除静态浓雾的边缘，相对与Fog根节点位置，
@export var del_fog_postion_area:Vector2 = Vector2(650, 700)
#endregion

## 初始化场外显示，并接收雾类型及暂停因素的变化通知。
func _ready() -> void:
	init_static_fog(static_fog)
	change_fog_type()
	global_position.x = end_global_positon_x

	Global.config_service.signal_fog_is_static.connect(change_fog_type)
	TreePauseManager.pause_factors_changed.connect(_sync_retreat_pause)

## 修改雾的种类
func change_fog_type():
	if Global.config_service.fog_is_static:
		static_fog.visible = true
		dynamic_fog.visible = false
		update_fog_static()
	else:
		static_fog.visible = false
		dynamic_fog.visible = true
		update_fog_dynamic()

## 将浓雾移到 [param position_x]（全局像素坐标），并同步刷新植物清雾区域。
## 由移动补间直接调用，确保重新选卡暂停期间也能更新静态雾和动态雾。
func _set_fog_x(position_x: float) -> void:
	global_position.x = position_x
	if fog_clearers.is_empty():
		return
	if Global.config_service.fog_is_static:
		update_fog_static()
	else:
		update_fog_dynamic()

func add_fog_clearer(fog_clearer:Area2D):
	fog_clearers.append(fog_clearer)
	if Global.config_service.fog_is_static:
		update_fog_static()
	else:
		update_fog_dynamic()

func del_fog_clearer(fog_clearer:Area2D):
	fog_clearers.erase(fog_clearer)
	if Global.config_service.fog_is_static:
		update_fog_static()
	else:
		update_fog_dynamic()

## 根据fog_clearers数组更新迷雾
func update_fog_dynamic():
	var centers = []
	var sizes = []
	var rotations = []
	var collision_shapes = []

	for node in fog_clearers:
		var shape_node := node.get_node_or_null("CollisionShape2D")
		if shape_node and shape_node.shape:
			collision_shapes.append(shape_node)

	for i in range(min(collision_shapes.size(), 8)):
		var shape_node = collision_shapes[i]
		var shape = shape_node.shape
		var global_pos = shape_node.global_position - Global.main_game.camera_2d.global_position
		var local_pos = dynamic_fog.make_canvas_position_local(global_pos)
		var uv = local_pos / dynamic_fog.size

		if shape is RectangleShape2D:
			centers.append(uv)
			# 将矩形尺寸转换为UV空间比例
			var size_uv = shape.extents / dynamic_fog.size  # extents是半宽高
			sizes.append(size_uv)
			rotations.append(shape_node.global_rotation)

	# 填满剩余，避免数组长度不够
	while centers.size() < 16:
		centers.append(Vector2(-10, -10))  # 放到UV外面无效
		sizes.append(Vector2.ZERO)
		rotations.append(0.0)

	dynamic_fog.material.set_shader_parameter("rect_centers", centers)
	dynamic_fog.material.set_shader_parameter("rect_sizes", sizes)
	dynamic_fog.material.set_shader_parameter("rect_rotations", rotations)
	dynamic_fog.material.set_shader_parameter("rect_count", min(collision_shapes.size(), 8))

func init_static_fog(curr_static_fog):
	for node2d:Node2D in curr_static_fog.get_children():
		if not node2d is Sprite2D:
			init_static_fog(node2d)
		else:
			## 用不到的雾删除
			var delta := node2d.global_position - global_position - del_fog_postion_area
			if max(delta.x, delta.y) > 0:
				node2d.queue_free()
			else:
				fog_sprites.append(node2d)

func update_fog_static():
	for fog_sprite in fog_sprites:
		var texture: Texture2D = fog_sprite.texture
		if texture == null:
			continue

		var full_texture_size = texture.get_size()
		var hframes = fog_sprite.hframes
		var vframes = fog_sprite.vframes

		# 单帧原始大小
		var frame_size = Vector2(
			full_texture_size.x / hframes,
			full_texture_size.y / vframes
		)

		# 考虑缩放后的实际显示大小 除2
		var fog_size = frame_size * fog_sprite.global_scale / Vector2(1.5, 1.5)
		var fog_global_pos = fog_sprite.global_position
		var fog_rect = Rect2(fog_global_pos - fog_size * 0.5, fog_size)

		# 构造雾多边形（未旋转）
		var fog_poly = [
			fog_rect.position,
			fog_rect.position + Vector2(fog_rect.size.x, 0),
			fog_rect.position + fog_rect.size,
			fog_rect.position + Vector2(0, fog_rect.size.y),
		]

		var is_overlapping := false

		for area in fog_clearers:
			var shape_node = area.get_node_or_null("CollisionShape2D")
			if shape_node == null or shape_node.shape == null:
				continue

			if shape_node.shape is RectangleShape2D:
				var rect_shape: RectangleShape2D = shape_node.shape
				var half_size = rect_shape.size * 0.5

				# 构造本地矩形四个角
				var local_points = [
					Vector2(-half_size.x, -half_size.y),
					Vector2( half_size.x, -half_size.y),
					Vector2( half_size.x,  half_size.y),
					Vector2(-half_size.x,  half_size.y),
				]

				# 转为全局坐标（包含旋转）
				var global_points = []
				for p in local_points:
					global_points.append(shape_node.global_transform * p)

				# 判断是否与雾相交
				if Geometry2D.intersect_polygons(fog_poly, global_points).size() > 0:
					is_overlapping = true
					break

		# 设置透明度
		if is_overlapping:
			fog_sprite.visible = false
		else:
			fog_sprite.visible = true

## 取消当前移动及其后续回调；暂停中的补间同样必须取消。
func _cancel_move() -> void:
	if move_tween and move_tween.is_valid():
		move_tween.kill()
	move_tween = null


## 从当前位置移到 [param target_x]（全局像素坐标），耗时 [param duration] 游戏秒。
## [param allow_rechoose_pause] 仅供轮次退场使用，允许忽略重新选卡暂停。
## [param on_finished] 为可选的完成操作；替换或取消移动时不会执行旧操作。
func _start_move(target_x: float, duration: float, allow_rechoose_pause: bool = false,
		on_finished: Callable = Callable()) -> void:
	_cancel_move()
	move_tween = create_tween()
	if allow_rechoose_pause:
		move_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	move_tween.tween_method(_set_fog_x, global_position.x, target_x, duration)
	move_tween.tween_callback(_on_move_finished.bind(on_finished))
	if allow_rechoose_pause:
		# 创建时可能已经因菜单或失败暂停，不能只等待下一次暂停信号。
		_sync_retreat_pause()


## 清理已完成的移动，再执行 [param on_finished]；不改变三叶草计时的暂停状态。
func _on_move_finished(on_finished: Callable) -> void:
	move_tween = null
	if on_finished.is_valid():
		on_finished.call()


## 轮次退场只忽略重新选卡暂停；菜单、失败及其他暂停因素仍冻结该移动。
func _sync_retreat_pause() -> void:
	if is_round_active or not move_tween or not move_tween.is_valid():
		return
	# 暂停原因的枚举键；任一重新选卡以外的有效原因都应阻止退雾。
	for pause_factor in TreePauseManager.curr_pause_factor:
		if pause_factor != TreePauseManager.E_PauseFactor.ReChooseCard \
				and TreePauseManager.curr_pause_factor[pause_factor]:
			move_tween.pause()
			return
	move_tween.play()


## 新三叶草取消旧保护并重新吹散；轮间触发只更新冻结的完整等待，不打断退场。
func be_flow_away() -> void:
	blover_end_timer.stop()
	if not is_round_active:
		blover_phase = E_BloverPhase.WAITING
		blover_end_timer.paused = true
		blover_end_timer.start()
		return
	blover_phase = E_BloverPhase.BLOWING
	blover_end_timer.paused = false
	_start_move(end_global_positon_x, BLOVER_BLOW_DURATION, false, _on_blover_blow_finished)


## 吹散动画完成后才启动完整等待；动画被新三叶草或轮次退场取消时不会调用。
func _on_blover_blow_finished() -> void:
	blover_phase = E_BloverPhase.WAITING
	blover_end_timer.start()


## 恢复主游戏：有三叶草保护时继续剩余等待，否则正常入场。
## 不展示僵尸的跨轮不会暂停浓雾；重复调用不重置当前吹散、等待或回场。
func start_round() -> void:
	if is_round_active:
		return
	is_round_active = true
	_cancel_move()
	blover_end_timer.paused = false
	if blover_phase == E_BloverPhase.WAITING:
		_set_fog_x(end_global_positon_x)
		# 等待在切换边界恰好到期时直接回场，不能 start() 再补完整等待。
		if blover_end_timer.time_left <= 0.0:
			_on_blover_end_timer_timeout()
		return
	_start_move(start_global_positon_x, ROUND_ENTER_DURATION)


## 查看下一轮僵尸前退到场外，并冻结三叶草剩余等待；重复退场不重置计时。
func fog_outside() -> void:
	if not is_round_active:
		return
	is_round_active = false
	blover_end_timer.paused = true
	if blover_phase == E_BloverPhase.BLOWING:
		# 吹散尚未完成，保护计时还没开始；保留完整等待供新轮恢复。
		blover_phase = E_BloverPhase.WAITING
		blover_end_timer.start()
	if is_equal_approx(global_position.x, end_global_positon_x):
		_cancel_move()
		_set_fog_x(end_global_positon_x)
		return
	_start_move(end_global_positon_x, ROUND_RETREAT_DURATION, true)


## 三叶草等待结束后回场；保护期先结束，轮次切换不会重新发放等待时间。
func _on_blover_end_timer_timeout() -> void:
	if not is_round_active or blover_phase != E_BloverPhase.WAITING:
		return
	blover_phase = E_BloverPhase.NONE
	_start_move(start_global_positon_x, BLOVER_RETURN_DURATION)
