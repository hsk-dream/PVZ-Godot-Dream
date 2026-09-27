extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillIceFireBall
## 吐球效果组件：按锁定的冰火类型设置嘴部和眼部光效，释放关键帧创建球并喷出粒子。

## 冰球的相对抽取权重；0 表示不抽取冰球，默认与火球等概率，两者不能同时为 0。
@export_range(0.0, 100.0, 0.1, "or_greater") var ice_ball_weight: float = 1.0
## 火球的相对抽取权重；概率为本权重除以总权重，每次技能准备时读取，已锁定的类型不受后续修改影响。
@export_range(0.0, 100.0, 0.1, "or_greater") var fire_ball_weight: float = 1.0
## 冰球场景，根脚本必须继承 ZB001DoctorBallBase 并返回 Ice 类型。
@export var ice_ball_scene: PackedScene
## 火球场景，根脚本必须继承 ZB001DoctorBallBase 并返回 Fire 类型。
@export var fire_ball_scene: PackedScene
## 嘴部释放标记；只在释放时读取全局 X，Y 由目标行和坡面计算。
@export var spawn_marker: Marker2D
## 嘴部共用粒子节点，每次成功创建球时重新启动一次喷吐效果。
@export var spit_particles: GPUParticles2D
## 冰球喷吐使用逐帧左右镜像的四帧贴图（_flip_h），保持原有动画帧顺序。
@export var ice_particle_texture: Texture2D
## 火球喷吐使用逐帧左右镜像的四帧贴图（_flip_h），不通过修改共享材质切换类型。
@export var fire_particle_texture: Texture2D
## 吐球时的嘴部叠加光效，对应 Boss_mouthglow_red；显隐与形变由攻击动画控制。
@export var mouth_glow: Sprite2D
## 吐球时的眼部叠加光效，对应 Boss_eyeglow_red；与嘴部使用同一球类型。
@export var eye_glow: Sprite2D
## 吐冰球时的蓝色嘴部贴图。
@export var ice_mouth_texture: Texture2D
## 吐火球时的红色嘴部贴图，也是退出吐球状态后的默认贴图。
@export var fire_mouth_texture: Texture2D
## 吐冰球时的蓝色眼部贴图。
@export var ice_eye_texture: Texture2D
## 吐火球时的红色眼部贴图，也是退出吐球状态后的默认贴图。
@export var fire_eye_texture: Texture2D


## 吐球动画开始前统一设置嘴部和眼部颜色，显示时机仍由原有动画轨道决定。[br]
## [param ball_type] 准备阶段锁定的 Ice 或 Fire，不重新随机；无效类型只清理光效。
func apply_charge_visuals(ball_type: StringName) -> void:
	reset_charge_visuals()
	if ball_type != &"Ice" and ball_type != &"Fire":
		return
	mouth_glow.texture = ice_mouth_texture if ball_type == &"Ice" else fire_mouth_texture
	eye_glow.texture = ice_eye_texture if ball_type == &"Ice" else fire_eye_texture


## 正常结束或死亡中断时关闭两处叠加光效并恢复默认贴图，避免后续动作残留蓝光。
func reset_charge_visuals() -> void:
	if is_instance_valid(mouth_glow):
		mouth_glow.hide()
		mouth_glow.texture = fire_mouth_texture
	if is_instance_valid(eye_glow):
		eye_glow.hide()
		eye_glow.texture = fire_eye_texture


