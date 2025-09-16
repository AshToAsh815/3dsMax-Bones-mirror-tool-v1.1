Ash - 骨骼镜像工具 v2.0 简易说明书
<img width="450" height="940" alt="截图" src="https://github.com/user-attachments/assets/990058c5-7063-4181-9fff-040b1f0fed98" />

更新项：
①、加入”匹配预设“功能，可以保存或者删除你的预设（包含四种模式的预设皆可保存与删除，提高工作效率）
②、对“映射表优先模式”的逻辑进行了一些优化
③、增加了一些彩蛋，你可以在脚本窗口到东点点西点点就会发现
————————————————————————————————————————————————————————————————————————
1. 脚本概述
基于 3ds Max Script 开发的骨骼姿态镜像工具，核心功能是将选中骨骼的位置、旋转、缩放同步到对侧骨骼（如左臂→右臂），支持多种匹配逻辑，提升动画制作效率。
核心特性：4 种骨骼匹配模式、预设保存 / 加载、多骨骼链同步镜像、容错与可撤销操作。

兼容性：兼容3dsMax2014及以上版本（本人自己的是Max2021）
————————————————————————————————————————————————————————————————————————
2. 安装与启动
2.1 安装
获取脚本文件（.ms格式）和UI文件夹，确保两者在同一目录（缺失UI仅图标不显示，功能正常）。
加载方式：
临时：直接将.ms文件拖放至 3ds Max 视图，自动初始化。
永久：将脚本放入 Max 脚本目录（默认：C:\Users\用户名\AppData\Local\Autodesk\3dsMax\版本\ENU\scripts），通过「脚本 > 运行脚本」启动。

2.2 启动
脚本加载后自动弹出工具卷展栏；若未弹出，在「自定义 > 自定义用户界面 > 宏脚本 > Bone Tools」中找到「Ash - 骨骼镜像」，拖到工具栏点击启动。
————————————————————————————————————————————————————————————————————————
3. 界面核心区域（精简版）
工具界面分 5 个关键区域，仅列核心交互控件：

区域	核心控件及功能

镜像轴设置	- 下拉框ddl_axis：选镜像基准轴（X/Y/Z，默认 X 轴，角色左右镜像常用）
- 复选框chk_children：是否包含子骨骼
- 复选框chk_ignoreMissing：遇缺失骨骼是否继续

匹配模式设置	- 下拉框ddl_mode：选骨骼匹配逻辑（前缀 / 后缀 / 包含 / 映射表优先）

命名规则 / 映射表	- 下拉框ddl_preset：加载已保存预设（默认 “自定义”）
- 按钮btn_savePreset：保存当前配置为预设
- 按钮btn_delPreset：删除选中预设（内置预设不可删）
- 输入框edt_L/edt_R：普通模式填左右标识（如 “_L”/“_R”）
- 多行框edt_Map：映射表模式填 “key=value” 规则（如 “SpiderMan_01=BatMan_114514”）

镜像执行	- 按钮btn_mirror：执行当前帧镜像（核心功能）
- 文本lbl_info：显示选中骨骼链数量
- 复选框chk_undo：操作是否可撤销（建议勾选）

作者与更新	- 按钮btn_nexus/btn_bili：作者主页
- 按钮btn_update：GitHub 更新地址
————————————————————————————————————————————————————————————————————————

4. 核心使用教程

4.1 普通模式（前缀 / 后缀 / 包含，适合命名规范骨骼）
选需镜像的骨骼根节点（如左臂根骨 “ArmRoot_L”）。
配置：
镜像轴：ddl_axis选 X 轴，勾选chk_children（含子骨骼）和chk_ignoreMissing（容错）。
匹配模式：ddl_mode选对应模式（如骨骼后缀 “_L”/“_R” 选 “后缀”）。
命名规则：edt_L填 “_L”，edt_R填 “_R”（可选：点btn_savePreset存为预设）。
执行：勾选chk_undo，点btn_mirror，验证对侧骨骼姿态是否同步。

