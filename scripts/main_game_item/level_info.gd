## 管理关卡轮次与进度显示，在自然波次进度和僵王血量之间切换。
extends Control
class_name LevelInfo

## 多轮关卡的轮次文字，不参与波次进度与僵王血条的切换。
@onready var round_label: Label = $RoundLabel
## 原波次进度条的显示容器；隐藏父节点可阻止后续首波逻辑重新显示子进度条。
@onready var wave_progress_root: Control = $WaveProgressRoot
## 独立僵王血条，负责血量信号绑定与平滑显示。
@onready var boss_hp_progress_bar: BossHpProgressBar = $BossHpProgressBar

## [param curr_round] 当前关卡轮次；更新文字并显示轮次标签。
func set_round(curr_round:int):
	round_label.text = "当前为第" + str(curr_round) + "轮"
	round_label.visible = true


## [param boss] 已完成初始化的僵王；绑定成功后替换原位置的波次进度显示。
func show_boss_progress(boss: ZB000Base) -> void:
	if not boss_hp_progress_bar.bind_boss(boss):
		return
	wave_progress_root.hide()
	boss_hp_progress_bar.show()


## [param keep_depleted] Boss 模式死亡后保留 100% 击败进度，直到关卡退出。
## [param restore_wave] 普通模式且仍在战斗时恢复波次容器，子进度条保留原有显隐状态。
func finish_boss_progress(keep_depleted: bool, restore_wave: bool) -> void:
	boss_hp_progress_bar.show_depleted()
	boss_hp_progress_bar.visible = keep_depleted
	wave_progress_root.visible = restore_wave and not keep_depleted


## [param keep_depleted] 已死亡的 Boss 离树时保留 100% 击败进度，不再依赖角色引用。
## [param restore_wave] 普通模式的角色离树时，仅在战斗仍继续的情况下恢复波次容器。
func clear_boss_progress(keep_depleted: bool, restore_wave: bool) -> void:
	boss_hp_progress_bar.unbind_boss()
	if keep_depleted:
		boss_hp_progress_bar.show_depleted()
	boss_hp_progress_bar.visible = keep_depleted
	wave_progress_root.visible = restore_wave and not keep_depleted
