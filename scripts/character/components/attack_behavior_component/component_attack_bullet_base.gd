extends AttackComponentBase
## 发射子弹攻击行为基础组件
class_name AttackComponentBulletBase

@onready var animation_tree: AnimationTree = $"../AnimationTree"
## 冷却时间计时器
@onready var bullet_attack_cd_timer: Timer = $BulletAttackCdTimer

## 用检测组件对应的值赋值，仙人掌会修改值更新子弹属性
## 当前发射子弹可以攻击的敌人状态
##("1 正常", "2 悬浮", "4 地刺", "8 低矮")
var can_attack_plant_status:int = 1
##("1 正常", "2 跳跃", "4 水下", "8 空中", "16 地下")
var can_attack_zombie_status:int = 1
## 是否使用行属性进行攻击判断
var is_lane:=true

## 攻击参数,动画攻击一次的参数
@export var attack_para:StringName= &"parameters/OneShot/request"
### TODO:子弹攻击伤害(为正数时可以给子弹赋值,默认为子弹攻击力)
#@export var attack_value_bullet:int = -1
@export var attack_cd:float = 1.5
## 攻击子弹类型
@export var attack_bullet_type:EnumsBullet.BulletType = EnumsBullet.BulletType.Bullet001Pea
## 子弹生产位置
@export var markers_2d_bullet: Array[Marker2D]
@export_group("发射子弹音效")
## 攻击音效名字（发射子弹）
@export var attack_sfx:StringName = &"Throw"

## 发射一次子弹信号
signal signal_shoot_bullet

## 主游戏场景子弹父节点
var bullets: Node2D
func _ready() -> void:
	super()
	bullet_attack_cd_timer.wait_time = attack_cd
	if is_instance_valid(Global.main_game):
		bullets = Global.main_game.bullets
	## 用检测组件对应的值赋值，仙人掌会修改值更新子弹属性
	can_attack_plant_status = detect_component.can_attack_plant_status
	##("1 正常", "2 跳跃", "4 水下", "8 空中", "16 地下")
	can_attack_zombie_status = detect_component.can_attack_zombie_status
	## 是否使用行属性进行攻击判断
	is_lane = detect_component.is_lane


## 角色速度修改
func owner_update_speed(speed_product:float):
	if not bullet_attack_cd_timer.is_stopped():
		if speed_product == 0:
			bullet_attack_cd_timer.paused = true
		else:
			bullet_attack_cd_timer.paused = false

			bullet_attack_cd_timer.start(bullet_attack_cd_timer.time_left / speed_product)

	bullet_attack_cd_timer.wait_time = attack_cd / speed_product

## 开始攻击
func attack_start():
	super()
	## 先随机等待一段时间调用一次攻击
	await get_tree().create_timer(randf_range(0, bullet_attack_cd_timer.wait_time/3)).timeout
	if is_attack_res:
		## 首次攻击还未使用计时器循环攻击
		if bullet_attack_cd_timer.is_stopped():
			_on_bullet_attack_cd_timer_timeout()
			bullet_attack_cd_timer.start()
	## 等待一段时间后可能为非攻击状态
	else:
		attack_end()

## 结束攻击
func attack_end():
	super()
	bullet_attack_cd_timer.stop()
	set_cancel_attack()


## 攻击间隔后触发执行攻击
func _on_bullet_attack_cd_timer_timeout() -> void:
	# 在这里调用实际攻击逻辑
	animation_tree.set(attack_para, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func set_cancel_attack():
	#animation_tree.set(attack_para, AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	pass

## 发射子弹（动画调用）
func _shoot_bullet():
	signal_shoot_bullet.emit()
	for i in range(markers_2d_bullet.size()):
		var bullet:Bullet000Base = Global.bullet_registry.get_bullet_scenes(attack_bullet_type).instantiate()
		var bullet_paras = get_bullet_paras(markers_2d_bullet[i].global_position, detect_component.ray_area_direction[i])
		#print(bullet_paras)
		bullet.init_bullet(bullet_paras)
		bullets.add_child(bullet)
		play_throw_sfx()


func get_bullet_paras(marker_2d_bullet_glo_pos:Vector2, ray_direction:Vector2) -> Dictionary[Bullet000Base.E_InitParasAttr,Variant]:
	return {
		Bullet000Base.E_InitParasAttr.IsActivateLane : is_lane,
		Bullet000Base.E_InitParasAttr.BulletLane : owner.lane,
		Bullet000Base.E_InitParasAttr.Position : bullets.to_local(marker_2d_bullet_glo_pos),
		Bullet000Base.E_InitParasAttr.Direction : ray_direction,
		Bullet000Base.E_InitParasAttr.CanAttackPlantState : can_attack_plant_status,
		Bullet000Base.E_InitParasAttr.CanAttackZombieState : can_attack_zombie_status,
	}


func play_throw_sfx():
	## 播放音效
	SoundManager.play_character_SFX(attack_sfx)