## 先从具备对应动画的有效行中选择目标，再按配置权重锁定冰火类型，每轮只抽取一次。[br]
## [param allowed_lanes] 吐球状态的动画行映射；没有有效行、权重非法或战斗已结束时返回空字典。
func prepare_parameters(allowed_lanes: Array[int]) -> Dictionary:
	# 当前博士所属的有效战斗场景，技能准备不依赖自然波次选行器。
	var game: MainGameManager = _get_active_game()
	if game == null:
		return {}
	# 运行中允许修改权重，准备时重查，避免将非法权重交给随机选择器。
	if not _get_ball_weight_configuration_error().is_empty():
		return {}
	# 本次技能的等权行选择器，复用项目 RandomPicker，排除不存在的行和重复行。
	var lane_picker: RandomPicker = RandomPicker.new()
	# 动画映射中的候选行号，从 0 开始。
	for lane: int in allowed_lanes:
		if lane < 0 or lane >= game.zombie_manager.all_zombie_rows.size() or lane_picker.has_item(lane):
			continue
		# 当前候选行，出生标记为球提供地面基准 Y。
		var row: ZombieRow = game.zombie_manager.all_zombie_rows[lane]
		if is_instance_valid(row) and row.is_inside_tree() and not row.is_queued_for_deletion() \
			and is_instance_valid(row.zombie_create_position):
			lane_picker.add_item(lane, 1.0, false)
	if lane_picker.is_empty():
		return {}
	# 汇总全部有效行后只构建一次权重表。
	lane_picker.rebuild_alias_table()
	# 随机选择器只接受正权重；为 0 的类型不加入池，另一类型即可被确定选中。
	var type_picker: RandomPicker = RandomPicker.new()
	if ice_ball_weight > 0.0:
		type_picker.add_item(&"Ice", ice_ball_weight, false)
	if fire_ball_weight > 0.0:
		type_picker.add_item(&"Fire", fire_ball_weight, false)
	type_picker.rebuild_alias_table()
	return {"lane": lane_picker.get_random_item(), "ball_type": type_picker.get_random_item()}


## 创建时直接挂到 Items，成形和滚动均独立于博士的后续变换；球不增加关卡僵尸数量。[br]
## [param parameters] 准备阶段锁定的 lane 和 ball_type，释放时不重新随机。
func execute(parameters: Dictionary) -> void:
	# 重查角色和关卡生命周期，取消死亡或场景退出后才到达的释放请求。
	var game: MainGameManager = _get_active_game()
	if game == null or not parameters.has_all(["lane", "ball_type"]) \
		or not is_instance_valid(spawn_marker) or not spawn_marker.is_inside_tree() or spawn_marker.is_queued_for_deletion():
		return
	# 本次球的类型标识，与子类返回的类型核对，防止误绑定冰火场景。
	var ball_type: StringName = parameters["ball_type"]
	if ball_type != &"Ice" and ball_type != &"Fire":
		return
	# 根据已经锁定的类型取得场景，不在释放关键帧重新选择类型。
	var scene: PackedScene = ice_ball_scene if ball_type == &"Ice" else fire_ball_scene
	if scene == null or not scene.can_instantiate():
		return
	# 实例尚未入树时检查脚本类型，错误配置立即释放，避免残留无行为的精灵。
	var instance: Node = scene.instantiate()
	# 冰火球统一父类引用，子类只负责自己的动画和类型定义。
	var ball: ZB001DoctorBallBase = instance as ZB001DoctorBallBase
	if ball == null or ball.get_ball_type() != ball_type:
		push_error("IceFireBallSkill：冰火球场景必须绑定类型匹配的球子类脚本。")
		instance.free()
		return
	# 初始出生点仍沿用嘴部 X 和目标行地面 Y，挂在 Items 下不再跟随嘴部移动。
	var spawn_x: float = spawn_marker.global_position.x
	game.items.add_child(ball)
	if not ball.launch(game, parameters["lane"], spawn_x):
		ball.queue_free()
		return
	_play_spit_particles(ball_type)


## 与创建球共用头部攻击动画的 1.25 秒释放事件；失败或死亡取消的释放不会喷出粒子。[br]
## [param ball_type] 本次已经锁定的 Ice 或 Fire，决定嘴部粒子贴图。
func _play_spit_particles(ball_type: StringName) -> void:
	if not is_instance_valid(spit_particles) or spit_particles.is_queued_for_deletion():
		return
	spit_particles.texture = ice_particle_texture if ball_type == &"Ice" else fire_particle_texture
	# 单次粒子使用 restart() 重置上一轮模拟，连续吐球也能从第一帧重新喷出。
	# 已喷出的粒子在世界坐标中运动，自行消散，不被博士后续抬头拖动。
	spit_particles.restart()


