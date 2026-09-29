## 博士共享动画标识；状态和动画控制器共同引用，不相互依赖常量定义。
extends RefCounted
class_name ZB001DoctorAnimations

## 主体入场动画名；必须非循环，播放结束后进入普通待机。
const ENTER_ANIMATION: StringName = &"Zombie_boss_enter"
## 主体普通待机动画名；必须循环播放，技能选择由待机计时器触发。
const IDLE_ANIMATION: StringName = &"Zombie_boss_idle"
## 主体低头动画名；第 2 秒开启受击，播放到位后进入吐球前待机。
const HEAD_ENTER_ANIMATION: StringName = &"Zombie_boss_head_enter"
## 吐球前后共用的低头循环动画；两段等待分别由自己的 SpeedTimer 控制。
const HEAD_IDLE_ANIMATION: StringName = &"Zombie_boss_head_idle"
## 主体抬头收尾动画名；第 0.6667 秒关闭受击，完成后结束本轮低头技能。
const HEAD_LEAVE_ANIMATION: StringName = &"Zombie_boss_head_leave"
## 主体死亡动画名；其中的方法关键帧负责请求生成奖杯。
const DEATH_ANIMATION: StringName = &"Zombie_boss_death"
## 驾驶舱博士的单次死亡动画，启动时机由机甲死亡动画的方法关键帧决定。
const DRIVER_DEATH_ANIMATION: StringName = &"Zombie_Boss_driver_death"
## 本体死亡动作结束后播放一次的举旗动画。
const DRIVER_FLAG_ANIMATION: StringName = &"Zombie_Boss_driver_flag"
## 本体举旗后的最终循环动作，持续到死亡保留时间及淡出结束。
const DRIVER_FLAG_LOOP_ANIMATION: StringName = &"Zombie_Boss_driver_flag_loop"
## 驾驶员默认循环动作；单次操纵和吐球动作结束后回到此动画。
const DRIVER_IDLE_ANIMATION: StringName = &"Zombie_Boss_driver_idle"
## 机甲开始一段动画时播放一次的驾驶员操纵动作。
const DRIVER_DRIVE_ANIMATION: StringName = &"Zombie_Boss_driver_drive"
## 机甲播放吐球动作时使用的驾驶员单次动作，优先于普通操纵动作。
const DRIVER_DAMAGE_ANIMATION: StringName = &"Zombie_Boss_driver_damage"
