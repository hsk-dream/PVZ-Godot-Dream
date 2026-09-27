# 🌱 使用godot重置PVZ
从95版、植物娘、胆小菇之梦，到杂交版、融合版等众多精彩的改版与同人作品，相信许多玩家都曾萌生过属于自己的创意与幻想。

本项目基于 [Godot4.6.2](https://godotengine.org/zh-cn/) 引擎，致力于对原版《植物大战僵尸》进行高质量复刻（完美还原），目前已基本实现原版主体内容，僵王博士和部分小游戏仍在完善中。

欢迎各位大佬在本开源项目基础上，完成属于自己的 PVZ 同人改版之梦！


**考虑到版权问题，将原版相关资源文件删除。**


有对本项目感兴趣的大佬，欢迎大家进qq群 (1046565016) 交流

## 僵王博士开发进度

已接入僵王注册、关卡出怪配置、分层状态机、受击窗口和死亡奖杯流程。
已实现连续放置僵尸与冰火球技能，包括冰火球碾压、植物克制、嘴部光效和地面轨迹。
蹦极、砸车和脚踩植物已接入动画流程，实际技能效果仍使用 `print` 占位。

## TODO

- [ ] 实现蹦极技能：选择目标，生成并调度蹦极僵尸。
- [ ] 实现砸车技能：选择落点，在动画关键帧生成车辆并处理范围碾压。
- [ ] 实现脚踩植物技能：确定踩踏范围，在动画关键帧处理植物碾压。
- [ ] 完善特殊植物与僵王的交互规则。
- [ ] 补齐僵王技能音效。
- [ ] 调整技能权重、间隔、连续放置数量及冰火球速度等战斗参数。
- [ ] 手动验收完整战斗流程，包括受击窗口、死亡衔接、冰火球克制及点击奖杯获胜。

## 项目展示
### 项目视频介绍
[开源！使用Godot实现对原版PVZ的完美复刻 (https://www.bilibili.com/video/BV1FKNJzUEpp/)](https://www.bilibili.com/video/BV1FKNJzUEpp/)
请观看该合集最新的展示视频
### 主游戏界面
![主游戏界面](readme_show/main_game.png)
### 开始菜单界面
![开始菜单界面](readme_show/run_start_menu.png)
### 自定义关卡
- 自定义关卡使用在游戏根目录下"level_game_para"文件夹中的游戏参数文件。
- 游戏参数文件为"ResourceLevelData"类型的资源文件
- 具体查看脚本文件"res://scripts/resources/level/level_data.gd"

## 游戏开发相关
[基于本项目开发pvz同人改版必看内容（./docs/开发相关.md）](./docs/开发相关.md)

### 插件
#### [anim_player_refactor](https://github.com/poohcom1/godot-animation-player-refactor)
一个 Godot 插件，用于重构 AnimationPlayer 的动画。
[插件使用教程](https://www.bilibili.com/video/BV1GxXWYZExH?spm_id_from=333.788.videopod.sections&vd_source=1005534986b111b7c1911fe1c36ac835)

注意：目录下**plugin.gd**脚本中调用的函数EditorUtil.find_animation_menu_button(base_control)只支持英文，需要进入函数修改对应的代码 func(node): return node.text == "Animation" 修改为 func(node): return node.text == "Animation" or node.text == "动画"

### [R2Ga_PVZ](https://github.com/hsk-dream/PVZ_reanim2godot_animation)
将植物大战僵尸的动画文件转换为Godot游戏引擎所支持的动画格式。[使用教程](https://www.bilibili.com/video/BV1XBKwzdELA/)
forked from [PVZ_reanim2godot_animation](https://github.com/HYTommm/PVZ_reanim2godot_animation)



### PVZ相关参考资料
- [［PVZ解包］一代PVZ植物大战僵尸PAK文件解包教程(https://www.bilibili.com/video/BV1JQ4y1k7KS/)](https://www.bilibili.com/video/BV1JQ4y1k7KS/)

- [Godot4.3——植物大战僵尸：游戏制作教程（已完结） (https://www.bilibili.com/video/BV1AdBtY9Ec5/)](https://www.bilibili.com/video/BV1AdBtY9Ec5/)

- [R2Ga转换器v3.1发布！ (https://www.bilibili.com/video/BV1s3ZbY3E9L/)](https://www.bilibili.com/video/BV1s3ZbY3E9L/)

- [PVZ wiki（https://wiki.pvz1.com/doku.php?id=home）](https://wiki.pvz1.com/doku.php?id=home)

## 📜 许可协议：Custom Non-Commercial License

本项目为《植物大战僵尸》复刻的学习作品，仅供个人学习与研究使用。
原作《植物大战僵尸》的游戏名称、角色、音乐、图像等内容的版权归 **PopCap Games** 及其母公司 **Electronic Arts（EA）** 所有，
本项目不用于任何商业目的，也不构成对原作版权的挑战或侵犯。

本项目采用自定义非商用许可协议，**禁止任何形式的商业用途**，其余条款与 MIT 协议一致，简要如下：

### ✅ 允许

- 个人学习与研究；
- 学术研究与教学用途；
- 《植物大战僵尸》相关的非营利改编、同人创作。

### ❌ 禁止

- 商业公司或组织内部使用；
- 将本项目作为产品或服务的一部分进行销售、收费分发或在线提供；
- 用于 SaaS、API 服务、BaaS 等直接或间接商业用途。

---

🔗 完整许可条款请查看 [LICENSE 文件](./LICENSE)


## 🙌 致谢
致敬《植物大战僵尸》原作团队（PopCap & EA）

### 项目贡献
- 植物图鉴初稿整理：[多003_](https://space.bilibili.com/472181151)
- 宽屏（16:9）的部分素材使用[豆包ai](https://www.doubao.com/chat)生成,感谢ai

### 参考项目
- 樱桃炸弹爆炸动画粒子特效: [HYTommm](https://space.bilibili.com/3493140163988287)开源项目[Godot-PVZ](https://github.com/HYTommm/Godot-PVZ)
- 信号总线,随机选择器: [玩物不丧志的老李](https://space.bilibili.com/8618918)开源项目[godot_core_system](https://github.com/LiGameAcademy/godot_core_system)
- 种子雨雨幕：[简单的小雨氛围：shader写的雾、粒子做的雨和水花 | godot4教程](https://www.bilibili.com/video/BV15ibAz4EZi)