## 博士启动前检查类型权重、场景、嘴部标记、粒子与冰火光效绑定；实体在 launch() 中检查子类动画。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 权重错误已在具体检测分支输出，此处仅向调用者转发以中止初始化。
	var weight_error: String = _get_ball_weight_configuration_error()
	if not weight_error.is_empty():
		return weight_error
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if ice_ball_scene == null or not ice_ball_scene.can_instantiate() \
		or fire_ball_scene == null or not fire_ball_scene.can_instantiate():
		detected_error = "IceFireBallSkill 必须绑定可实例化的冰球与火球场景。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(spawn_marker) or not is_instance_valid(owner) or not owner.is_ancestor_of(spawn_marker):
		detected_error = "IceFireBallSkill 必须绑定博士自身的嘴部 Marker2DSpawnBall。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(spit_particles) or not owner.is_ancestor_of(spit_particles) \
		or spit_particles.process_material == null or not spit_particles.one_shot:
		detected_error = "IceFireBallSkill 必须绑定博士自身配置了处理材质的单次喷吐粒子。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if ice_particle_texture == null or fire_particle_texture == null:
		detected_error = "IceFireBallSkill 必须绑定冰球和火球的喷吐粒子贴图。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(mouth_glow):
		detected_error = "mouth_glow 未绑定有效 Sprite2D，应指向 Body/BodyCorrect/Head/Boss_mouthglow_red。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(eye_glow):
		detected_error = "eye_glow 未绑定有效 Sprite2D，应指向 Body/BodyCorrect/Head/Boss_eyeglow_red。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if mouth_glow == eye_glow:
		detected_error = "mouth_glow 和 eye_glow 不能绑定同一个节点。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not owner.is_ancestor_of(mouth_glow):
		detected_error = "mouth_glow 必须属于当前博士场景。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not owner.is_ancestor_of(eye_glow):
		detected_error = "eye_glow 必须属于当前博士场景。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if ice_mouth_texture == null or fire_mouth_texture == null or ice_eye_texture == null or fire_eye_texture == null:
		detected_error = "IceFireBallSkill 必须绑定冰火两套嘴部和眼部贴图。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""


## 检查相对权重，合法时返回空字符串；非法时在检测处报告错误并返回原因。
func _get_ball_weight_configuration_error() -> String:
	# 初始化与每轮准备共用同一校验，防止编辑器配置和运行中赋值采用不同规则。
	var detected_error: String = ""
	if not is_finite(ice_ball_weight) or ice_ball_weight < 0.0 \
		or not is_finite(fire_ball_weight) or fire_ball_weight < 0.0:
		detected_error = "冰球和火球权重必须为有限非负数。"
	elif not is_finite(ice_ball_weight + fire_ball_weight) or ice_ball_weight + fire_ball_weight <= 0.0:
		detected_error = "冰球和火球总权重必须为有限正数，不能同时为 0。"
	if not detected_error.is_empty():
		push_error("%s：%s" % [get_path(), detected_error])
	return detected_error


## 只允许正常出战且存活的博士在当前关卡释放；球生成后不再依赖博士引用。
func _get_active_game() -> MainGameManager:
	# 场景 owner 为所属博士，避免依赖 Skills 下的固定节点层级。
	var doctor: ZB001Doctor = owner as ZB001Doctor
	if not is_instance_valid(doctor) or doctor.is_death or not doctor.is_inside_tree() \
		or doctor.is_queued_for_deletion() or doctor.character_init_type != Character000Base.E_CharacterInitType.IsNorm:
		return null
	# 本技能所属的关卡，确认尚在战斗中且独立球挂载节点仍有效。
	var game: MainGameManager = Global.main_game
	if not is_instance_valid(game) or game.is_queued_for_deletion() or not game.is_ancestor_of(doctor) \
		or game.main_game_progress != MainGameManager.E_MainGameProgress.MAIN_GAME \
		or not is_instance_valid(game.zombie_manager) or not is_instance_valid(game.items) or game.items.is_queued_for_deletion():
		return null
	return game
