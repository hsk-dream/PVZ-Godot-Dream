extends Plant000Base
class_name Plant024TallNut

@onready var hp_stage_change_component: HpStageChangeComponent = $HpStageChangeComponent

func ready_norm_signal_connect():
	super()
	## 连接信号
	hp_component.signal_hp_loss.connect(hp_stage_change_component.judge_body_change)

## [param area] 进入阻跳范围的区域；仅普通僵尸具有跳跃阻挡属性，僵王和非角色区域直接跳过。
func _on_area_2d_stop_jump_area_entered(area: Area2D) -> void:
	# 安全转换，避免僵王受击框进入范围时被强制赋给普通僵尸类型。
	var zombie := area.owner as Zombie000Base
	if not is_instance_valid(zombie) or zombie.is_death or zombie.is_queued_for_deletion():
		return
	if zombie.lane == lane and zombie.is_trigger_tall_nut_stop_jump:
		zombie.jump_be_stop(self)

