骨骼镜像工具（Bone Mirror Tool v3.0）说明书

软件版本兼容性：

支持的 3ds Max 版本：兼容 3ds Max 2016 及以上版本（基于 MaxScript 语法特性与 DotNet 控件支持范围，低版本可能存在 UI 控件加载失败或函数不支持问题）。

系统兼容性：仅支持 Windows 系统（3ds Max 本身无 macOS 版本，脚本依赖 Windows 系统的 DotNet Framework 4.0+，无需额外安装，Windows 7 及以上系统默认自带）。
——————————————————————————————————————————————————————————————————————————
1. 工具简介
功能：用于 3ds Max 中骨骼姿态的左右镜像，支持多骨骼链同步处理，解决常规镜像中左右骨骼轴向不一致导致的模型错乱问题。
核心优势：新增 “局部镜像” 功能，可针对性调整骨骼轴向；支持自定义骨骼映射规则，适配不同命名规范的骨架。
——————————————————————————————————————————————————————————————————————————
2. 核心功能区说明

2.1 镜像轴设置
控件	功能说明
镜像轴（下拉框）	选择镜像基准轴（X/Y/Z），需根据骨骼在场景中的朝向选择（如 X 轴常用于左右对称骨骼）。
包含子骨骼（勾选框）	勾选时同步镜像选中骨骼的所有子骨骼；未勾选时仅处理顶层选中骨骼。
遇缺失节点继续（勾选框）	勾选时，若找不到某骨骼的对侧节点，跳过该节点继续处理；未勾选时直接停止操作。

2.2 局部镜像设置（解决轴向不一致问题）
控件	功能说明
使用局部镜像（勾选框）	启用后，按骨骼局部坐标系进行旋转镜像（常规骨架无需启用，轴向错乱时必选）。
翻转局部轴（下拉框）	仅 “使用局部镜像” 启用时可操作，选择需翻转的局部轴组合（如 YZ 轴适配特定骨骼结构）。

2.3 匹配模式设置
控件	功能说明
匹配模式（下拉框）	选择骨骼左右对侧的识别逻辑：
- 前缀 / 后缀 / 包含：按名称中的字符（如 L/R、Left/Right）匹配；
- 映射表优先：优先按自定义映射规则匹配，无匹配时 fallback 到字符规则。

2.4 命名规则与预设
控件	功能说明
命名预设（下拉框）	加载已保存的规则预设（如 “L/R”“_L/_R”），选择 “自定义” 可手动输入参数。
左侧 / 右侧字符串（输入框）	非 “映射表优先” 模式下，输入识别左右骨骼的标识（如 L_、R_）。
映射表（多行输入框）	“映射表优先” 模式下，按 “key=value” 格式输入自定义骨骼映射（每行一条规则，支持双向匹配）。
保存 / 删除预设（按钮）	保存当前规则为新预设；删除选中预设（内置预设不可删除）。

2.5 执行与辅助功能
控件	功能说明
镜像当前帧（按钮）	执行核心镜像操作，仅对当前时间帧生效，支持多骨骼链同步处理。
当前已选择 X 条骨骼链（标签）	实时显示选中的骨骼根节点数量，确认操作范围。
可撤销（勾选框）	勾选时，镜像操作记录到 Max 撤销历史，可通过 Ctrl+Z 撤销。

——————————————————————————————————————————————————————————————————————————
3. 操作流程

3.1 常规骨架镜像（轴向一致）
选中需要镜像的骨骼链（顶层骨骼即可）；
在 “镜像轴” 下拉框选择对应基准轴（如 X 轴）；
确认 “包含子骨骼” 已勾选（按需调整）；
点击【镜像当前帧】按钮，完成操作。

3.2 轴向不一致骨架镜像（模型错乱时）
选中目标骨骼链，在 “匹配模式” 中选择对应规则（或配置映射表）；
勾选【使用局部镜像】，在 “翻转局部轴” 中选择需调整的轴组合（如 YZ 轴）；
点击【镜像当前帧】按钮，验证模型姿态是否正常（异常可更换局部轴组合）。

3.3 自定义映射规则
在 “匹配模式” 中选择 “映射表优先”；
在 “映射表” 输入框按格式输入规则（如 “SpiderMan_01=BatMan_114514”）；
选中骨骼，点击【镜像当前帧】，工具将按映射规则匹配对侧骨骼。
——————————————————————————————————————————————————————————————————————————
4. 其他功能
控件 / 按钮	功能说明
更新地址（GitHub）	打开脚本的 GitHub 仓库，获取最新版本、更新日志及源代码。
N 网主页 / B 站主页	访问作者的 Nexus Mods 或 Bilibili 主页，查看教程或联系作者。
——————————————————————————————————————————————————————————————————————————
5. 注意事项
操作前建议保存场景，避免因规则配置错误导致的骨骼姿态异常；
映射表规则需确保 “key=value” 格式正确（至少包含 1 个 “=”），否则无法保存预设；
内置预设（如 “Left/Right”“L/R”）不可删除，避免影响基础功能使用。





Bone Mirror Tool v3.0 User Manual

