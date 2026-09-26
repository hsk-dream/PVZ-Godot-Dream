extends Node
## 扫描真实角色场景，验证八类动作计时全部迁移且继承场景没有遗漏。
## Godot --headless --path . res://tests/character_speed_timer_test.tscn --fixed-fps 60

var checks := 0
var failures := 0
var migrated_scenes: Array[String] = []
var game: MainGameManager
const MAIN = preload("res://scenes/main/MainGame03Roof.tscn")

## 保留真实关卡子节点和坡面数据，只跳过选卡及自动出怪流程。
class ControlledMainGame extends MainGameManager:
	func _ready() -> void:
		pass

const CASES := [
	["plant_001_pea_shooter_single", "AttackComponent/BulletAttackCdTimer"],
	["plant_002_sun_flower", "CreateSunComponent/CreateSunTimer"],
	["plant_039_mari_gold", "CreateCoinComponent/CreateCoinTimer"],
	["plant_032_magnet_shroom", "MagnetComponent/AttackCdTimer"],
	["plant_007_chomper", "ChewTimer"],
	["plant_005_potato_mine", "PrepareTimer"],
	["plant_010_sun_shroom", "GrowTimer"],
	["zombie_016_jackbox", "BombComponentJackbox/JackBombTimer"],
]


func _ready() -> void:
	_run.call_deferred()


func _check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", description)


func _run() -> void:
	_scan_scenes("res://scenes")
	if failures == 0:
		game = MAIN.instantiate() as MainGameManager
		game.set_script(ControlledMainGame)
		game.game_para = ResourceLevelData.new()
		Global.game_para = null
		add_child(game)
		for entry in CASES:
			await _test_role(entry[0], entry[1])
		await _test_production()
		await _test_first_attack()
		game.free()
	print("CHARACTER_SPEED_TIMER_TESTS: %d checks, %d failures; %d scenes" % [checks, failures, migrated_scenes.size()])
	get_tree().quit(1 if failures else 0)


## 只选本次八类用途；同名 GardenComponent/CreateCoinTimer 保留普通 Timer。
func _is_target(node: Node) -> bool:
	if node.name in [&"BulletAttackCdTimer", &"CreateSunTimer", &"ChewTimer", &"PrepareTimer", &"GrowTimer", &"JackBombTimer"]:
		return node is Timer
	return node is Timer and ((node.name == &"CreateCoinTimer" and node.get_parent().name == &"CreateCoinComponent") \
		or (node.name == &"AttackCdTimer" and node.get_parent().name == &"MagnetComponent"))


func _scan_scenes(directory: String) -> void:
	for child in DirAccess.get_directories_at(directory):
		_scan_scenes(directory.path_join(child))
	for file in DirAccess.get_files_at(directory):
		if not file.ends_with(".tscn"):
			continue
		var path := directory.path_join(file)
		var content := FileAccess.get_file_as_string(path)
		if not ("BulletAttackCdTimer" in content or "CreateSunTimer" in content or "ChewTimer" in content \
			or "PrepareTimer" in content or "GrowTimer" in content or "JackBombTimer" in content \
			or "CreateCoinComponent" in content or "MagnetComponent" in content):
			continue
		var scene := load(path) as PackedScene
		var root := scene.instantiate()
		var found := false
		for node in root.find_children("*", "Timer", true, false):
			if _is_target(node):
				found = true
				_check(node.has_method("start_scaled"), "%s/%s 使用 SpeedTimer" % [path, root.get_path_to(node)])
		if found:
			migrated_scenes.append(path)
		root.free()


func _actor(name: String) -> Character000Base:
	var folder := "zombie" if name.begins_with("zombie") else "plant"
	var scene := load("res://scenes/character/%s/%s.tscn" % [folder, name]) as PackedScene
	var actor := scene.instantiate() as Character000Base
	actor.lane = 0
	actor.random_speed_range = Vector2.ONE
	# 在父角色 ready 前已有速度因素，子组件初始化不能假定速度永远为 1。
	actor.influence_speed_factors[Character000Base.E_Influence_Speed_Factor.IceDecelerateSpeed] = 0.5
	if actor is Zombie000Base:
		actor.is_walk = false
		actor.sfx_enter_name = &""
	game.add_child(actor)
	return actor


