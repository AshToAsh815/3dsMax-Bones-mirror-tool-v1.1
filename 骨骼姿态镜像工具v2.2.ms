global BoneMirrorRollout

/* ---------- Preset storage (强制替换映射表预设，不受旧文件影响) ---------- */
global prefixBuiltins, suffixBuiltins, containBuiltins, mapBuiltins
global prefixPresets, suffixPresets, containPresets, mapPresets

-- 1. 映射表内置预设（强制替换为指定的2个，删除旧的手臂/腿部映射）
mapBuiltins = #(  -- 这里去掉if判断，强制覆盖旧值，不管之前是否定义
    #("SuperHero", "SpiderMan_01=BatMan_114514"),
    #("两个傻逼", "冥月千雪=你的中二魔王\n你的中二魔王=绝世大傻逼\nDante陽=绝世大傻逼\n你的中二魔王=Dante陽")
)
-- 映射表用户预设：强制基于新的内置预设初始化，覆盖旧文件加载的内容
mapPresets = #()
for p in mapBuiltins do append mapPresets p

-- 2. 其他模式内置预设（保持原有结构不变，仅确保初始化）
if prefixBuiltins == undefined then
(
    prefixBuiltins = #(
        #("Left/Right", "Left", "Right"),
        #("L/R", "L", "R")
    )
)
if suffixBuiltins == undefined then
(
    suffixBuiltins = #(
        #("_L/_R", "_L", "_R"),
        #("_left/_right", "_left", "_right"),
        #("Left/Right", "Left", "Right")
    )
)
if containBuiltins == undefined then
(
    containBuiltins = #(
        #("Left/Right words","Left","Right"),
        #("L/R mix","L","R")
    )
)
-- 其他模式用户预设初始化（仅在未定义时）
if prefixPresets == undefined then
(
    prefixPresets = #()
    for p in prefixBuiltins do append prefixPresets p
)
if suffixPresets == undefined then
(
    suffixPresets = #()
    for p in suffixBuiltins do append suffixPresets p
)
if containPresets == undefined then
(
    containPresets = #()
    for p in containBuiltins do append containPresets p
)

/* ---------- 字符串辅助（修复核心名称提取，确保无多余过滤） ---------- */
fn BM_StripPrefix nm =
(
    local p = findString nm ":"
    if p != undefined then
        #(substring nm 1 p, substring nm (p+1) (nm.count - p))  -- 仅拆分"前缀:核心名"，保留核心名原始格式
    else
        #("", nm)
)

fn BM_CoreName nm =
(
    local pr = BM_StripPrefix nm
    pr[2]  -- 直接返回原始核心名（如"R_Thigh_pull_ST"），不额外过滤字符
)

fn BM_StartsWith s prefix =
(
    (prefix != "") and matchPattern s pattern:(prefix + "*")
)
fn BM_EndsWith s suffix =
(
    (suffix != "") and matchPattern s pattern:("*" + suffix)
)

/* ---------- 映射表解析（保持原有逻辑，兼容完整映射文本） ---------- */
fn BM_MapByTable core mapStr =
(
    if (mapStr == undefined) or (mapStr == "") then undefined
    else
    (
        local lines = filterString mapStr "\n"
        for ln in lines do
        (
            ln = trimRight (trimLeft ln) " \t\r\n"
            if ln != "" do
            (
                local eqPos = findString ln "="
                if eqPos != undefined do
                (
                    local k = trimRight (substring ln 1 (eqPos-1)) " \t\r\n"
                    local v = trimLeft  (substring ln (eqPos+1) (ln.count - eqPos)) " \t\r\n"
                    if (k != "" and v != "") do
                    (
                        if (findString core k) != undefined then return (substituteString core k v)
                        if (findString core v) != undefined then return (substituteString core v k)
                    )
                )
            )
        )
        undefined
    )
)

/* ---------- 查找目标骨骼（核心修复：包含模式双向匹配+全局查找） ---------- */
-- 新增：全局搜索目标骨骼（不依赖层级，解决跨父节点匹配问题）
fn BM_GlobalFindNodeByCore tgtCore =
(
    if classOf tgtCore != String or tgtCore == "" then return undefined
    for node in objects where isValidNode node do
    (
        if (BM_CoreName node.name) == tgtCore then
            return node
    )
    undefined
)

