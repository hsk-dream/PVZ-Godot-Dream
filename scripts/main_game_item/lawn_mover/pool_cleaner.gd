extends LawnMover
class_name PoolCleaner

## 启动时记录的正常移速，吸入僵尸结束后恢复。
var ori_move_speed:float

#region 游泳相关

## 碰到僵尸
var is_zombie: bool = false

@export_group("游泳相关")
@export var is_water := false
###游泳消失的精灵图
#@export var swimming_fade : Array[Sprite2D]
###游泳出现的精灵图
#@export var swimming_appear : Array[Sprite2D]
#endregion


func _ready() -> void:
	super._ready()
	ori_move_speed = move_speed


func _on_area_entered(area: Area2D) -> void:
	# 被碾压后忽略同帧的僵尸和水池回调，防止重新启动或生成水花。
	if is_destroyed or is_queued_for_deletion() or not is_instance_valid(area):
		return
	# 区域所属节点，可能为僵尸或泳池；释放中的无效 owner 不参与检测。
	var owner_node = area.owner
	if not is_instance_valid(owner_node):
		return
	if owner_node is Zombie000Base:
		if lane == owner_node.lane:
			_on_lane_zombie_enter(owner_node)

	elif owner_node.name =="Pool":
		print("小推车碰撞到泳池")
		start_swim()

## 启动小推车
func _start_mower():
	if is_destroyed or is_queued_for_deletion():
		return
	is_moving = true
	SoundManager.play_other_SFX("pool_cleaner")
	animation_player.play("PoolCleaner_land")
	_mower_run_all_zombie_on_start()

func _on_area_exited(area: Area2D) -> void:
	if is_destroyed or is_queued_for_deletion() or not is_instance_valid(area):
		return
	# 离开区域的所属节点，水池退出负责恢复陆地状态。
	var owner_node = area.owner
	if not is_instance_valid(owner_node):
		return
	if owner_node is Zombie000Base:
		pass

	elif owner_node.name =="Pool":
		print("小推车碰离开泳池")
		end_swim()

func suck_end():
	if is_destroyed or is_queued_for_deletion():
		return
	move_speed = ori_move_speed
	is_zombie = false

## 小推车碾压一个僵尸
func _mower_run_one_zombie(zombie :Zombie000Base):
	if is_destroyed or is_queued_for_deletion() or not is_instance_valid(zombie) or zombie.is_queued_for_deletion():
		return
	zombie.character_death_disappear()
	move_speed = ori_move_speed / 4
	is_zombie = true

#region 水池游泳

func start_swim():
	# 水花
	var splash = SceneRegistry.SPLASH.instantiate()
	get_parent().add_child(splash)
	splash.global_position = global_position
	is_water = true

func end_swim():
	# 水花
	var splash = SceneRegistry.SPLASH.instantiate()
	get_parent().add_child.call_deferred(splash)
	splash.global_position = global_position
	is_water = false
#endregion
