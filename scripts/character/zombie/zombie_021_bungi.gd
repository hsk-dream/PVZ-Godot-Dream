## 蹦极僵尸沿用自身下降与上升流程；偷取结束通知召唤者，死亡仍走普通僵尸统计。
extends Zombie000Base
class_name Zombie021Bungi

## 成功偷取或确定放弃目标时只发出一次，不等待上升离场；死亡由角色死亡信号通知。
signal signal_steal_finished()

## 与身体遮罩共用的材质模板；每只蹦极复制一份，避免不同绳子的裁切高度互相覆盖。
const ROPE_MASK: ShaderMaterial = preload("res://shader_material/body_mask.tres")

## 被偷植物表现的挂载容器，随僵尸一起上升。
@onready var bungi_container: Node2D = $Body/BodyCorrect/BungiContainer
## 身体下降和上升使用的局部偏移节点，根节点始终保留落点坐标。
@onready var body_correct: Node2D = $Body/BodyCorrect
## 上升动画前需要切换父节点的绳子。
@onready var bungee_cords: Node2D = $Body/BodyCorrect/Zombie_bungi_body/BungeeCords
## 抓取动画切换后用于承载绳子的身体精灵。
@onready var zombie_bungi_body_2: Sprite2D = $Body/BodyCorrect/Zombie_bungi_body2
## 目标靶子；普通入场时出现，博士召唤或开始返回时隐藏。
@onready var bungee_target: Sprite2D = $BungeeTarget

@export_group("动画状态")
## 身体已经接近地面，允许动画树从下降切换到待机。
@export var is_drop_end: bool = false
## 落地等待结束，允许动画树进入抓取动画。
@export var is_grab: bool = false
## 已被保护伞弹开，本次不能继续偷取植物。
@export var is_umbrella_raise: bool = false
## 出战前注入的目标格子，实际抓取时读取其中最新的植物。
var plant_cell: PlantCell
## 是否跳过靶子和下降前的两秒预警；博士召唤时在入树前设置为 true，普通出怪默认保留预警。
var skip_spawn_warning: bool = false
## 博士召唤时入树前注入的手部连接点；普通蹦极为 null，不启用绳子裁切。
var bungee_anchor: Marker2D
## 当前实例的绳子材质，全部绳段通过 BungeeCords 继承；持续到本实例离场。
var _rope_material: ShaderMaterial
## 每只僵尸只允许发送一次偷取结束信号。
var _steal_finished: bool = false
## 返回流程只能启动一次，并阻止下降阶段的异步回调继续执行。
var _is_raising: bool = false
## 当前下降 Tween，返回或死亡时取消，避免和上升 Tween 同时写身体位置。
var _drop_tween: Tween


## 在新实例入树前统一注入出战参数；只保存引用与标记，不访问 onready 节点或重置运行状态。[br]
## [param target_cell] 本次偷取的目标格子，实际抓取时读取其中最新的植物。[br]
## [param skip_warning] 是否跳过靶子和下降前预警，普通出怪默认为 false。[br]
## [param rope_anchor] 博士手部绳子连接点；普通蹦极默认为 null，不启用裁切。
func initialize_spawn(target_cell: PlantCell, skip_warning: bool = false, rope_anchor: Marker2D = null) -> void:
	plant_cell = target_cell
	skip_spawn_warning = skip_warning
	bungee_anchor = rope_anchor


## 根据入场参数决定是否显示预警；两种模式共用下降和落地等待，每次异步恢复都检查中断。
func ready_norm() -> void:
	super()
	if not is_instance_valid(plant_cell):
		push_error("Zombie021Bungi：正常出战前必须注入目标格子。")
		character_death_disappear.call_deferred()
		return
	_initialize_rope_mask()
	hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	body_correct.position.y -= 600
	if skip_spawn_warning:
		# 入树时立即隐藏，不创建靶子 Tween 或前置计时器，直接开始下降。
		bungee_target.visible = false
	else:
		bungee_target.position.y -= 600
		# 普通蹦极的靶子动画和两秒预警同时开始，保持原有入场节奏。
		var target_tween: Tween = create_tween()
		target_tween.tween_property(bungee_target, "position:y", bungee_target.position.y + 600, 0.5)
		await get_tree().create_timer(2.0, false).timeout
	if not _can_continue_descent():
		return
	_drop_tween = create_tween()
	_drop_tween.set_parallel()
	_drop_tween.tween_callback(_mark_drop_end).set_delay(1.8)
	_drop_tween.tween_callback(_enable_descent_hurt_box).set_delay(1.3)
	_drop_tween.tween_property(body_correct, "position:y", body_correct.position.y + 600, 2.0).set_trans(Tween.TRANS_BACK)
	await _drop_tween.finished
	if not _can_continue_descent():
		return
	await get_tree().create_timer(2.0, false).timeout
	if not _can_continue_descent():
		return
	is_grab = true
	body.z_index -= 50


## 展示实例不执行偷取，也不显示靶子和影子。
func ready_show() -> void:
	super()
	set_process(false)
	bungee_target.visible = false
	shadow.visible = false


