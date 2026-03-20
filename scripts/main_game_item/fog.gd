extends Node2D
class_name Fog
## 目前动态雾只接受8个驱散雾的area2d,如果要增加，需要更改fog的着色器脚本
## 是否为静态雾（原版雾）,使用Global.fog_is_static
#@export var is_static_fog := true
## 清除雾的Area2d
var fog_clearers:Array[Area2D] = []
## 是否正在移动，如果正在移动需要每帧更新fog
var is_move := false
var tween_come_back : Tween

@export var start_global_positon_x:float = 290.0
## 被吹散的位置和游戏开始时的位置
@export var end_global_positon_x:float = 1000.0
## 吹散之后返回游戏计时器,每次吹散重新启动
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

func _ready() -> void:
	init_static_fog(static_fog)
	change_fog_type()
	global_position.x = end_global_positon_x

	Global.config_service.signal_fog_is_static.connect(change_fog_type)

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

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if is_move and not fog_clearers.is_empty():
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

## 被吹散
func be_flow_away():
	## 先停止计时器，避免在等待间隙计时完成
	blover_end_timer.stop()
	## 如果当前fog正在移动回到游戏场景，停止移动
	if tween_come_back and tween_come_back.is_running():
		tween_come_back.kill()
	## 使用tween吹散迷雾
	var tween :Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position:x", end_global_positon_x, 0.5)
	is_move = true
	## 吹散后, 开始计时
	await tween.finished
	is_move = false
	blover_end_timer.start()

## 回到主游戏界面
func come_back_game(duration:float, res_glo_pos_x:=start_global_positon_x):
	tween_come_back = get_tree().create_tween()
	tween_come_back.tween_property(self, "global_position:x", res_glo_pos_x, duration)
	is_move = true
	await tween_come_back.finished
	is_move = false
	blover_end_timer.paused = false


## 迷雾到外面,多轮游戏时调用
func fog_outside():
	## 先停止计时器，避免在等待间隙计时完成
	blover_end_timer.stop()
	## 如果当前fog正在移动回到游戏场景，停止移动
	if tween_come_back and tween_come_back.is_running():
		tween_come_back.kill()
	come_back_game(3, end_global_positon_x)

## 吹散迷雾24秒回到游戏
func _on_blover_end_timer_timeout() -> void:
	come_back_game(10.0)