fn BM_FindCounterpartCore core mode Lstr Rstr mapStr =
(
    local t = undefined
    -- 强制类型检查：确保core是有效字符串
    if classOf core != String or core == "" then return undefined

    -- 映射表优先模式：先试映射表，再 fallback 到L/R规则
    if mode == "映射表优先" then
    (
        if (mapStr != undefined) and (mapStr != "") then
        (
            t = BM_MapByTable core mapStr
            if t != undefined then return t
        )

        if (Lstr != "") and (Rstr != "") then
        (
            if BM_StartsWith core Lstr then return substituteString core Lstr Rstr
            if BM_StartsWith core Rstr then return substituteString core Rstr Lstr
            if BM_EndsWith core Lstr then return (substring core 1 (core.count - Lstr.count)) + Rstr
            if BM_EndsWith core Rstr then return (substring core 1 (core.count - Rstr.count)) + Lstr
            if (findString core Lstr) != undefined then return substituteString core Lstr Rstr
            if (findString core Rstr) != undefined then return substituteString core Rstr Lstr
        )
        return undefined
    )

    -- 核心修复：包含模式双向对称匹配（先检查当前侧符号，再处理对侧）
    case mode of
    (
        "前缀":
        (
            if BM_StartsWith core Lstr then t = substituteString core Lstr Rstr
            else if BM_StartsWith core Rstr then t = substituteString core Rstr Lstr
        )
        "后缀":
        (
            if BM_EndsWith core Lstr then
                t = (substring core 1 (core.count - Lstr.count)) + Rstr
            else if BM_EndsWith core Rstr then
                t = (substring core 1 (core.count - Rstr.count)) + Lstr
        )
        "包含":
        (
            -- 修复1：独立检查R和L，不依赖else if（选右侧时优先处理R→L）
            local hasR = (Rstr != "" and (findString core Rstr) != undefined)
            local hasL = (Lstr != "" and (findString core Lstr) != undefined)

            if hasR then  -- 右侧骨骼：替换R为L（解决选右侧无法匹配左侧的核心）
                t = substituteString core Rstr Lstr
            else if hasL then  -- 左侧骨骼：替换L为R（保持原有逻辑）
                t = substituteString core Lstr Rstr

            -- 修复2：避免无效替换（如替换后与原核心名相同）
            if t != undefined and t == core then t = undefined
        )
        default: t = undefined
    )
    t
)

fn BM_FindNodeByCoreInParent parentNode tgtCore =
(
    if parentNode == undefined then undefined
    else
    (
        for c in parentNode.children do
            if (BM_CoreName c.name) == tgtCore then return c
        undefined
    )
)

fn BM_GetTopAncestor n =
(
    if n == undefined then undefined
    else
    (
        local cur = n
        while (cur.parent != undefined) do cur = cur.parent
        cur
    )
)

fn BM_FindNodeByCoreInHierarchy root tgtCore =
(
    if root == undefined then undefined
    if (BM_CoreName root.name) == tgtCore then return root
    for c in root.children do
    (
        local found = BM_FindNodeByCoreInHierarchy c tgtCore
        if found != undefined then return found
    )
    undefined
)

fn BM_FindCounterpartNode node mode Lstr Rstr mapStr =
(
    local core    = BM_CoreName node.name
    local tgtCore = BM_FindCounterpartCore core mode Lstr Rstr mapStr
    if tgtCore == undefined then return undefined

    local srcParent = node.parent
    local candidates = #()  -- 修复3：用候选列表存储所有可能的目标骨骼

    -- 1. 尝试在对应父节点下查找（保留原有层级匹配）
    if srcParent != undefined do
    (
        local tgtParent = BM_FindCounterpartNode srcParent mode Lstr Rstr mapStr
        if tgtParent != undefined then
        (
            local inParent = BM_FindNodeByCoreInParent tgtParent tgtCore
            if inParent != undefined do append candidates inParent
        )
    )

    -- 2. 尝试在顶层层级下查找（解决父节点不匹配的情况）
    local top = BM_GetTopAncestor node
    if top != undefined then
    (
        local inHierarchy = BM_FindNodeByCoreInHierarchy top tgtCore
        if inHierarchy != undefined do append candidates inHierarchy
    )

    -- 3. 强制全局查找（最终兜底，解决跨层级/跨父节点匹配问题）
    local globalNode = BM_GlobalFindNodeByCore tgtCore
    if globalNode != undefined do append candidates globalNode

    -- 返回第一个有效且非自身的目标骨骼
    for cand in candidates where cand != undefined and cand != node do
        return cand
        
    undefined
)

/* ---------- 矩阵 ---------- */
fn BM_MakeMirrorMatrix axisStr =
(
    case axisStr of
    (
        "X": (scaleMatrix [-1,1,1])
        "Y": (scaleMatrix [1,-1,1])
        "Z": (scaleMatrix [1,1,-1])
    )
)

/* ---------- 镜像应用 ---------- */
fn BM_ApplyMirrorRecursive node M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing =
(
    local tgt = BM_FindCounterpartNode node mode Lstr Rstr mapStr
    if tgt != undefined and tgt != node then
    (
        local newTM = M * node.transform * M

        if (doPos and doRot and doScl) then tgt.transform = newTM
        else
        (
            if doPos then (try(tgt.pos      = newTM.pos)      catch())
            if doRot then (try(tgt.rotation = newTM.rotation) catch())
            if doScl then (try(tgt.scale    = newTM.scale)    catch())
        )
    )
    else if (not ignoreMissing) then return()

    if doChildren then
        for c in node.children do
            BM_ApplyMirrorRecursive c M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing
)

fn BM_MirrorOneFrame t roots M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing =
(
    at time t
    (
        for r in roots do
            BM_ApplyMirrorRecursive r M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing
    )
)

