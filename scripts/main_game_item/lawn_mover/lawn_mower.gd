extends Node2D
class_name LawnMover
## 小推车

## 推车行号，从 0 开始，由小推车管理器在入树前赋值。
var lane: int = -1
## 推车启动后的移动速度，单位为像素/秒。
@export var move_speed: float = 300.0
## 小推车动画播放器，碾压时保留当前姿态并停止播放。
@onready var animation_player: AnimationPlayer = $AnimationPlayer
## 共用的僵尸检测与被碾压区域，通过第 14 层允许冰火球检测本车。
@onready var area_2d: Area2D = $Area2D
## 车身精灵容器，被碾压时复制当前姿态作为无碰撞的视觉残留。
@onready var body: Node2D = $Body

## 是否已启动；被碾压时立即停止移动。
var is_moving: bool = false
## 被碾压后立即置为 true，阻止排队删除前的启动、攻击和重复碾压。
var is_destroyed: bool = false
## 超出屏幕500像素删除
var screen_rect: Rect2  # 延后初始化

func _ready() -> void:
	# 必须在 ready 后才能安全获取视口尺寸
	screen_rect = get_viewport_rect().grow(500)


func _process(delta: float) -> void:
	if is_moving:
		position.x += move_speed * delta

		if not screen_rect.has_point(global_position):
			queue_free()


func _on_area_entered(area: Area2D) -> void:
	if is_destroyed or is_queued_for_deletion() or not is_instance_valid(area):
		return
	# 检测区域所属角色，只有普通僵尸能够触发原有清场逻辑。
	var area_owner = area.owner
	if area_owner is Zombie000Base:
		# 已确认类型的目标僵尸，只有同行才会触发小推车。
		var zombie :Zombie000Base = area_owner
		if lane == zombie.lane:
			_on_lane_zombie_enter(zombie)

## 当同行僵尸进入
func _on_lane_zombie_enter(zombie :Zombie000Base):
	if is_destroyed or is_queued_for_deletion():
		return
	if not is_moving:
		start_trigger_filter(zombie)
	else:
		_mower_run_one_zombie(zombie)

## 启动触发过滤
func start_trigger_filter(zombie :Zombie000Base):
	if is_destroyed or is_queued_for_deletion():
		return
	if zombie is Zombie018Digger:
		## 掘土状态矿工不触发小推车，连接启动小推车函数
		if not zombie.is_can_trigger_mower:
			zombie.signal_can_trigger_mower.connect(_start_mower)
			return
	_start_mower()

## 启动小推车
func _start_mower():
	# 矿工信号可能在本车被碾压后、正式释放前到达，不能再次启动。
	if is_destroyed or is_queued_for_deletion():
		return
	is_moving = true
	animation_player.play("LawnMower_normal")
	SoundManager.play_other_SFX("lawnmower")
	_mower_run_all_zombie_on_start()

## 启动时碾压当前所有的僵尸
func _mower_run_all_zombie_on_start():
	# 碰撞快照可能包含已释放的区域，先验证引用，再转换为强类型节点。
	for area_reference: Variant in area_2d.get_overlapping_areas():
		if is_destroyed or is_queued_for_deletion():
			return
		if not is_instance_valid(area_reference):
			continue
		# 仍存活的检测区域；排队删除的目标不再参与启动攻击。
		var area: Area2D = area_reference as Area2D
		if area == null or area.is_queued_for_deletion():
			continue
		# 区域所属角色，仅处理同行的普通僵尸。
		var area_owner = area.owner
		if area_owner is Zombie000Base:
			# 已确认类型的目标僵尸。
			var zombie :Zombie000Base = area_owner
			if lane == zombie.lane:
				_mower_run_one_zombie(zombie)

## 小推车碾压一个僵尸
func _mower_run_one_zombie(zombie :Zombie000Base):
	if is_destroyed or is_queued_for_deletion() or not is_instance_valid(zombie) or zombie.is_queued_for_deletion():
		return
	zombie.be_mowered_run(self)


## 被冰火球碾压：原车立即失效并释放，留下纵向压缩至 0.4 的车身副本两秒。[br]
## 重复碾压、已离场或待删除时忽略；视觉副本没有碰撞和小推车脚本。
func be_flattened() -> void:
	if is_destroyed or is_queued_for_deletion() or not is_inside_tree():
		return
	is_destroyed = true
	is_moving = false
	set_process(false)
	# 泳池车使用动画树驱动姿态，必须先停树，再停止播放器并保留当前帧。
	var animation_tree: AnimationTree = get_node_or_null("AnimationTree") as AnimationTree
	if is_instance_valid(animation_tree):
		animation_tree.active = false
	animation_player.stop(true)
	_create_flattened_remains()
	# 可能正在处理物理碰撞回调，延迟修改开关；销毁标记负责阻止本帧继续行动。
	area_2d.set_deferred("monitoring", false)
	area_2d.set_deferred("monitorable", false)
	hide()
	queue_free()


## 将车身当前外观复制到同级的纯视觉容器，保留原车变换与绘制层级，不登记到管理器。
func _create_flattened_remains() -> void:
	# 同级容器替代原车根节点的变换和绘制属性，避免车身副本失去行层级或位置偏移。
	var remains: Node2D = Node2D.new()
	remains.name = "FlattenedLawnMover"
	remains.transform = transform
	remains.z_index = z_index
	remains.z_as_relative = z_as_relative
	remains.modulate = modulate
	remains.self_modulate = self_modulate
	get_parent().add_child(remains)
	# 只复制节点外观，不复制脚本、信号连接和分组；身体保留当前局部变换。
	var body_copy: Node2D = body.duplicate(0) as Node2D
	remains.add_child(body_copy)
	body_copy.scale.y *= 0.4
	# 清理计时绑定视觉容器；暂停时停止计时，切换场景释放容器时一并取消。
	var cleanup_tween: Tween = remains.create_tween()
	cleanup_tween.tween_interval(2.0)
	cleanup_tween.tween_callback(remains.queue_free)