4.2 映射表优先模式（适合命名不统一骨骼）
选骨骼根节点，ddl_axis选 X 轴，勾选容错和含子骨骼。
配置：
ddl_mode选 “映射表优先”。
edt_Map填映射规则（每行 1 条 “key=value”，如 “冥月千雪 = 你的中二魔王”，支持双向匹配，
意思就是你两边对应的两根骨骼名字完全不一样也没关系，名字写到映射表输入框里面就能成功镜像）。
执行：点btn_mirror，完成镜像。
————————————————————————————————————————————————————————————————————————

5. 预设管理（简单操作）
加载：ddl_mode选对应模式，ddl_preset下拉选目标预设，参数自动填充。
保存：配置好参数后点btn_savePreset，输入名称确认（映射表需含 “=”，否则提示格式错误）。
删除：ddl_preset选需删除的预设（非 “自定义”），点btn_delPreset确认（内置预设禁止删除，会弹提示）。

————————————————————————————————————————————————————————————————————————

6. 注意事项
骨骼命名需与匹配模式对应（如 “后缀” 模式需统一 “_L”/“_R”），否则无法匹配对侧。
镜像轴选错会导致姿态颠倒，角色左右镜像优先试 X 轴。
重要操作前建议备份场景，避免失误丢失数据。

————————————————————————————————————————————————————————————————————————
7. 常见问题
问题	解决方案
镜像后对侧骨骼无反应	1. 检查ddl_mode与骨骼命名是否匹配；2. 确认edt_L/edt_R或edt_Map参数正确
镜像姿态颠倒（如骨骼反向）	切换ddl_axis的镜像轴（如 X 轴改 Y 轴）
预设保存后不显示	重新启动脚本，或检查脚本目录是否有读写权限（需生成BoneMirrorPresets文件）
映射表提示格式错误	确保每行仅 1 个 “=”（如 “a=b” 正确，“a=b=c” 错误）





Ash - Bone Mirror Tool v2.0 Simplified Manual
Update Items:

①、Added the "Matching Presets" feature, allowing you to save or delete your presets (presets for all four modes can be saved and deleted, improving work efficiency).

②、Optimized the logic for the "Mapping Table Priority Mode."

③、Added some Easter eggs—you can explore the interface by clicking around to discover them.
————————————————————————————————————————————————————————————————————————
1. Tool Overview
A bone pose mirroring tool developed based on 3ds Max Script. Its core function is to sync the position, rotation, and scale of selected bones to their counterpart bones (e.g., left arm → right arm). It supports multiple matching logics to improve animation production efficiency.

Core Features: 4 bone matching modes, preset save/load, simultaneous mirroring of multiple bone chains, error tolerance, and undoable operations.

Compatibility: Supports 3ds Max 2014 and above (Personal test environment: 3ds Max 2021).
————————————————————————————————————————————————————————————————————————
2. Installation & Launch
2.1 Installation
Obtain the script file (in .ms format) and the UI folder. Ensure both are placed in the same directory (If the UI folder is missing, only icons won’t display—core functions remain normal).

Loading Methods:

Temporary Loading: Drag and drop the .ms file directly into the 3ds Max viewport; initialization will start automatically.
Permanent Loading: Place the script in the Max script directory (Default path: C:\Users\[Your Username]\AppData\Local\Autodesk\3dsMax\[Your Max Version]\ENU\scripts). Launch it via Scripts > Run Script.
2.2 Launch
After loading, the tool’s rollout panel will pop up automatically. If it doesn’t:

Go to Customize > Customize User Interface > MacroScripts > Bone Tools.
Find Ash - Bone Mirror, drag it to the toolbar, and click to launch.
————————————————————————————————————————————————————————————————————————
3. Core UI Areas (Simplified)
The tool interface is divided into 5 key areas, with only core interactive controls listed below:

Area	Core Controls & Functions
Mirror Axis Settings	- Dropdown ddl_axis: Select the mirror reference axis (X/Y/Z; default: X-axis, commonly used for left-right mirroring of character bones).
- Checkbox chk_children: Whether to include child bones.
- Checkbox chk_ignoreMissing: Whether to continue if bones are missing.
Matching Mode Settings	Dropdown ddl_mode: Select bone matching logic (Prefix / Suffix / Contain / Mapping Table Priority).
Naming Rules / Mapping Table	- Dropdown ddl_preset: Load saved presets (default: "Custom").
- Button btn_savePreset: Save current configuration as a preset.
- Button btn_delPreset: Delete the selected preset (built-in presets cannot be deleted).
- Input boxes edt_L/edt_R: Enter left/right identifiers for normal modes (e.g., "_L"/"_R").
- Multi-line box edt_Map: Enter "key=value" rules for Mapping Table mode (e.g., "SpiderMan_01=BatMan_114514").
Mirror Execution	- Button btn_mirror: Execute mirroring for the current frame (core function).
- Text lbl_info: Display the number of selected bone chains.
- Checkbox chk_undo: Whether the operation is undoable (recommended to check).
Author & Updates	- Buttons btn_nexus/btn_bili: Links to the author’s homepage.
- Button btn_update: GitHub update link.
————————————————————————————————————————————————————————————————————————
4. Core Usage Tutorials
4.1 Normal Mode (Prefix / Suffix / Contain)
Suitable for bones with standardized naming (e.g., "_L"/"_R", "Left"/"Right").

Select the bone root node to mirror (e.g., left arm root "ArmRoot_L").
Configuration:
Mirror Axis: Select X-axis in ddl_axis; check chk_children (include child bones) and chk_ignoreMissing (error tolerance).
Matching Mode: Select the corresponding mode in ddl_mode (e.g., "Suffix" for bones named with "_L"/"_R").
Naming Rules: Enter "_L" in edt_L and "_R" in edt_R (Optional: Click btn_savePreset to save as a preset).
Execution: Check chk_undo, click btn_mirror, and verify if the counterpart bone’s pose is synced.
4.2 Mapping Table Priority Mode
Suitable for bones with non-standardized names (no uniform left-right identifiers).

Select the bone root node; select X-axis in ddl_axis; check chk_ignoreMissing (error tolerance) and chk_children (include child bones).
Configuration:
Select "Mapping Table Priority" in ddl_mode.
Enter mapping rules in edt_Map (one "key=value" rule per line, e.g., "SuperMan_01=SpiderMan_02"). This supports bidirectional matching—meaning it works even if the names of corresponding bones on both sides are completely different (just enter the names in the mapping table input box).
Execution: Click btn_mirror to complete mirroring.
————————————————————————————————————————————————————————————————————————
5. Preset Management (Simple Operations)
Load: Select the corresponding mode in ddl_mode, then select the target preset from the ddl_preset dropdown—parameters will be filled automatically.
Save: After configuring parameters, click btn_savePreset and enter a name to confirm (Mapping table rules must contain "="; otherwise, a format error prompt will appear).
Delete: Select the preset to delete (not "Custom") in ddl_preset, click btn_delPreset to confirm (built-in presets are protected and cannot be deleted— a prompt will appear if you try).
————————————————————————————————————————————————————————————————————————
6. Notes
Bone naming must match the selected matching mode (e.g., use uniform "_L"/"_R" for "Suffix" mode); otherwise, counterpart bones cannot be matched.
Selecting the wrong mirror axis will cause inverted poses. For left-right mirroring of characters, try the X-axis first.
It is recommended to back up the scene before important operations to avoid data loss due to mistakes.
————————————————————————————————————————————————————————————————————————
7. Common Issues & Solutions
Issue	Solution
No response from counterpart bones after mirroring	1. Check if ddl_mode matches the bone naming; 2. Verify that parameters in edt_L/edt_R or edt_Map are correct.
Inverted bone pose after mirroring (e.g., reversed direction)	Switch the mirror axis in ddl_axis (e.g., change from X-axis to Y-axis).
Saved preset not displayed	Restart the script, or check if the script directory has read/write permissions (the BoneMirrorPresets file needs to be generated).
Mapping table format error prompt	Ensure each line contains only one "=" (e.g., "a=b" is correct; "a=b=c" is incorrect).