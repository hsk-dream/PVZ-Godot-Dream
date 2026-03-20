extends Zombie000Base
class_name Zombie024Gargantuar

## 小鬼的头,用于投掷小鬼时定位
@onready var zombie_imp_head: Sprite2D = $Body/BodyCorrect/Imp1/Zombie_imp_head

@export_group("投掷小鬼相关")
## body中的小鬼节点和灰烬中的小鬼节点,小鬼抛出时隐藏
@export var body_imp:Array[Node2D]
@export_subgroup("数值")
## 丢小鬼的巨人位置的最小x值,位置小于该值时,不在丢小鬼
@export var MinXThrowGargantuar:float = 400
"""
巨人投掷200像素
限制在投掷范围内
然后上下波动50
"""
## 小鬼投掷的范围
@export var RangeXImpThrow:Vector2 = Vector2(200, 360)
## 巨人投掷的距离
@export var XThrow:float = 350
## 投掷波动范围
@export var RangeRandomXThrow:Vector2 = Vector2(-50, 50)
## 小鬼投掷的全局位置
var glo_pos_imp_be_thrown :Vector2

@export_group("动画状态")
## 是否扔小鬼
@export var is_throw := false
## 是否扔过小鬼,辅助判断避免重复丢小鬼
var is_throw_once := false


## 初始化正常出战角色信号连接
func ready_norm_signal_connect():
	super()
	## 血量状态变化组件
	hp_component.signal_hp_loss.connect(jugde_throw_imp_form_hp_change)


## 血量变化判断是否丢小鬼
func jugde_throw_imp_form_hp_change(curr_hp:int, _is_drop:=true):
	if not is_throw_once and global_position.x>MinXThrowGargantuar and curr_hp <= 1500:
		is_throw_once = true
		is_throw = true

## 扔出小鬼,动画调用
func throw_out_imp():
	for n in body_imp:
		n.visible = false
	is_throw = false

	if not is_death:
		create_imp()

func create_imp():
	var zombie_init_para:Dictionary = {
		Zombie000Base.E_ZInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsNorm,
		Zombie000Base.E_ZInitAttr.Lane:lane,
		Zombie000Base.E_ZInitAttr.IsMiniZombie: is_mini_zombie,
		Zombie000Base.E_ZInitAttr.IsPotZombie: is_pot_zombie,
	}
	Global.main_game.zombie_manager.create_norm_zombie(
		EnumsCharacter.ZombieType.Z025Imp,
		Global.main_game.zombie_manager.all_zombie_rows[lane],
		zombie_init_para,
		_get_imp_throw_glo_pos(),
		update_imp_throw_pos
	)

## 获取投掷小鬼的目标位置
func _get_imp_throw_glo_pos()->Vector2:
	var target_x_imp_throw = clamp(global_position.x - XThrow, RangeXImpThrow.x, RangeXImpThrow.y)
	var target_x_imp_throw_res = target_x_imp_throw + randf_range(RangeRandomXThrow.x, RangeRandomXThrow.y)
	#prints("全局位置:", global_position.x, "投掷位置:", target_x_imp_throw, "随机位置:", target_x_imp_throw_res)
	glo_pos_imp_be_thrown = Vector2(target_x_imp_throw_res, Global.main_game.zombie_manager.all_zombie_rows[lane].zombie_create_position.global_position.y)
	return glo_pos_imp_be_thrown
	#Vector2(target_x_imp_throw_res - Global.main_game.zombie_manager.all_zombie_rows[lane].global_position.x, \
	#Global.main_game.zombie_manager.all_zombie_rows[lane].zombie_create_position.position.y)

## 更新投掷小鬼的位置
func update_imp_throw_pos(zombie_imp:Zombie025Imp):
	zombie_imp.is_thrown = true
	zombie_imp.target_pos_anim_head_to_body = zombie_imp_head.global_position - glo_pos_imp_be_thrown
	print("位置:", zombie_imp.target_pos_anim_head_to_body)


## 压扁地刺时被地刺反击无效果
func be_caltrop():
	pass

## 死亡时播放音效,动画调用
func play_gargantuar_death_sfx():
	SoundManager.play_character_SFX(&"gargantudeath")