fn BM_GetRootSelection sel =
(
    local roots = #()
    for n in sel where isValidNode n do
    (
        local isChild = false
        for m in sel where (isValidNode m and m != n) do
            if (try(isAncestor m n) catch false) do (isChild = true; exit)
        if not isChild do append roots n
    )
    roots
)

/* ---------- Preset file IO (适配映射表新结构，加载后强制覆盖为新内置预设) ---------- */
fn BM_EscapeString s =
(
    if s == undefined then return ""
    s = substituteString s "\\" "\\\\"
    s = substituteString s "\"" "\\\""
    s = substituteString s "\n" "\\n"
    s = substituteString s "\r" "\\r"
    s
)

fn BM_SavePresetsToFiles =
(
    local scriptPath = ""
    try( scriptPath = getSourceFileName() ) catch(scriptPath = "")
    local baseDir = if scriptPath != "" then getFilenamePath scriptPath else (getDir #userScripts)
    local jsonPath = baseDir + "BoneMirrorPresets.json"
    local msPath   = baseDir + "BoneMirrorPresets.ms"
    local legacyJson = baseDir + "双重预设文件(勿删).json"
    local legacyMs   = baseDir + "双重预设文件(勿删).ms"

    -- JSON序列化：适配映射表的#(名称, 完整文本)结构
    fn ArrToJson arr mode =
    (
        local s = "["
        for i = 1 to arr.count do
        (
            local p = arr[i]
            local name = BM_EscapeString p[1]
            if mode == "map" then
            (
                -- 映射表：存储name和完整mapText
                local mapText = BM_EscapeString p[2]
                s += "{\"name\":\"" + name + "\",\"mapText\":\"" + mapText + "\"}"
            )
            else
            (
                -- 其他模式：存储name、L、R
                local l = BM_EscapeString p[2]
                local r = BM_EscapeString p[3]
                s += "{\"name\":\"" + name + "\",\"l\":\"" + l + "\",\"r\":\"" + r + "\"}"
            )
            if i < arr.count then s += ","
        )
        s += "]"
        s
    )

    local jsonText = "{\n"
    jsonText += "\"prefix\": " + ArrToJson prefixPresets "other" + ",\n"
    jsonText += "\"suffix\": " + ArrToJson suffixPresets "other" + ",\n"
    jsonText += "\"contain\": " + ArrToJson containPresets "other" + ",\n"
    jsonText += "\"map\": " + ArrToJson mapPresets "map" + "\n"
    jsonText += "}\n"

    -- 写入JSON文件
    try
    (
        local f = createFile jsonPath
        format "%\n" jsonText to:f
        close f
    ) catch()
    try
    (
        local f2 = createFile legacyJson
        format "%\n" jsonText to:f2
        close f2
    ) catch()

    -- MaxScript文件序列化：适配映射表结构
    fn ArrToMs arr mode =
    (
        local s = "#(\n"
        for i = 1 to arr.count do
        (
            local p = arr[i]
            local n = BM_EscapeString p[1]
            if mode == "map" then
            (
                -- 映射表：#(名称, 完整mapText)
                local mapText = BM_EscapeString p[2]
                s += "#(\"" + n + "\", \"" + mapText + "\")"
            )
            else
            (
                -- 其他模式：#(名称, L, R)
                local l = BM_EscapeString p[2]
                local r = BM_EscapeString p[3]
                s += "#(\"" + n + "\", \"" + l + "\", \"" + r + "\")"
            )
            if i < arr.count then s += ",\n"
        )
        s += "\n)"
        s
    )

    local msText = "global prefixPresets, suffixPresets, containPresets, mapPresets\n"
    msText += "prefixPresets = " + ArrToMs prefixPresets "other" + "\n"
    msText += "suffixPresets = " + ArrToMs suffixPresets "other" + "\n"
    msText += "containPresets = " + ArrToMs containPresets "other" + "\n"
    msText += "mapPresets = " + ArrToMs mapPresets "map" + "\n"

    -- 写入MaxScript文件
    try
    (
        local fm = createFile msPath
        format "%\n" msText to:fm
        close fm
    ) catch()
    try
    (
        local fm2 = createFile legacyMs
        format "%\n" msText to:fm2
        close fm2
    ) catch()
)

fn BM_LoadPresetsFromFiles =
(
    local scriptPath = ""
    try( scriptPath = getSourceFileName() ) catch(scriptPath = "")
    local baseDir = if scriptPath != "" then getFilenamePath scriptPath else (getDir #userScripts)
    local msPath   = baseDir + "BoneMirrorPresets.ms"
    local legacyMs = baseDir + "双重预设文件(勿删).ms"

    -- 优先加载.ms文件（但加载后会强制覆盖映射表预设为新内置）
    if doesFileExist msPath then
    (
        try (fileIn msPath) catch()
    )
    else if doesFileExist legacyMs then
    (
        try (fileIn legacyMs) catch()
    )

    -- 关键修复：强制映射表预设为新的内置预设，覆盖旧文件加载的内容
    mapPresets = #()
    for p in mapBuiltins do append mapPresets p

    -- 其他模式预设确保初始化（不受影响）
    if prefixPresets == undefined then prefixPresets = copy prefixBuiltins
    if suffixPresets == undefined then suffixPresets = copy suffixBuiltins
    if containPresets == undefined then containPresets = copy containBuiltins

    -- 确保其他模式内置预设在最前面（去重）
    fn EnsureBuiltinsAtFront arrRef builtins mode =
    (
        if arrRef == undefined then arrRef = #()
        for i = builtins.count to 1 by -1 do
        (
            local b = builtins[i]
            local j = 1
            while j <= arrRef.count do
            (
                local match = false
                if mode == "map" then
                (
                    -- 映射表：按名称和mapText去重（这里mapPresets已强制为新内置，此逻辑仅为兼容）
                    if arrRef[j][1] == b[1] and arrRef[j][2] == b[2] then match = true
                )
                else
                (
                    -- 其他模式：按L和R去重
                    if arrRef[j][2] == b[2] and arrRef[j][3] == b[3] then match = true
                )
                if match then deleteItem arrRef j else j += 1
            )
            insertItem b arrRef 1
        )
        arrRef
    )

    prefixPresets = EnsureBuiltinsAtFront prefixPresets prefixBuiltins "other"
    suffixPresets = EnsureBuiltinsAtFront suffixPresets suffixBuiltins "other"
    containPresets = EnsureBuiltinsAtFront containPresets containBuiltins "other"
    mapPresets = EnsureBuiltinsAtFront mapPresets mapBuiltins "map"  -- 再次确认映射表预设

    true
)

/* ---------- 预设名称输入弹窗 ---------- */
fn BM_PromptString prompt defaultText =
(
    try
    (
        local gs = getString prompt defaultText
        if gs != undefined then return gs
    ) catch()

    try
    (
        local win = dotNetObject "System.Windows.Forms.Form"
        win.Text = prompt
        win.FormBorderStyle = (dotNetClass "System.Windows.Forms.FormBorderStyle").FixedDialog
        win.StartPosition = (dotNetClass "System.Windows.Forms.FormStartPosition").CenterScreen
        win.ClientSize = dotNetObject "System.Drawing.Size" 360 120
        win.MaximizeBox = false
        win.MinimizeBox = false
        win.ShowInTaskbar = false
        win.TopMost = true

        local lbl = dotNetObject "System.Windows.Forms.Label"
        lbl.Text = prompt
        lbl.AutoSize = false
        lbl.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleLeft
        lbl.Bounds = dotNetObject "System.Drawing.Rectangle" 10 10 340 20

        local txt = dotNetObject "System.Windows.Forms.TextBox"
        txt.Bounds = dotNetObject "System.Drawing.Rectangle" 10 35 340 22
        txt.Text = (if defaultText != undefined then defaultText else "")

        local btnOk = dotNetObject "System.Windows.Forms.Button"
        btnOk.Text = "确定"
        btnOk.DialogResult = (dotNetClass "System.Windows.Forms.DialogResult").OK
        btnOk.Bounds = dotNetObject "System.Drawing.Rectangle" 200 70 75 25

        local btnCancel = dotNetObject "System.Windows.Forms.Button"
        btnCancel.Text = "取消"
        btnCancel.DialogResult = (dotNetClass "System.Windows.Forms.DialogResult").Cancel
        btnCancel.Bounds = dotNetObject "System.Drawing.Rectangle" 285 70 75 25

        win.Controls.AddRange #(lbl, txt, btnOk, btnCancel)
        win.AcceptButton = btnOk
        win.CancelButton = btnCancel

        local res = win.ShowDialog()
        if res == (dotNetClass "System.Windows.Forms.DialogResult").OK then
        (
            local out = txt.Text
            win.Dispose()
            return out
        )
        else
        (
            win.Dispose()
            return undefined
        )
    ) catch
    (
        local resq = queryBox prompt
        if resq then return defaultText else return undefined
    )
)

/* ---------- 修复弹窗：内置预设删除拒绝（无WordWrap，手动换行） ---------- */
fn BM_ShowBuiltinDenyDialog =
(
    -- 获取图片路径
    local scriptPath = ""
    try( scriptPath = getSourceFileName() ) catch(scriptPath = "")
    local imgPath = ""
    if scriptPath != "" then
    (
        local baseDir = getFilenamePath scriptPath
        local uiDir = baseDir + "UI\\"
        if doesFileExist (uiDir + "005.gif") then
            imgPath = uiDir + "005.gif"
        else if doesFileExist (uiDir + "005.png") then
            imgPath = uiDir + "005.png"
        end
    )

    -- 创建弹窗窗口
    local win = dotNetObject "System.Windows.Forms.Form"
    win.Text = "哦豁完蛋~"
    win.FormBorderStyle = (dotNetClass "System.Windows.Forms.FormBorderStyle").FixedDialog
    win.StartPosition = (dotNetClass "System.Windows.Forms.FormStartPosition").CenterScreen
    win.ClientSize = dotNetObject "System.Drawing.Size" 380 140
    win.MaximizeBox = false
    win.MinimizeBox = false
    win.ShowInTaskbar = false
    win.TopMost = true
    win.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 255 255 255

    -- 左侧图片控件
    local pic = dotNetObject "System.Windows.Forms.PictureBox"
    pic.Bounds = dotNetObject "System.Drawing.Rectangle" 10 10 120 120
    pic.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage
    pic.BackColor = (dotNetClass "System.Drawing.Color").Transparent
    if imgPath != "" and doesFileExist imgPath then
    (
        try(pic.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath) catch()
    )
    win.Controls.Add(pic)

    -- 右侧文字（手动\n换行，无WordWrap）
    local lbl = dotNetObject "System.Windows.Forms.Label"
    lbl.Bounds = dotNetObject "System.Drawing.Rectangle" 160 10 200 80
    lbl.Text = "想删我的预设？\n门都没有！"
    lbl.AutoSize = false
    lbl.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter
    lbl.Font = dotNetObject "System.Drawing.Font" "微软雅黑" 15
    win.Controls.Add(lbl)

    -- 确定按钮
    local btnOk = dotNetObject "System.Windows.Forms.Button"
    btnOk.Text = "Man!What can I say?"
    btnOk.DialogResult = (dotNetClass "System.Windows.Forms.DialogResult").OK
    btnOk.Bounds = dotNetObject "System.Drawing.Rectangle" 155 100 200 25
    win.Controls.Add(btnOk)
    win.AcceptButton = btnOk

    -- 显示并释放
    win.ShowDialog()
    win.Dispose()
)

/* ---------- UI 卷展栏（修正映射表预设显示/保存） ---------- */
rollout BoneMirrorRollout "镜像工具v2.2" width:230 height:710
(
    -- 镜像轴相关控件
    dotNetControl pic_axis "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"镜像轴功能图标标识，用于视觉区分镜像轴设置区域"
    label lbl_axis "镜像轴:" align:#left offset:[25,-21] tooltip:"标识下方下拉框的功能：选择骨骼镜像操作所基于的坐标轴"
    dropdownlist ddl_axis "" items:#("X","Y","Z") selection:1 tooltip:"选择镜像操作的基准坐标轴（X/Y/Z），需根据骨骼在场景中的朝向选择，确保镜像后姿态符合预期"
    checkbox     chk_children "包含子骨骼" checked:true tooltip:"控制镜像范围：勾选时同时处理选中骨骼的所有子骨骼，未勾选时仅处理选中的顶层骨骼"
    checkbox     chk_ignoreMissing "遇缺失节点继续" checked:true tooltip:"处理异常场景：勾选时若找不到某骨骼的对侧节点，跳过该节点继续处理其他骨骼；未勾选时直接停止操作"

    -- 匹配模式分隔线与控件
    button sep_mode_top "" enabled:false height:3
    dotNetControl pic_mode "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"匹配模式功能图标标识，用于视觉区分骨骼匹配模式设置区域"
    label lbl_mode "匹配模式" align:#left offset:[25,-21] tooltip:"标识下方下拉框的功能：选择识别骨骼左右对侧的匹配逻辑"
    dropdownlist ddl_mode "" items:#("前缀","后缀","包含","映射表优先") selection:3 tooltip:"选择骨骼对侧匹配模式：\n1.前缀：按骨骼名称前缀识别左右（如LeftArm/RightArm）\n2.后缀：按骨骼名称后缀识别左右（如Arm_L/Arm_R）\n3.包含：按名称中包含的字符识别左右（如ArmLeft/ArmRight）\n4.映射表优先：优先按自定义映射表匹配，无匹配时 fallback 到上述规则"
    button sep_mode_bot "" enabled:false height:3

    -- 命名规则分隔线与控件
    button sep_rule_top "" enabled:false height:3
    dotNetControl pic_rule "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"命名规则功能图标标识，用于视觉区分骨骼命名规则设置区域"
    label lbl_grp1 "命名规则 (对侧匹配)" align:#left offset:[25,-21] tooltip:"标识该区域功能：设置当前匹配模式下，识别骨骼左右对侧的具体参数"
    dropdownlist ddl_preset "命名预设：" items:#("自定义") selection:1 tooltip:"加载已保存的命名规则预设：选择‘自定义’可手动输入参数，选择其他预设可快速应用常用配置"
    button btn_savePreset "保存为预设" height:22 tooltip:"将当前设置的命名规则（L/R字符串或映射表内容）保存为新预设，方便后续重复使用"
    button btn_delPreset "删除预设" height:22 tooltip:"删除当前选中的预设（内置预设不可删除），删除后无法恢复，请确认后操作"

    -- L/R字符串设置控件
    label    lblL "左侧字符串 (L):" tooltip:"标识左侧骨骼的名称标识（如L_、Left），用于在非映射表模式下识别左侧骨骼"
    edittext edt_L "" text:"L_" fieldwidth:80 tooltip:"输入左侧骨骼的名称标识字符串（如L_、Left），需与右侧标识字符串对应（非映射表模式生效）"
    label    lblR "右侧字符串 (R):" tooltip:"标识右侧骨骼的名称标识（如R_、Right），用于在非映射表模式下识别右侧骨骼"
    edittext edt_R "" text:"R_" fieldwidth:80 tooltip:"输入右侧骨骼的名称标识字符串（如R_、Right），需与左侧标识字符串对应（非映射表模式生效）"

    -- 映射表设置控件
    label lblMap "映射表 (每行 key=value)： " tooltip:"自定义骨骼映射关系的输入区域，仅在‘映射表优先’模式下生效，每行格式为‘源骨骼标识=目标骨骼标识’"
    edittext edt_Map "" text:"" width:190 height:80 style:#multiLine tooltip:"输入自定义骨骼映射规则：\n1.每行一条规则，格式为‘key=value’（如SpiderMan_01=BatMan_114514）\n2.支持双向匹配（key可映射到value，value也可映射到key）\n3.仅在‘映射表优先’模式下生效"
    button sep_rule_bot "" enabled:false height:3

    button sep_content_bot2 "" enabled:false height:3

    -- 镜像执行控件
    button btn_mirror "镜像当前帧（支持多链）" height:35 tooltip:"执行骨骼镜像核心操作：将选中骨骼链的姿态（位置/旋转/缩放）镜像到对侧骨骼，支持多骨骼链同时处理，仅对当前时间帧生效"
    label  lbl_info "当前已选择 0 条骨骼链" align:#left tooltip:"实时显示当前场景中选中的骨骼根节点数量（即独立骨骼链的数量），帮助确认操作范围"
    checkbox chk_undo "可撤销" checked:true tooltip:"控制操作是否可撤销：勾选时镜像操作会记录到Max撤销历史，可通过Ctrl+Z撤销；未勾选时操作不可撤销"

    -- 作者信息区域控件
    button sep_author_top "" enabled:false height:3
    dotNetControl pic_author "System.Windows.Forms.PictureBox" width:180 height:45 align:#center tooltip:"作者标识图片，用于展示脚本作者相关信息"
    button sep_author_bot "" enabled:false height:3

    -- 链接按钮控件
    button btn_nexus "N网主页" height:22 tooltip:"点击打开脚本作者在Nexus Mods平台的主页，可查看作者发布的其他资源"
    button btn_bili  "B站主页" height:22 tooltip:"点击打开脚本作者在Bilibili平台的主页，可查看相关教程、动态或联系作者"
    button btn_update "更新地址(GitHub)" height:22 tooltip:"点击打开脚本在GitHub的仓库地址，可获取最新版本、更新日志及源代码"
    button sep_links "" enabled:false height:3
    button btn_surprise "恭喜发现隐藏惊喜按钮！" height:30 tooltip:"Bro！点我有惊喜！"

    -- 刷新预设下拉框（兼容映射表新结构）
    fn BM_UpdatePresetDropdown =
    (
        local mode = ddl_mode.items[ddl_mode.selection]
        local items = #("自定义")
        -- 关键：遍历新的mapPresets，确保显示新预设
        case mode of
        (
            "前缀": for p in prefixPresets do append items p[1]
            "后缀": for p in suffixPresets do append items p[1]
            "包含": for p in containPresets do append items p[1]
            "映射表优先": for p in mapPresets do append items p[1]  -- 这里必然是新的两个预设
            default: ()
        )
        ddl_preset.items = items
        ddl_preset.selection = 1
    )

    -- 保存预设（区分映射表和其他模式）
    fn BM_AddPresetNamed mode name data =
    (
        if name == undefined or name == "" then return()
        case mode of
        (
            "前缀": append prefixPresets #(name, data[1], data[2])
            "后缀": append suffixPresets #(name, data[1], data[2])
            "包含": append containPresets #(name, data[1], data[2])
            "映射表优先": append mapPresets #(name, data[1])  -- 存储#(名称, 完整映射文本)
            default: ()
        )
        BM_UpdatePresetDropdown()
        BM_SavePresetsToFiles()
        ddl_preset.selection = ddl_preset.items.count
    )

    -- 删除预设（兼容映射表结构）
    fn BM_DeletePresetAt mode idx =
    (
        if idx < 1 then return false

        -- 计算内置预设数量（映射表现在是2个）
        local builtinCount = 0
        case mode of
        (
            "前缀": builtinCount = prefixBuiltins.count
            "后缀": builtinCount = suffixBuiltins.count
            "包含": builtinCount = containBuiltins.count
            "映射表优先": builtinCount = mapBuiltins.count  -- 现在是2个（SuperHero和两个傻逼）
            default: builtinCount = 0
        )

        -- 内置预设禁止删除
        if idx <= builtinCount then
        (
            BM_ShowBuiltinDenyDialog()
            return false
        )

        -- 执行删除
        case mode of
        (
            "前缀":
            (
                if idx <= prefixPresets.count then
                (
                    prefixPresets = for i = 1 to prefixPresets.count where i != idx collect prefixPresets[i]
                    true
                )
                else false
            )
            "后缀":
            (
                if idx <= suffixPresets.count then
                (
                    suffixPresets = for i = 1 to suffixPresets.count where i != idx collect suffixPresets[i]
                    true
                )
                else false
            )
            "包含":
            (
                if idx <= containPresets.count then
                (
                    containPresets = for i = 1 to containPresets.count where i != idx collect containPresets[i]
                    true
                )
                else false
            )
            "映射表优先":
            (
                if idx <= mapPresets.count then
                (
                    mapPresets = for i = 1 to mapPresets.count where i != idx collect mapPresets[i]
                    true
                )
                else false
            )
            default: false
        )
    )

    -- 布局调整
    fn BM_AdjustLayout =
    (
        local margin = 10
        local usableW = BoneMirrorRollout.width - margin*2
        for c in #(ddl_axis, chk_children, chk_ignoreMissing,
                   sep_mode_top, ddl_mode, sep_mode_bot,
                   sep_rule_top, ddl_preset, btn_savePreset, btn_delPreset, edt_L, edt_R, lblL, lblR, lblMap, edt_Map, sep_rule_bot,
                   sep_content_bot2,
                   btn_mirror, lbl_info, chk_undo, sep_author_top, pic_author, sep_author_bot,
                   btn_nexus, btn_bili, btn_update, sep_links,
                   btn_surprise) do
        (
            try(c.pos.x = margin) catch()
            try(c.width = usableW) catch()
        )
        
        -- 确保Ash.png高度固定，宽度按比例自动调整，并居中显示
        try(
            -- 保持固定高度为背景区域高度
            pic_author.Height = 45;
            -- 宽度根据图片比例自动调整，不超过可用宽度
            local maxWidth = usableW;
            if pic_author.Image != undefined then
            (
                -- 计算按高度缩放后的宽度
                local imgRatio = pic_author.Image.Width as float / pic_author.Image.Height as float
                local autoWidth = (pic_author.Height * imgRatio) as integer
                -- 确保不超过最大宽度
                pic_author.Width = if autoWidth > maxWidth then maxWidth else autoWidth
            )
            -- 居中显示
            pic_author.pos.x = (BoneMirrorRollout.width - pic_author.width)/2
        ) catch()
    )

    -- 更新选中骨骼链数量
    fn BM_UpdateInfo =
    (
        local selRoots = BM_GetRootSelection (selection as array)
        lbl_info.text = "当前已选择 " + (selRoots.count as string) + " 条骨骼链"
    )

    -- 卷展栏打开时初始化（强制刷新映射表预设）
    on BoneMirrorRollout open do
    (
        BM_AdjustLayout()
        BM_UpdateInfo()

        -- 加载预设后，强制刷新映射表预设（确保是新的）
        BM_LoadPresetsFromFiles()
        BM_UpdatePresetDropdown()  -- 这里会重新读取mapPresets，显示新预设

        -- 监听选择变化
        callbacks.removeScripts id:#BM_SelUpdate
        callbacks.addScript #selectionSetChanged "try(BoneMirrorRollout.BM_UpdateInfo())catch()" id:#BM_SelUpdate

        -- 加载UI图片
        local scriptPath = ""
        try( scriptPath = getSourceFileName() ) catch(scriptPath = "")
        if scriptPath != "" then
        (
            local baseDir = getFilenamePath scriptPath
            local uiDir = baseDir + "UI\\"

            local imgPath1 = uiDir + "001.png"
            if doesFileExist imgPath1 then
                try(
                    pic_axis.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath1; 
                    pic_axis.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").Zoom;
                    pic_axis.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68
                ) catch()

            local imgPath2 = uiDir + "002.png"
            if doesFileExist imgPath2 then
                try(
                    pic_mode.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath2; 
                    pic_mode.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").Zoom;
                    pic_mode.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68
                ) catch()

            local imgPath3 = uiDir + "003.png"
            if doesFileExist imgPath3 then
                try(
                    pic_rule.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath3; 
                    pic_rule.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").Zoom;
                    pic_rule.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68
                ) catch()

            local imgPath4 = uiDir + "Ash.png"
            if doesFileExist imgPath4 then
                try(
                    pic_author.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath4; 
                    pic_author.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").Zoom;
                    pic_author.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68;
                    -- 固定高度为背景区域高度
                    pic_author.Height = 45;
                    -- 触发布局调整以计算宽度
                    BM_AdjustLayout()
                ) catch()
        )
    )

    on BoneMirrorRollout close do callbacks.removeScripts id:#BM_SelUpdate
    on BoneMirrorRollout resized sz do BM_AdjustLayout()

    -- 切换匹配模式时刷新预设（确保映射表显示新预设）
    on ddl_mode selected i do
    (
        BM_UpdatePresetDropdown()  -- 切换到映射表模式时，立即刷新下拉框
    )

    -- 选择预设时填充内容（修正映射表显示）
    on ddl_preset selected i do
    (
        if i > 1 then
        (
            local mode = ddl_mode.items[ddl_mode.selection]
            local arr = undefined
            case mode of
            (
                "前缀": arr = prefixPresets
                "后缀": arr = suffixPresets
                "包含": arr = containPresets
                "映射表优先": arr = mapPresets  -- 这里是新的两个预设
                default: arr = undefined
            )
            if arr != undefined and i-1 <= arr.count then
            (
                local p = arr[i-1]
                if p != undefined then
                (
                    if mode == "映射表优先" then
                    (
                        -- 映射表：填充完整文本到edt_Map（新预设的内容）
                        edt_Map.text = p[2]
                    )
                    else
                    (
                        -- 其他模式：填充L/R到对应输入框
                        edt_L.text = p[2]
                        edt_R.text = p[3]
                    )
                )
            )
        )
    )

    -- 保存预设按钮（修正映射表保存逻辑）
    on btn_savePreset pressed do
    (
        local mode = ddl_mode.items[ddl_mode.selection]
        if mode == "映射表优先" then
        (
            local mapText = edt_Map.text
            -- 验证映射表格式（至少包含一个"="）
            if (findString mapText "=") == undefined then
            (
                messageBox "映射表格式错误！请输入 键=值 格式（例如 ArmL=ArmR）"
                return()
            )
            -- 生成默认名称（取第一个"="前的内容）
            local defaultName = (substring mapText 1 (findString mapText "=" - 1)) + "映射"
            local name = BM_PromptString "请输入映射表预设名称：" defaultName
            if name != undefined then
            (
                BM_AddPresetNamed mode name #(mapText)
                messageBox "已保存映射表预设并更新文件！"
            )
        )
        else
        (
            local l = edt_L.text
            local r = edt_R.text
            if l == "" and r == "" then
            (
                messageBox "L和R字符串不能都为空！"
                return()
            )
            local defaultName = l + "/" + r
            local name = BM_PromptString "请输入预设名称：" defaultName
            if name != undefined then
            (
                BM_AddPresetNamed mode name #(l, r)
                messageBox "已保存预设并更新文件！"
            )
        )
    )

    -- 删除预设按钮（逻辑不变，调用修复后的弹窗）
    on btn_delPreset pressed do
    (
        local sel = ddl_preset.selection
        if sel <= 1 then
        (
            messageBox "你都没选预设你想删什么？"
            return()
        )

        local presetName = ddl_preset.items[sel]
        local confirmDelete = queryBox ("确定要删除预设 '" + presetName + "' 吗？\n删了可找不回来的喔！") title:"确认删除"
        
        if confirmDelete then
        (
            local mode = ddl_mode.items[ddl_mode.selection]
            local idx = sel - 1  -- 预设数组索引（跳过"自定义"）
            local ok = BM_DeletePresetAt mode idx
            if ok then
            (
                BM_UpdatePresetDropdown()
                BM_SavePresetsToFiles()
                messageBox "已删除预设并更新文件！"
            )
        )
    )

    -- 镜像按钮行为（保持不变）
    on btn_mirror pressed do
    (
        local selRoots = BM_GetRootSelection (selection as array)
        if selRoots.count == 0 then
        (
            messageBox "那我问你，骨骼都不选你想镜像什么？啊？你回答我！"
            return()
        )

        local axisStr       = ddl_axis.items[ddl_axis.selection]
        local mode          = ddl_mode.items[ddl_mode.selection]
        local Lstr          = edt_L.text
        local Rstr          = edt_R.text
        local mapStr        = edt_Map.text
        local ignoreMissing = chk_ignoreMissing.checked

        local M      = BM_MakeMirrorMatrix axisStr
        local doPos  = true
        local doRot  = true
        local doScl  = true
        local doChildren = chk_children.checked

        if chk_undo.checked then
        (
            undo "Bone Mirror" on
            (
                with animate on
                (
                    BM_MirrorOneFrame currentTime selRoots M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing
                )
            )
        )
        else
        (
            with animate on
            (
                BM_MirrorOneFrame currentTime selRoots M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing
            )
        )
    )

    -- 链接按钮（保持不变）
    on btn_nexus pressed do shellLaunch "https://next.nexusmods.com/profile/ashtoash815/mods" ""
    on btn_bili pressed do shellLaunch "https://space.bilibili.com/3493272253106937?spm_id_from=333.337.0.0" ""
    on btn_update pressed do shellLaunch "https://github.com/AshToAsh815/3dsMax-Bones-mirror-tool-v1.1" ""
    on btn_surprise pressed do shellLaunch "https://www.bilibili.com/video/BV1GJ411x7h7/" ""
)

/* ---------- 显示与宏定义 ---------- */
fn BM_Show =
(
    try(destroyDialog BoneMirrorRollout) catch()
    createDialog BoneMirrorRollout 170 710 \
        style:#(#style_titlebar,#style_sysmenu,#style_resizing) \
        dockable:true
)

macroScript BoneMirrorTool
category:"Bone Tools"
toolTip:"Ash-骨骼姿态镜像（修复版）"
buttonText:"Ash-骨骼镜像"
(
    on execute do BM_Show()
)

-- 强制初始化后，立即显示卷展栏
BM_Show()
    