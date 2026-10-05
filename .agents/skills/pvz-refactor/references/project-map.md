# 项目入口与重构契约

所有路径相对包含 project.godot 的项目根目录。按任务选择下面的入口，重新读当前源码和实际绑定；这些现状不是禁止演进的架构规范。

## 全局服务与关卡

| 范围 | 检查入口 | 需要核对 |
| --- | --- | --- |
| 启动与 Autoload | project.godot；scenes/main/01StartMenu.tscn；scenes/autoload/global.tscn；scripts/autoload/global/global.gd | 入口 UID、Autoload 名称与次序、Global 子服务的唯一节点绑定。 |
| 用户与持久化 | scripts/autoload/global/user_manager.gd、save_service.gd、config_service.gd | 用户选择、存档路径与默认语义、配置变更信号、自动保存生命周期。 |
| 运行状态与只读数据 | scripts/autoload/global/global_game_state.gd、global_read_data.gd | 状态所有者、金币通知、角色白名单与当前关卡状态；不要将持久化 IO 搬进 UI。 |
| 注册与场景路由 | scripts/autoload/global/character_registry.gd、bullet_registry.gd、main_scene_registry.gd；scripts/autoload/scene_registry.gd | 类型数字、场景映射和动态注册的实际机制；SceneRegistry 是独立 Autoload。 |
| 主游戏与管理器 | scripts/manager/main_game_manager.gd、main_game_sub_manager.gd；scenes/main/MainGame00Base.tscn、MainGame01Front.tscn、MainGame02Back.tscn、MainGame03Roof.tscn | 入树/就绪/离树顺序，管理器依赖，前院/后院/屋顶的继承覆盖。 |
| 关卡配置与自定义选关 | scripts/resources/level/level_data.gd；scripts/consts/const_level_data.gd；resources/level_date_resource/；scripts/choose_level/06_custom_chooes_level.gd | Resource 导出属性、游戏模式、场地、波次、关卡标识和目录扫描。 |
| 跨场景事件与暂停 | scripts/autoload/event_bus.gd、tree_pause_manager.gd | 字符串事件名、payload 顺序、同步/延迟分发和订阅清理；多原因暂停的合成。 |

业务/UI 通过 Global 公开引用访问其服务，不直接 get_node/% 访问 Global 内部子节点。当前启动先加载用户名，再载入该用户存档和配置，最后开启自动保存；搬动初始化逻辑前核对每个依赖的就绪时机。

MainGameManager 在 _enter_tree 注入 Global.main_game 与 game_para，在 _ready 初始化参数并按依赖初始化各管理器；离树清理只针对仍指向自身的全局引用。不要将这些步骤统一搬到一个回调而忽略时序。

CharacterRegistry 管角色与种植条件，BulletRegistry 管子弹，MainSceneRegistry 管主场景，SceneRegistry 管辅助场景/特效。ItemRegistry 当前只是空类，不能假定它已经拥有道具业务。

## 角色、组件、子弹与僵王

| 范围 | 检查入口 | 需要核对 |
| --- | --- | --- |
| 通用角色与组件 | scripts/character/character_000_base.gd；scripts/character/plant/plant_000_base.gd；scripts/character/zombie/zombie_000_base.gd；scripts/character/components/ | 初始化类型、owner 归属、角色信号编排、HP/死亡入口、启用与速度因素。 |
| 种植与刷怪 | scripts/manager/plant_cell_manager/；scripts/main_game_item/plant_cell.gd；scripts/manager/zombie_manager/ | 格子占用、植物层位、行类型、生成前参数和信号、登记与移除。 |
| 子弹 | scripts/bullet/；scripts/bullet/component/movement/；scenes/bullet/；docs/子弹说明文档.md | 基类与场景继承、初始化参数、运动调度、目标过滤、重复命中和销毁。 |
| 状态机 | scripts/state_machine/base/character_state_machine.gd、character_state.gd、character_composite_state.gd、animation_method_query.gd | 注入、启动、延迟切换、嵌套驱动、动画事件和退出清理。 |
| 倍率与计时 | scripts/util/speed_timer.gd；Character000Base 的速度因素；TreePauseManager | 基础动作秒数、独立角色倍率、Engine.time_scale、零速及业务暂停。 |
| 僵王博士 | scripts/character/zombie_boss/001_doctor/；scripts/state_machine/zombie_boss/001_doctor/；resources/zombie_boss/001_doctor/；scenes/character/zombie_boss/zombie_boss_001_doctor.tscn | 根节点/控制器/状态/技能/配置职责、受击窗口、目标锁定、动作事件与死亡奖杯。 |

