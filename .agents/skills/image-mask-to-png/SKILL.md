---
name: image-mask-to-png
description: Use when a user supplies an image and a separate grayscale mask to produce a transparent PNG, including requests to use a second image as mask or convert a mask to alpha. 适用于原图加遮罩生成透明 PNG；不用于没有遮罩的自动抠图或图像生成。
---

# 遮罩生成透明 PNG

使用 [scripts/apply_mask.py](scripts/apply_mask.py) 检查输入、选择输出文件名并处理像素，无需临时重写算法或调用图像生成服务。

## 输入与输出

- 默认原图为 JPG/JPEG，mask 为 PNG，扩展名不区分大小写。恰好提供一张 JPG/JPEG 和一张 PNG 且未指定角色时，按格式识别角色，不依赖附件顺序；用户明确指定的角色优先。缺少图片或角色不明确时先询问。
- 默认输出为原图同目录同名的 `.png`，仅替换最后一个后缀。例如 `assets/reanim/example.jpg` 输出为同目录的 `example.png`。经确认使用其他格式原图时沿用此规则；用户指定输出位置或名称时通过 `--output` 传入。
- 白色保留、黑色透明、灰色半透明。保留原图 RGB，输出 Alpha = 原 Alpha × 遮罩灰度 / 255，向下取整。遮罩自身 Alpha 不参与计算。
- 输出为原尺寸 RGBA PNG。输入尺寸必须一致；不默认缩放、裁剪、反转、二值化、模糊或去黑边。

## 环境

默认使用当前 Codex 桌面任务的内置 Python，依赖见 [requirements.txt](requirements.txt)。调用 `load_workspace_dependencies` 获取 `Python executable` 绝对路径，不猜测位置、不写死用户名、不使用裸 `python`。使用该解释器检查 Python 和 Pillow；不可用时说明限制并由用户指定环境，不静默切换 Conda，也不向内置运行时安装或升级包。用户明确指定解释器时遵循其选择。

## 检查、确认与执行

1. 用脚本的 `--check` 做只读检查，读取 JSON 报告；这一步不会生成图片或创建输出目录。
2. 检查 `format_warnings`：非空时列出原图与 mask 的角色、完整路径、实际格式和计划输出路径，询问这些输入是否正确，等待答复。用户确认后才使用 `--allow-other-formats`，不擅自交换角色或修改输入后缀；已明确确认该格式组合时不重复询问。
3. 按以下优先级处理 `conflict`，格式确认与覆盖确认可合并成一次问题：
   - `input`：输出指向原图或 mask，输入文件始终保留。说明该冲突和 `numbered_output` 路径，使用 `--auto-number`；不要提供覆盖输入的选项，也不要使用 `--force`。
   - `existing`：先列出 `output` 的完整绝对路径，询问“确认覆盖，还是保留现有文件并自动编号另存？”并等待答复。确认覆盖后用 `--force`；选择不覆盖则用 `--auto-number`。用户已明确授权覆盖这个具体文件时不重复询问。
   - `none`：告知 `output` 的完整路径，直接执行，不传覆盖或编号参数。
4. 保持预检使用的输入及输出参数，去掉 `--check`，按确认结果添加参数并执行。未收到答复不能视为确认；格式许可和覆盖许可各自独立，不能相互替代。

PowerShell 示例（将占位符替换为获取到的绝对路径）：

```powershell
$maskPython = "PYTHON_EXECUTABLE"
$maskScript = "SKILL_DIR/scripts/apply_mask.py"
$maskArgs = @("--image", "SOURCE_PATH", "--mask", "MASK_PATH")
# 指定输出时：$maskArgs += @("--output", "OUTPUT_PATH.png")
& $maskPython -X utf8 -c "import sys, PIL; print(sys.version); print(PIL.__version__)"
& $maskPython -B -X utf8 $maskScript @maskArgs --check
# 检查无冲突且格式符合要求后：
& $maskPython -B -X utf8 $maskScript @maskArgs
# 不覆盖、编号另存时，执行上面命令并添加 --auto-number；确认覆盖则添加 --force。
# 确认非默认格式时，另外添加 --allow-other-formats。
```

`--auto-number` 在文件主名后依次追加 `_1`、`_2`……，使用第一个未占用的名称，保留目录和原主名中的数字。例如 `example_7.png` 冲突时输出 `example_7_1.png`。若发布时又出现同名文件，脚本继续编号；以脚本返回的实际路径为准。`--force` 与 `--auto-number` 不能同时使用。

脚本先在目标目录写入临时 PNG，重新打开并完整解码校验后才发布。确认覆盖时使用原子替换；不覆盖时发布操作拒绝已有目标。写入、校验或替换失败会清理临时文件并保留旧输出。若普通执行返回文件冲突，重新检查并询问，不能自动转为强制覆盖。

## 验证与交付

- 退出码 `0` 表示检查或生成成功，`1` 表示处理失败，`2` 表示参数错误。`--check` 成功仅表示检查完成；仍需处理报告中的格式警告和冲突。
- 根据生成结果重新打开输出，确认 PNG、RGBA、尺寸与 Alpha；必要时用棋盘格或浅色背景预览。返回实际输出文件的绝对路径链接并尽可能展示图片。
- 生成结果和临时预览不放进技能目录，不作为技能源码提交。

维护脚本后，用同一解释器运行测试：

```powershell
& $maskPython -B -X utf8 -m unittest discover -s "SKILL_DIR/tests" -v
```