——————————————————————————————————————————————————————————————————————————
Software Version Compatibility

Supported 3ds Max Versions: Compatible with 3ds Max 2016 and above. (Based on MaxScript syntax features and DotNet control support, lower versions may experience UI control loading failures or unsupported functions.)

System Compatibility: Windows systems only. (3ds Max has no macOS version natively; the script relies on Windows’ DotNet Framework 4.0+, which comes pre-installed on Windows 7 and later systems—no additional installation required.)
——————————————————————————————————————————————————————————————————————————
1. Tool Overview
Function: Used for left-right mirroring of bone poses in 3ds Max, supporting simultaneous processing of multiple bone chains. Resolves model distortion caused by inconsistent axes between left and right bones during regular mirroring.
Core Advantages: New "Local Mirror" feature for targeted bone axis adjustment; supports custom bone mapping rules to adapt to skeletons with different naming conventions.
——————————————————————————————————————————————————————————————————————————
2. Core Function Area Description

2.1 Mirror Axis Settings
Control	Description
Mirror Axis (Dropdown)	Select the base axis (X/Y/Z) for mirroring. Choose based on bone orientation in the scene (e.g., X-axis is commonly used for left-right symmetric bones).
Include Children (Checkbox)	When checked, mirrors all child bones of the selected bones; when unchecked, only processes top-level selected bones.
Continue on Missing Nodes (Checkbox)	When checked, skips and continues processing if the counterpart of a bone is not found; when unchecked, stops the operation immediately.

2.2 Local Mirror Settings (Resolves Axis Inconsistency)
Control	Description
Use Local Mirror (Checkbox)	When enabled, performs rotation mirroring based on the bone’s local coordinate system (not needed for regular skeletons, mandatory for axis inconsistency).
Local Axis Flip (Dropdown)	Only operable when "Use Local Mirror" is enabled. Select the combination of local axes to flip (e.g., YZ-axis for specific bone structures).

2.3 Matching Mode Settings
Control	Description
Matching Mode (Dropdown)	Select the logic for identifying left-right bone counterparts:
- Prefix/Suffix/Contain: Match via characters in bone names (e.g., L/R, Left/Right);
- Map First: Prioritize custom mapping rules, fallback to character rules if no match is found.

2.4 Naming Rules & Presets
Control	Description
Naming Presets (Dropdown)	Load saved rule presets (e.g., "L/R", "_L/_R"). Select "Custom" to enter parameters manually.
Left/Right String (Input Boxes)	In non-"Map First" modes, enter identifiers for left/right bones (e.g., L_, R_).
Mapping Table (Multi-line Input)	In "Map First" mode, enter custom bone mapping in "key=value" format (one rule per line, supports bidirectional matching).
Save/Delete Preset (Buttons)	Save current rules as a new preset; delete the selected preset (built-in presets cannot be deleted).

2.5 Execution & Auxiliary Functions
Control	Description
Mirror Current Frame (Button)	Executes the core mirror operation, effective only for the current time frame, supporting simultaneous processing of multiple bone chains.
X Bone Chains Selected (Label)	Real-time display of the number of selected bone root nodes to confirm the operation scope.
Undoable (Checkbox)	When checked, the mirror operation is recorded in Max’s undo history and can be undone via Ctrl+Z.
——————————————————————————————————————————————————————————————————————————
3. Operation Workflows

3.1 Regular Skeleton Mirroring (Consistent Axes)
Select the bone chain to mirror (only top-level bones are needed);
Select the corresponding base axis (e.g., X-axis) from the "Mirror Axis" dropdown;
Ensure "Include Children" is checked (adjust as needed);
Click the Mirror Current Frame button to complete the operation.

3.2 Skeleton Mirroring with Axis Inconsistency (When Model Is Distorted)
Select the target bone chain, and choose the corresponding rule (or configure the mapping table) in "Matching Mode";
Check Use Local Mirror, and select the axis combination to flip (e.g., YZ-axis) from "Local Axis Flip";
Click the Mirror Current Frame button, and verify if the model pose is normal (try a different axis combination if abnormal).

3.3 Custom Mapping Rules
Select "Map First" in "Matching Mode";
Enter rules in the "Mapping Table" input box in the required format (e.g., "SpiderMan_01=BatMan_114514");
Select the bones, and click Mirror Current Frame—the tool will match counterpart bones using the mapping rules.
——————————————————————————————————————————————————————————————————————————
4. Other Functions
Control/Button	Description
Update (GitHub)	Opens the script’s GitHub repository to access the latest version, update logs, and source code.
Nexus Page / Bilibili Page	Visits the author’s Nexus Mods or Bilibili homepage to view tutorials or contact the author.
——————————————————————————————————————————————————————————————————————————
5. Notes
It is recommended to save the scene before operation to avoid abnormal bone poses caused by incorrect rule configurations;
Mapping table rules must follow the correct "key=value" format (containing at least one "="), otherwise presets cannot be saved;
Built-in presets (e.g., "Left/Right", "L/R") cannot be deleted to prevent disruption to basic functionality.