## 在首次显示前配置裁切；只让绳段继承材质，不修改角色身体与被偷植物的材质。
func _initialize_rope_mask() -> void:
	set_process(false)
	if not is_instance_valid(bungee_anchor) or not bungee_anchor.is_inside_tree() or bungee_anchor.is_queued_for_deletion():
		return
	_rope_material = ROPE_MASK.duplicate() as ShaderMaterial
	_rope_material.set_shader_parameter(&"clip_above", true)
	_rope_material.set_shader_parameter(&"use_world_coordinates", true)
	_rope_material.set_shader_parameter(&"fade_width", 1.0)
	bungee_cords.material = _rope_material
	bungee_cords.use_parent_material = false
	# 仅遍历绳子容器的子节点，不能把容器自身改为继承身体材质。
	for child: Node in bungee_cords.get_children():
		if child is Node2D:
			GlobalUtils.node_use_parent_material(child)
	_update_rope_mask()
	set_process(true)


## [param _delta] 本帧间隔；裁切只读取定位点当前位置，不累计时间，也不依赖批次等待状态。
func _process(_delta: float) -> void:
	_update_rope_mask()


## 偷取结束后的上升阶段仍跟随手部；定位点释放时保留最后高度，避免上方绳子突然显现。
func _update_rope_mask() -> void:
	if _rope_material == null or not is_instance_valid(bungee_anchor) \
		or not bungee_anchor.is_inside_tree() or bungee_anchor.is_queued_for_deletion():
		set_process(false)
		return
	_rope_material.set_shader_parameter(&"cutoff_y", bungee_anchor.global_position.y)


## 下降阶段仍活动时才能恢复回调，避免死亡或被弹开后再次抓取、开启受击。
func _can_continue_descent() -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and not is_death and not _is_raising and not is_umbrella_raise


## 延迟切换动画状态，取消下降后不再修改。
func _mark_drop_end() -> void:
	if _can_continue_descent():
		is_drop_end = true


## 下降到可受击高度时开启受击；回调可能同步触发保护伞或其他攻击。
func _enable_descent_hurt_box() -> void:
	if _can_continue_descent():
		hurt_box_component.enable_component(ComponentNormBase.E_IsEnableFactor.Character)


## 动画轨道触发返回；偷取完成即通知博士，不等待这一秒上升结束。
func raise_start() -> void:
	if _is_raising or is_death or is_queued_for_deletion():
		return
	_is_raising = true
	_stop_drop_tween()
	if not is_umbrella_raise and is_instance_valid(plant_cell):
		bungi_plant_cell(plant_cell)
	# 植物死亡可能同步触发其他效果，先确认自己仍存活再继续返回。
	if is_death or is_queued_for_deletion():
		return
	bungee_target.visible = false
	hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	_finish_steal()
	if is_death or is_queued_for_deletion():
		return
	# 上升与影子消失并行；返回完成才按原流程移除并扣减场上僵尸数量。
	var raise_tween: Tween = create_tween()
	raise_tween.set_parallel()
	raise_tween.tween_property(body_correct, "position:y", body_correct.position.y - 600, 1.0)
	raise_tween.tween_property(shadow, "scale", Vector2.ZERO, 0.5)
	await raise_tween.finished
	if not is_death and not is_queued_for_deletion():
		character_death_disappear()


## [param target_cell] 当前目标格子；目标消失则空手返回，每次最多偷一层植物。
func bungi_plant_cell(target_cell: PlantCell) -> void:
	if not is_instance_valid(target_cell) or target_cell.is_queued_for_deletion():
		return
	# 植物死亡回调可能释放表现节点或攻击自己，接收后必须重新验证。
	var plant_body_copy: Variant = target_cell.be_bungi()
	if not is_instance_valid(plant_body_copy):
		return
	if is_death or is_queued_for_deletion():
		plant_body_copy.queue_free()
		return
	plant_body_copy.reparent(bungi_container)


## 标记本次偷取已结束；空手和被弹开同样属于结束，信号绝不重复发送。
func _finish_steal() -> void:
	if _steal_finished:
		return
	_steal_finished = true
	signal_steal_finished.emit()


## 停止旧下降轨迹，防止返回时被旧 Tween 再次拉回地面。
func _stop_drop_tween() -> void:
	if is_instance_valid(_drop_tween) and _drop_tween.is_valid():
		_drop_tween.kill()


## 抓取动画切换身体后，让绳子跟随新的身体精灵。
func update_bungee_cords_parent() -> void:
	bungee_cords.reparent(zombie_bungi_body_2)


## 保留普通死亡信号和管理器统计，取消下降后立即释放蹦极实例。
func character_death() -> void:
	_stop_drop_tween()
	super()
	queue_free()


## 保护伞使本次偷取立即作废；动画树负责切换上升，博士无需继续等待该实例。
func be_umbrella_leaf() -> void:
	if is_death or is_queued_for_deletion() or _is_raising or is_umbrella_raise:
		return
	is_umbrella_raise = true
	_stop_drop_tween()
	_finish_steal()
