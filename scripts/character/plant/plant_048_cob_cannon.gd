extends Plant000Base
class_name Plant048CobCannon

## 前轮的植物格子
var plant_cell_next:PlantCell

## 加农炮子弹,设置其明暗交替
@onready var cob_cannon_cob: Sprite2D = $Body/BodyCorrect/CobCannon_cob
@onready var area_2d_mouse: Area2D = $Body/Area2DMouse

## 瞄准准星
@onready var cob_cannon_target: CobCannonTarget = $CobCannonTarget
## 子弹位置
@onready var marker_2d_bullet: Marker2D = $Body/BodyCorrect/Marker2DBullet

## 目标位置
var attack_target_global_pos:Vector2

## 充能cd
@export var charge_cd:float = 35
var charge_cd_timer:Timer

@export_group("动画状态")
## 是否有子弹
@export var is_bullet:= true
## 是否攻击
@export var is_attack:= false
## 是否充能
@export var is_charge := false

func ready_norm():
	super()
	cob_cannon_bright_dark()

	## 玉米加农炮种植时删除前轮的植物格子的玉米投手,同时更新前轮的植物格子的数据
	plant_cell_next = Global.main_game.plant_cell_manager.all_plant_cells[row_col.x][row_col.y+1]
	if is_instance_valid(plant_cell_next.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm]):
		plant_cell_next.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm].character_death_disappear()
	plant_cell_next.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm] = self
	signal_character_death.connect(plant_cell_next.one_plant_free.bind(self))


	charge_cd_timer = Timer.new()
	charge_cd_timer.wait_time = charge_cd
	charge_cd_timer.one_shot = false
	charge_cd_timer.autostart = false
	add_child(charge_cd_timer)
	# 连接超时信号
	charge_cd_timer.timeout.connect(_on_charge_cd_timer_timeout)

	area_2d_mouse.visible = true

func cob_cannon_bright_dark():
	# 你希望变到的 “暗” 颜色或透明度
	var bright_modulate: Color = Color(1.5, 1.5, 1.5)
	var dark_modulate: Color = Color(0.6, 0.6, 0.6)

	var tween: Tween
	# 创建并添加 Tween
	tween = create_tween()
	# 设置循环播放（往返）
	tween.set_loops()
	# Tween 属性：从 bright_modulate 到 dark_modulate，用时 1 秒
	tween.tween_property(cob_cannon_cob, "modulate", dark_modulate, 0.5)
	# 然后从 dark_modulate 回到 bright_modulate，用时 1 秒
	tween.tween_property(cob_cannon_cob, "modulate", bright_modulate, 0.5)


func _on_charge_cd_timer_timeout():
	is_charge = true

## 初始化正常出战角色信号连接
func ready_norm_signal_connect():
	super()
	cob_cannon_target.signal_cannon_fire.connect(attack_start)

## 开始攻击,获取攻击位置
func attack_start(target_global_pos:Vector2):
	self.attack_target_global_pos = target_global_pos
	is_bullet = false
	is_attack = true
	is_charge = false
	charge_cd_timer.start()

## 发射子弹
func shoot_bullet():
	is_attack = false

	var bullet_cob_cannon :Bullet016CobCannon =  Global.bullet_registry.get_bullet_scenes(EnumsBullet.BulletType.Bullet016CobCannon).instantiate()
	bullet_cob_cannon.init_cannon(attack_target_global_pos)
	Global.main_game.bullets.add_child(bullet_cob_cannon)
	bullet_cob_cannon.global_position = marker_2d_bullet.global_position

	SoundManager.play_character_SFX("coblaunch")

## 充能完毕
func charge_end():
	is_bullet = true

#region 鼠标交互
func _on_area_2d_mouse_entered() -> void:
	if is_bullet:
		body.body_light_and_dark()


func _on_area_2d_mouse_exited() -> void:
	body.body_light_and_dark_end()


@warning_ignore("unused_parameter")
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	## 有子弹时左键点击,准备发射
	if is_bullet and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cob_cannon_target.activate_it()
#endregion