- 角色的实际就绪钩子为 ready_norm、ready_show、ready_garden。从创建者核对 init 参数在 add_child 前后的注入顺序，尤其追踪子弹在 _ready 使用 init_bullet 注入的全局检测组件。
- 跨角色组件的主要信号由角色根编排。追踪连接、断开、重复入树与已释放目标，不只移动函数正文。
- 正常战斗角色通过 HP 与死亡流程退场；不能用裸 queue_free 替代伤害、掉落、战斗登记和死亡表现。临时特效或无效未入树实例按其自身生命周期处理。
- ComponentNormBase 按多个原因合成启用状态；角色倍率也按因素合成。解除一个原因不能覆盖其他禁用、冻结或减速原因。
- SpeedTimer 用 start_scaled 启动，用 get_base_time_left 读基础剩余时间，用 manual_paused 表示业务暂停；Engine.time_scale 不在组件内重复换算。解除冻结的计时器不能被同一个零速信号冻结。
- CharacterStateMachine 显式 initialize/start，change_state 提交下个更新周期的请求；子状态机 externally_driven 由父状态驱动。保持一次更新、一次事件分发和一次退出清理。
- 普通子弹根节点调度 MovementComponent；特殊玉米炮仅继承 Bullet000Base，使用 init_cannon，不能强行并入标准子弹管线。
- 僵王现有边界：根节点做初始化与角色通知；控制器做动画/姿势；状态控制流程；技能执行效果；配置 Resource 存放参数。共享配置保持只读，权重、候选与执行次数等运行态属于技能实例。

## 场景与资源契约

移动/重命名时联查脚本、场景、外部动画和资源中的 path、uid、NodePath、class_name、unique_name_in_owner、导出绑定、继承覆盖及 [connection]。

动画方法轨道中的目标节点、方法名、参数、关键帧时间和触发次数都是接口。射击组件的 _shoot_bullet、博士死亡的 request_trophy 等即使没有普通代码调用，也可能被 .tscn/.tres 调用。删除“未使用”代码前须排查这些消费者。

保留脚本 .gd.uid 内容及现有资源 UID；重构不应批量重生成 UID、重导入素材或改动动画。必要搬迁先列映射，再逐个核对引用；不要假定更新 res:// 路径就足够。

project.godot 定义碰撞层；角色与子弹使用行号、状态和阵营过滤。屋顶区分检测平面与真实平面，位置变化需说明局部/全局坐标。渲染先看 CanvasLayer 再看 z_index。修改节点父级、碰撞或显示层时必须检查这些语义。

## 存档与 ID

- 存档格式入口为 scripts/autoload/global/save_service.gd、scripts/resources/save_game/、MainGameManager.save_game_main_game/load_game_main_game 及各组件的保存字典。
- 全局存档按用户名存于 GlobalSaveGame.json；关卡资源存于 MAIN_GAME_SAVE_DIR_NAME 定义的目录。路径、JSON 键、嵌套 Dictionary 键、Resource class_name、@export 名称与类型都要保持旧数据可读。
- SaveGameVersion 被写入，但当前加载逻辑不提供完整版本校验/迁移；不能以存在版本常量为由认定字段迁移安全。不要把尚未恢复的字段默认为已实现功能。
- PlantType、ZombieType、ZombieBossType、MainScenes 与关卡模式等数字值会进入资源或存档。不要顺手重排；有新增需求时明确保留旧值。
- 关卡 save_game_name 由模式、页码和 level_id 组合。自定义选关将 level_game_para 目录内直接 .tres 文件的 basename 用作 level_id；重命名文件可能改变进度与存档关联。
- 自定义关卡扫描在编辑器使用项目根，在导出运行时使用可执行文件所在目录，且不递归扫描子目录。不要将它当作普通 res:// 递归注册表。
- 如 game_sences 等现有拼写属于资源字段，不能用“纠正拼写”跳过兼容方案。玉米炮双格占用、主格保存等细节须从 plant_cell.gd 核对。

## 使用地图时的边界

README、开发文档和示例可能落后于源码。遇到 Godot 版本、init_norm、MainGameDate、EnumsMainScene 等描述，先核查实际配置和声明；不按旧文档新建依赖，也不因为文档旧而顺手整理所有文档。

README 说明公开仓库可能缺少原版 assets。运行/导入失败先区分缺失素材、既有问题和本批变化，不删除引用或修改玩法来制造“通过”。

addons、素材、动画转换工具、导出配置不属于默认重构范围，只有任务确实涉及才读取和修改。用户存档不作为默认检查输入。
