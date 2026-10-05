extends Node
class_name GIM_LawnMover

@onready var game_item_manager: GameItemManager = %GameItemManager

## 小推车类型
enum E_LawnMoverType{
	LawnMover,
	PoolCleaner,
	RoofCleaner,
}

## 小推车场景
const LawnMoverSecneMap = {
	E_LawnMoverType.LawnMover : preload("res://scenes/item/game_scenes_item/lawn_mover/lawn_mower.tscn"),
	E_LawnMoverType.PoolCleaner : preload("res://scenes/item/game_scenes_item/lawn_mover/pool_cleaner.tscn"),
	E_LawnMoverType.RoofCleaner : preload("res://scenes/item/game_scenes_item/lawn_mover/roof_cleaner.tscn")
}

## 所有场景中的小推车类型
const AllLawnMoverTypeFromGameScenes = {
	MainSceneRegistry.MainScenes.MainGameFront:[0,0,0,0,0],
	MainSceneRegistry.MainScenes.MainGameBack:[0,0,1,1,0,0],
	MainSceneRegistry.MainScenes.MainGameRoof:[2,2,2,2,2]
}

@onready var lawn_movers: Node2D = %LawnMovers
## 小推车生成的全局x位置
@export var GlobalXLawnMover:float = 20
var all_lawn_movers_type:Array = []
var all_lawn_movers_global_pos:Array[Vector2] = []
var all_lawn_movers:Array[LawnMover] = []

var game_scene:MainSceneRegistry.MainScenes

func _ready() -> void:
	game_scene = game_item_manager.game_para.game_sences
	## 补充小推车
	EventBus.subscribe("replenish_lawn_mover", replenish_lawn_mover)

## 初始化小推车
func init_lawn_movers() -> void:
	if game_item_manager.game_para.save_game_data_main_game != null :
		create_all_lawn_movers(game_item_manager.game_para.save_game_data_main_game.lawn_mover_manager_data["is_has_all_lawn_mover"])
	else:
		create_all_lawn_movers()

## 生成所有的小推车
func create_all_lawn_movers(is_has_all_lawn_mover:Array=[]):
	all_lawn_movers_type = AllLawnMoverTypeFromGameScenes[game_scene]

	print("创建小推车, 小推车类型", all_lawn_movers_type)
	assert(game_item_manager.main_game.zombie_manager.all_zombie_rows.size() == all_lawn_movers_type.size(), "小推车数量与僵尸行数量不一致")
	for lane in range(all_lawn_movers_type.size()):
		var zombie_row:ZombieRow = game_item_manager.main_game.zombie_manager.all_zombie_rows[lane]
		var global_pos_lawn_mover:Vector2 = Vector2(GlobalXLawnMover, zombie_row.zombie_create_position.global_position.y)
		all_lawn_movers_global_pos.append(global_pos_lawn_mover)
		var new_lawn_mover:LawnMover
		if is_has_all_lawn_mover.is_empty() or is_has_all_lawn_mover[lane] == true:
			new_lawn_mover = create_lawn_mover(lane, all_lawn_movers_type[lane], all_lawn_movers_global_pos[lane])
		else:
			new_lawn_mover = null
		all_lawn_movers.append(new_lawn_mover)

## 补充小推车
func replenish_lawn_mover():
	if all_lawn_movers.is_empty():
		create_all_lawn_movers()
	else:
		# 按行检查原位可用小推车；被碾压但尚未释放的车也需要补充。
		for i in range(all_lawn_movers.size()):
			if is_instance_valid(all_lawn_movers[i]) and not all_lawn_movers[i].is_queued_for_deletion() \
				and not all_lawn_movers[i].is_destroyed and not all_lawn_movers[i].is_moving:
				continue
			else:
				# 本行新补充的小推车，替换旧引用；视觉残留不参与管理器登记。
				var new_lawn_mover = create_lawn_mover(i, all_lawn_movers_type[i], all_lawn_movers_global_pos[i])
				all_lawn_movers[i] = new_lawn_mover

## 生成一个小推车
func create_lawn_mover(lane:int, lawn_mover_type:E_LawnMoverType, global_pos:Vector2)->LawnMover:
	var new_lawn_mover:LawnMover = LawnMoverSecneMap[lawn_mover_type].instantiate()
	new_lawn_mover.lane = lane
	new_lawn_mover.z_index = lane * 50 + 40
	## 由于在ready中会检测屋顶，使用全局位置，因此在add_child之前修改其局部位置
	new_lawn_mover.position = global_pos - lawn_movers.global_position
	lawn_movers.add_child(new_lawn_mover)
	lawn_mover_appear(new_lawn_mover)
	return new_lawn_mover

## 小推车出现动画。[param lawn_mover] 为新生成的车，动画随该车销毁自动取消。
func lawn_mover_appear(lawn_mover:Node2D):
	# 滑入动画的最终局部横坐标。
	var pos_x = lawn_mover.position.x
	lawn_mover.position.x -= 100
	# 绑定车节点而非管理器，避免被碾压后继续写入已释放对象。
	var tween:Tween = lawn_mover.create_tween()
	tween.tween_property(lawn_mover, "position:x", pos_x, 0.5)

func get_save_game_data_lawn_mover_manager()->Dictionary:
	# 保存各行是否仍有未启动、未销毁的小推车。
	var save_game_data_lawn_mover:Dictionary = {}
	# 与行号对应的可用状态列表，不包含压扁后的视觉副本。
	var is_has_all_lawn_mover:Array[bool] = []
	# 当前检查的行号；待删除的原车即使引用有效也不能存为可用。
	for i in range(all_lawn_movers.size()):
		if is_instance_valid(all_lawn_movers[i]) and not all_lawn_movers[i].is_queued_for_deletion() \
			and not all_lawn_movers[i].is_destroyed and not all_lawn_movers[i].is_moving:
			is_has_all_lawn_mover.append(true)
		else:
			is_has_all_lawn_mover.append(false)
	save_game_data_lawn_mover["is_has_all_lawn_mover"] = is_has_all_lawn_mover
	return save_game_data_lawn_mover