## 真实角色速度信号与真实 Timer 联动，验证连续变速、冻结启动及解除冻结。
func _test_role(name: String, timer_path: String) -> void:
	var actor := _actor(name)
	var timer := actor.get_node(timer_path) as Timer
	_check(is_equal_approx(float(timer.get("speed_scale")), 0.5), name + " 初始化同步已有倍率")
	await get_tree().process_frame
	await get_tree().process_frame
	timer.call("start_scaled", 10.0)
	var remaining := float(timer.call("get_base_time_left"))
	for speed: float in [0.5, 2.0, 0.0, 1.0]:
		actor.update_speed_factor(speed, Character000Base.E_Influence_Speed_Factor.IceDecelerateSpeed)
		_check(is_equal_approx(float(timer.get("speed_scale")), speed), name + " 接收速度 " + str(speed))
		_check(is_equal_approx(float(timer.call("get_base_time_left")), remaining), name + " 连续变速保留进度")
	actor.update_speed_factor(0.0, Character000Base.E_Influence_Speed_Factor.IceDecelerateSpeed)
	timer.call("start_scaled", 8.0)
	await get_tree().create_timer(0.1).timeout
	_check(timer.paused and is_equal_approx(float(timer.call("get_base_time_left")), 8), name + " 零速启动不倒计时")
	actor.update_speed_factor(1.0, Character000Base.E_Influence_Speed_Factor.IceDecelerateSpeed)
	_check(not timer.paused and is_equal_approx(timer.time_left, 8), name + " 恢复后从原进度继续")
	actor.free()


## 生产随机区间保持动作时间，禁用期间变速也必须更新下次启动所用倍率。
func _test_production() -> void:
	for name in ["plant_002_sun_flower", "plant_039_mari_gold"]:
		var actor := _actor(name)
		await get_tree().process_frame
		await get_tree().process_frame
		var component: Node = actor.get_node("CreateSunComponent" if "sun_flower" in name else "CreateCoinComponent")
		var timer := component.get_child(0) as Timer
		component.set("create_time_range_other", Vector2(12, 12))
		actor.update_speed_factor(0.5, Character000Base.E_Influence_Speed_Factor.IceDecelerateSpeed)
		component.call("change_production_interval")
		_check(is_equal_approx(float(timer.get("base_wait_time")), 12) and is_equal_approx(timer.time_left, 24), name + " 随机周期只换算一次")
		component.call("disable_component", ComponentNormBase.E_IsEnableFactor.Sleep)
		actor.update_speed_factor(0.0, Character000Base.E_Influence_Speed_Factor.IceDecelerateSpeed)
		component.call("enable_component", ComponentNormBase.E_IsEnableFactor.Character)
		_check(timer.is_stopped(), name + " 其他禁用因素仍存在时不能启动")
		component.call("enable_component", ComponentNormBase.E_IsEnableFactor.Sleep)
		_check(timer.paused and not timer.is_stopped(), name + " 零速启用保存待生产任务")
		actor.update_speed_factor(1.0, Character000Base.E_Influence_Speed_Factor.IceDecelerateSpeed)
		_check(is_equal_approx(timer.time_left, 12), name + " 解除冻结保持基础周期")
		actor.free()


## 首次随机等待也属于攻击冷却，停攻后不能留下独立 SceneTreeTimer 的迟到回调。
func _test_first_attack() -> void:
	var actor := _actor("plant_001_pea_shooter_single")
	await get_tree().process_frame
	await get_tree().process_frame
	var attack := actor.get_node("AttackComponent") as AttackComponentBulletBase
	var timer := attack.get_node("BulletAttackCdTimer") as Timer
	actor.update_speed_factor(0.0, Character000Base.E_Influence_Speed_Factor.IceFreezeSpeed)
	attack.update_is_attack_factors(true, AttackComponentBase.E_IsAttackFactors.RayEnemy)
	_check(not timer.is_stopped() and timer.paused, "首次攻击等待使用可冻结的 SpeedTimer")
	_check(is_equal_approx(float(timer.get("base_wait_time")), attack.attack_cd), "首次短等待后下一轮使用完整攻击周期")
	attack.attack_end()
	await get_tree().create_timer(0.6).timeout
	_check(timer.is_stopped(), "取消首次等待后没有迟到回调重启攻击")
	actor.free()
