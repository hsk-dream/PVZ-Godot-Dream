extends AttackComponentBase
## 发射子弹攻击行为基础组件
class_name AttackComponentBulletBase

@onready var animation_tree: AnimationTree = $"../AnimationTree"
## 冷却时间计时器
@onready var bullet_attack_cd_timer: SpeedTimer = $BulletAttackCdTimer

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
@export var attack_bullet_type:BulletRegistry.BulletType = BulletRegistry.BulletType.Bullet001Pea
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
	# 基础周期不含倍率；同步已有速度因素，避免等待下一次速度信号才生效。
	bullet_attack_cd_timer.base_wait_time = attack_cd
	owner_update_speed(GlobalUtils.get_dic_product(owner.influence_speed_factors))
	if is_instance_valid(Global.main_game):
		bullets = Global.main_game.bullets
	## 用检测组件对应的值赋值，仙人掌会修改值更新子弹属性
	can_attack_plant_status = detect_component.can_attack_plant_status
	##("1 正常", "2 跳跃", "4 水下", "8 空中", "16 地下")
	can_attack_zombie_status = detect_component.can_attack_zombie_status
	## 是否使用行属性进行攻击判断
	is_lane = detect_component.is_lane


## SpeedTimer 保留当前进度并处理零速，调用方不再换算剩余时间或修改 paused。
func owner_update_speed(speed_product:float):
	bullet_attack_cd_timer.set_speed_scale(speed_product)

## 开始攻击
func attack_start():
	super()
	# 首次随机等待也使用同一个可变速计时器，停攻会一起取消，避免旧协程迟到重启攻击。
	if bullet_attack_cd_timer.is_stopped():
		bullet_attack_cd_timer.start_scaled(maxf(randf_range(0, attack_cd / 3.0), 0.001))
		# 仅第一轮使用短等待；修改基础周期不会重置当前进度，之后原生循环使用完整冷却。
		bullet_attack_cd_timer.base_wait_time = attack_cd

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


func get_bullet_paras(marker_2d_bullet_glo_pos:Vector2, ray_direction:Vector2) -> Dictionary[Bullet000NormBase.E_InitParasAttr,Variant]:
	return {
		Bullet000NormBase.E_InitParasAttr.IsActivateLane : is_lane,
		Bullet000NormBase.E_InitParasAttr.BulletLane : owner.lane,
		Bullet000NormBase.E_InitParasAttr.Position : bullets.to_local(marker_2d_bullet_glo_pos),
		Bullet000NormBase.E_InitParasAttr.Direction : ray_direction,
		Bullet000NormBase.E_InitParasAttr.CanAttackPlantState : can_attack_plant_status,
		Bullet000NormBase.E_InitParasAttr.CanAttackZombieState : can_attack_zombie_status,
	}


func play_throw_sfx():
	## 播放音效
	SoundManager.play_character_SFX(attack_sfx)
