extends ComponentNormBase
class_name CreateSunComponent

## 生产阳光计时器
@onready var create_sun_timer: SpeedTimer = $CreateSunTimer
## 身体, 控制发光
@onready var body: BodyCharacter = %Body


## 生产阳光价值
@export var sun_value := 25
## 生产光位置
@export var marker_2d_create_sun: Marker2D
## 生产阳光的个数
@export var num_create_sun:int=1
@export_group("生产间隔时间")
## 第一个阳光生产时间范围
@export var create_time_range_first:Vector2 = Vector2(3, 12.5)
## 后续生产阳光的时间范围
@export var create_time_range_other:Vector2 = Vector2(23.5,25)
## 阳光生产间隔，始终保存正常速度下的动作时间。
var create_interval :float
## 创建阳光时的发光颜色
var create_sun_color: Color = Color(1, 1, 1)


#region 我是僵尸模式
@export_group("我是僵尸模式")
## 剩余的阳光数量
@export var remaining_sun_on_zombie_mode := 8
## 被攻击一次生产一个阳光
func _on_be_eat_once():
	if remaining_sun_on_zombie_mode > 0:
		remaining_sun_on_zombie_mode -= 1
		_spawn_sun()

## 当角色死亡时
func _on_character_death():
	if remaining_sun_on_zombie_mode > 0:
		for i in range(remaining_sun_on_zombie_mode):
			_spawn_sun()
		remaining_sun_on_zombie_mode = 0

#endregion
func _ready() -> void:
	# 随机区间不包含速度；禁用或展示状态也先保存周期与倍率，供后续启用使用。
	create_interval = randf_range(create_time_range_first.x, create_time_range_first.y)
	create_sun_timer.base_wait_time = create_interval
	owner_update_speed(GlobalUtils.get_dic_product(owner.influence_speed_factors))
	if not get_tree().current_scene is MainGameManager:
		return
	create_sun_timer.start_scaled()

	EventBus.subscribe("main_game_progress_update", _on_main_game_progress_update)

## 主游戏进程改变时,修改生产阳光组件
func _on_main_game_progress_update(curr_main_game_progress:MainGameManager.E_MainGameProgress):
	if curr_main_game_progress == MainGameManager.E_MainGameProgress.MAIN_GAME:
		enable_component(E_IsEnableFactor.MainGameProgress)
	else:
		disable_component(E_IsEnableFactor.MainGameProgress)

## 启用组件
func enable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)
	if is_enabling:
		create_sun_timer.start_scaled()

## 禁用组件
func disable_component(is_enable_factor:E_IsEnableFactor):
	super(is_enable_factor)
	if not is_enabling:
		create_sun_timer.stop()

## 禁用期间同样同步倍率，零速下重新启用时应保存任务但不开始扣减。
func owner_update_speed(speed_product:float):
	create_sun_timer.set_speed_scale(speed_product)


## 生产阳光后、改变阳光生产时间，重新启动计时器
func change_production_interval():
	create_interval = randf_range(create_time_range_other.x, create_time_range_other.y)
	create_sun_timer.start_scaled(create_interval)


## 创建阳光
func _spawn_sun():
	## 播放音效
	SoundManager.play_character_SFX(&"Throw1")
	for i in range(num_create_sun):
		var new_sun:Sun = SceneRegistry.SUN.instantiate()
		new_sun.init_sun(sun_value, Global.main_game.suns.to_local(marker_2d_create_sun.global_position))
		Global.main_game.suns.add_child(new_sun)

		# 控制阳光下落
		var tween = new_sun.create_tween()
		var center_y : float = -15
		var target_y : float = 45
		tween.tween_property(new_sun, "position:y", center_y, 0.3).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(new_sun, "position:y", target_y, 0.6).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		new_sun.spawn_sun_tween = get_tree().create_tween()
		new_sun.spawn_sun_tween.set_parallel()
		new_sun.spawn_sun_tween.tween_subtween(tween)
		new_sun.spawn_sun_tween.tween_property(new_sun, "position:x", randf_range(-30, 30), 0.9).as_relative()

		new_sun.spawn_sun_tween.finished.connect(new_sun.on_sun_tween_finished)


## 创建阳光全流程：身体发光、生产阳光、身体不发光
func create_sun():
	# 创建新的 tween
	var tween = create_tween()
	tween.tween_method(func(val): body.set_other_color(BodyCharacter.E_ChangeColors.CreateSunColor, val), Color(1, 1, 1), Color(2, 2, 2), 0.5)
	# 在第一个 tween 完成后、第二个 tween 开始前调用函数
	tween.tween_callback(Callable(self, "_spawn_sun"))
	tween.tween_method(func(val): body.set_other_color(BodyCharacter.E_ChangeColors.CreateSunColor, val), Color(2, 2, 2), Color(1, 1, 1), 0.5)


func _on_create_sun_timer_timeout() -> void:
	create_sun()
	change_production_interval()

## 改变阳光生产价值
func change_sun_value(new_sun_value:int):
	self.sun_value = new_sun_value
