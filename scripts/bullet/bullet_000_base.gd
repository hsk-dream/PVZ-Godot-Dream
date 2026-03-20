extends Node2D
class_name Bullet000Base

@onready var bullet_shadow: Sprite2D = $BulletShadow
@onready var area_2d_attack: Area2D = $Area2DAttack

## 子弹击中特效
@onready var bullet_effect: BulletEffect000Base = $BulletEffect
## 子弹本体节点
@onready var body: Node2D = $Body
@export var bullet_type:EnumsBullet.BulletType
## 子弹基类
@export_group("子弹基础属性")
## 子弹阵营
@export var bullet_camp:EnumsCharacter.CharacterType = EnumsCharacter.CharacterType.Plant
## 子弹是否旋转
@export var is_rotate := false
## 最大攻击次数(-1表示可以无限攻击)
@export var max_attack_num:=1
## 当前攻击次数
var curr_attack_num:=0
## 子弹伤害
@export var attack_value := 20
## 子弹默认移动速度
@export var speed: float = 300.0
## 子弹默认移动方向
@export var direction: Vector2 = Vector2.RIGHT
## 子弹伤害模式：普通，穿透，真实
@export var bullet_mode : EnumsBullet.AttackMode
## 子弹移动离出生点最大距离，超过自动销毁
@export var max_distance := 2000.0
## 子弹初始位置
var start_pos: Vector2
## 默认是否激活行属性，激活后只能攻击本行的僵尸
@export var default_is_activate_lane:=true
var is_activate_lane:bool
## 子弹行属性
var lane :int = -1
@export_subgroup("子弹音效相关")
## 是否触发受击音效(火焰豌豆就不触发)
@export var trigger_be_attack_sfx := true
## 子弹本身音效
@export var type_bullet_SFX :SoundManagerClass.TypeBulletSFX =  SoundManagerClass.TypeBulletSFX.Pea


@export_group("子弹攻击相关")
## 可以攻击的敌人状态
@export_flags("1 正常", "2 悬浮", "4 地刺", "8 低矮植物") var can_attack_plant_status:int = 1
@export_flags("1 正常", "2 跳跃", "4 水下", "8 空中", "16 地下") var can_attack_zombie_status:int = 1

@export_group("子弹升级相关")
## 是否可以升级子弹
@export var is_can_up:=false

func _ready() -> void:
	body.rotation = direction.angle()

	if is_rotate:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(body, "rotation", TAU, 1.0).as_relative()

## 子弹初始化参数种类
enum E_InitParasAttr{
	IsActivateLane,		## 是否激活行属性
	BulletLane, 		## 子弹所在行
	Position,			## 子弹起始位置
	Direction,			## 子弹起始方向
	CanAttackPlantState,	## 子弹可以攻击的敌人(植物)状态
	CanAttackZombieState,	## 子弹可以攻击的敌人(僵尸)状态

	## 抛物线子弹\追踪子弹额外属性
	Enemy,				## 子弹选中的敌人
	EnemyGloPos,		## 敌人位置(发射子弹时敌人若已经消失,抛物线依旧可以攻击)

}

## 初始化子弹属性
func init_bullet(bullet_paras:Dictionary):
	## 子弹行
	self.is_activate_lane = bullet_paras.get(E_InitParasAttr.IsActivateLane, default_is_activate_lane)
	self.lane = bullet_paras.get(E_InitParasAttr.BulletLane, -1)
	z_index = self.lane * 50 + 45

	self.start_pos = bullet_paras.get(E_InitParasAttr.Position, Vector2.ZERO)
	position = self.start_pos

	self.direction = bullet_paras.get(E_InitParasAttr.Direction, Vector2.RIGHT)
	self.can_attack_plant_status = bullet_paras.get(E_InitParasAttr.CanAttackPlantState, can_attack_plant_status)
	self.can_attack_zombie_status = bullet_paras.get(E_InitParasAttr.CanAttackZombieState, can_attack_zombie_status)


## 获取子弹属性
func get_bullet_paras()->Dictionary[E_InitParasAttr,Variant]:
	return {
		E_InitParasAttr.IsActivateLane : self.is_activate_lane,
		E_InitParasAttr.BulletLane : self.lane,
		E_InitParasAttr.Position : position,
		E_InitParasAttr.Direction : self.direction,
		E_InitParasAttr.CanAttackPlantState : self.can_attack_plant_status,
		E_InitParasAttr.CanAttackZombieState : self.can_attack_zombie_status,
	}

## 子弹与敌人碰撞
func _on_area_2d_attack_area_entered(area: Area2D) -> void:
	var enemy:Character000Base = area.owner
	## TODO:攻击植物子弹
	if enemy is Plant000Base:
		## 子弹阵营为植物
		if bullet_camp == EnumsCharacter.CharacterType.Plant:
			return
		if not enemy.curr_be_attack_status & can_attack_plant_status:
			return
	elif enemy is Zombie000Base:
		## 子弹阵营为植物
		if bullet_camp == EnumsCharacter.CharacterType.Zombie:
			return
		## 如果不是可攻击状态敌人
		if not enemy.curr_be_attack_status & can_attack_zombie_status:
			#print("敌人状态：", enemy.curr_be_attack_status, "可以攻击敌人状态：", can_attack_zombie_status)
			return
	else:
		push_error("敌人不是植物,不是僵尸")
	## 子弹没有攻击次数
	if max_attack_num != -1 and curr_attack_num >= max_attack_num:
		return

	## 如果子弹有行属性
	if is_activate_lane:
		if lane == enemy.lane:
			attack_once(enemy)
	else:
		attack_once(enemy)


## 对敌人造成伤害
func _attack_enemy(enemy:Character000Base):
	if enemy is Zombie000Base:
		_attack_zombie(enemy)
	elif enemy is Plant000Base:
		_attack_plant(enemy)

## 对僵尸敌人造成伤害,直线类子弹重写
func _attack_zombie(zombie:Zombie000Base):
	## 攻击敌人
	zombie.be_attacked_bullet(attack_value, bullet_mode, true, trigger_be_attack_sfx)


## 对植物敌人造成伤害
func _attack_plant(plant:Plant000Base):
	plant = get_first_be_hit_plant_in_cell(plant)
	## 攻击敌人
	plant.be_attacked_bullet(attack_value, bullet_mode, true, trigger_be_attack_sfx)


## 直线子弹先对壳类进行攻击
## 抛物线子弹先对Norm进行攻击
func get_first_be_hit_plant_in_cell(plant:Plant000Base)->Plant000Base:
	return plant

## 攻击一次
func attack_once(enemy:Character000Base):
	curr_attack_num += 1
	if max_attack_num != -1 and curr_attack_num > max_attack_num:
		return
	## 对敌人造成伤害
	_attack_enemy(enemy)
	## 是否有音效
	if type_bullet_SFX != SoundManagerClass.TypeBulletSFX.Null:
		SoundManager.play_bullet_attack_SFX(type_bullet_SFX)
	## 如果有子弹特效
	if bullet_effect.is_bullet_effect:
		if enemy is Character000Base:
			bullet_effect.global_position.x = enemy.hurt_box_component.global_position.x
		bullet_effect.activate_bullet_effect()

	## 判断是否进入删除队列
	if max_attack_num != -1 and curr_attack_num >= max_attack_num:
		queue_free()
