骨骼姿态镜像工具（BoneMirrorTool）说明书
兼容3dsMax2008及以上版本（Compatible with 3dsMax2008 and above）

一、工具简介
Bro做MOD每次都要调两边的姿势调累了,做了个脚本

二、文件构成
工具包含以下文件/文件夹：
- BoneMirrorTool.mcr
  宏脚本文件，安装后可在 Customize UI 中生成按钮。
- BoneMirrorTool.ms
  普通脚本文件，包含工具的核心逻辑。
- UI/ 文件夹
  存放按钮图标等资源，必须与脚本放在同一路径下，否则按钮会退回文字显示。
  图标文件名：Ash.png、001.png、002.png、003.png

三、.ms 与 .mcr 的区别
- .ms (MaxScript Script)
  普通脚本，运行后立即执行，不会自动注册按钮。用于开发调试，或由 .mcr 调用。
- .mcr (MacroScript)
  宏脚本，安装后会在 Customize UI 中出现。用于正式分发。在本工具中，.mcr 脚本负责注册 UI，内部调用 .ms 实现功能。

四、安装步骤（看不懂mcr格式安装的，ms格式的简单，拖进max就能用，脚本窗口底部还能点按钮跳到我主页看教程）
1. 将 骨骼姿态镜像工具.mcr、骨骼姿态镜像工具.ms、UI 文件夹复制到：
   C:\Users\<用户名>\AppData\Local\Autodesk\3dsMax\<版本>\ENU\usermacros\
2. 启动 3ds Max。
3. 打开菜单 ：自定义 → 自定义用户界面 → 工具栏 → 类别 → Bone Tools → 鼠标拖到工具栏安装
4. 不在工具栏装也可以装“四元菜单”那一栏，这样窗口右键就能看到工具，或者“菜单”一栏装到顶栏的菜单里

五、主要功能
1. 镜像轴选择：X / Y / Z。
2. 匹配模式：前缀 / 后缀 / 包含 / 映射表优先。
3. 命名规则：指定 L/R 标记。
4. 映射表：手动输入特殊对应关系。
5. 可选项：包含子骨骼 / 遇缺失节点继续 / 可撤销。
6. 点击“镜像当前帧”执行操作。

六、使用流程
1. 选择一侧骨骼链。
2. 打开 脚本
3. 设置镜像轴（通常为 X）。
4. 设置匹配模式和命名规则。
5. 点击“镜像当前帧”。
6. 检查结果。

七、注意事项
- 确保骨骼命名规范（如果有那种左右两边骨骼名乱的一批的，建议打死绑定者，那种你得把名字抄进映射表框里面再镜像）
- 图标文件必须命名为 Ash.png、001.png、002.png、003.png。
- UI 文件夹必须和 .mcr、.ms 同路径。
- 建议操作前保存场景。
- 支持撤销，关闭可撤销可提升性能。


Bone Pose Mirror Tool (BoneMirrorTool) Manual

1. Introduction
BoneMirrorTool is a 3ds Max script tool for mirroring the pose of bones from one side of a character to the other, useful in rigging and animation editing.

2. File Structure
The tool consists of:
- BoneMirrorTool.mcr
  MacroScript file. Registers the tool in Customize UI.
- BoneMirrorTool.ms
  Standard script file containing the main logic.
- UI/ folder
  Stores button icons. Must be placed in the same path as the scripts.
  Icon filenames: Ash.png, 001.png, 002.png, 003.png

3. Difference between .ms and .mcr
- .ms (MaxScript Script)
  Runs immediately when executed. No UI registration. Used for development/debugging or called by .mcr.
- .mcr (MacroScript)
  Registers into Customize UI. Used for distribution. In this tool, .mcr handles the UI while calling the .ms for logic.

4. Installation
1. Copy BoneMirrorTool.mcr, BoneMirrorTool.ms, and UI folder to:
   C:\Users\<username>\AppData\Local\Autodesk\3dsMax\<version>\ENU\usermacros\
2. Launch 3ds Max.
3. Go to Customize → Customize User Interface → Toolbars.
4. In Category: Bone Tools, find "Bone Mirror".
5. Drag to a toolbar to create a button.

5. Main Features
1. Mirror axis selection: X / Y / Z.
2. Matching modes: Prefix / Suffix / Contains / Mapping Table First.
3. Naming rules: define L/R identifiers.
4. Mapping table: specify custom name pairs.
5. Options: include children, ignore missing nodes, undo support.
6. Execute by clicking "Mirror Current Frame".

6. Usage Workflow
1. Select the bone chain on one side.
2. Open BoneMirrorTool.
3. Set the mirror axis (usually X).
4. Set matching mode and naming rules.
5. Click "Mirror Current Frame".
6. Check the result.

7. Notes
- Ensure consistent bone naming.
- Icon files must be named Ash.png, 001.png, 002.png, 003.png.
- UI folder must be in the same path as .mcr and .ms.
- Save the scene before using.
- Undo is supported; disabling it may improve performance.
