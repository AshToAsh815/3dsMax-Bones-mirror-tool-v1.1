global BoneMirrorRollout 

/* ---------- 字符串辅助 ---------- */
fn BM_StripPrefix nm =
(
    local p = findString nm ":"
    if p != undefined then
        #(substring nm 1 p, substring nm (p+1) (nm.count - p))
    else
        #("", nm)
)

fn BM_CoreName nm =
(
    local pr = BM_StripPrefix nm
    pr[2]
)

fn BM_StartsWith s prefix =
(
    (prefix != "") and matchPattern s pattern:(prefix + "*")
)
fn BM_EndsWith s suffix =
(
    (suffix != "") and matchPattern s pattern:("*" + suffix)
)

/* ---------- 映射表解析 ---------- */
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

/* ---------- 查找目标骨骼 ---------- */
fn BM_FindCounterpartCore core mode Lstr Rstr mapStr =
(
    local t = undefined
    if mode == "映射表优先" do
    (
        t = BM_MapByTable core mapStr
        if t != undefined then return t
    )

    case mode of
    (
        "前缀": if BM_StartsWith core Lstr then t = substituteString core Lstr Rstr
                else if BM_StartsWith core Rstr then t = substituteString core Rstr Lstr
        "后缀": if BM_EndsWith core Lstr then
                    t = (substring core 1 (core.count - Lstr.count)) + Rstr
                else if BM_EndsWith core Rstr then
                    t = (substring core 1 (core.count - Rstr.count)) + Lstr
        "包含": if (Lstr != "" and (findString core Lstr) != undefined) then
                    t = substituteString core Lstr Rstr
                else if (Rstr != "" and (findString core Rstr) != undefined) then
                    t = substituteString core Rstr Lstr
        "映射表优先": t = BM_MapByTable core mapStr
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
    if srcParent != undefined do
    (
        local tgtParent = BM_FindCounterpartNode srcParent mode Lstr Rstr mapStr
        if tgtParent != undefined then
        (
            local inParent = BM_FindNodeByCoreInParent tgtParent tgtCore
            if inParent != undefined then return inParent
        )
    )

    local top = BM_GetTopAncestor node
    if top != undefined then
    (
        local found = BM_FindNodeByCoreInHierarchy top tgtCore
        if found != undefined then return found
    )
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
    if tgt != undefined and tgt != node then  -- 避免自己镜像自己
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

/* ---------- UI ---------- */
rollout BoneMirrorRollout "镜像工具v1.1" width:230 height:585
(
    dotNetControl pic_axis "System.Windows.Forms.PictureBox" width:21 height:21
    label lbl_axis "镜像轴:" align:#left offset:[25,-21]
    dropdownlist ddl_axis "" items:#("X","Y","Z") selection:1 offset:[25,0]
    checkbox     chk_children "包含子骨骼" checked:true
    checkbox     chk_ignoreMissing "遇缺失节点继续" checked:true

    button sep_mode_top "" enabled:false height:3
    dotNetControl pic_mode "System.Windows.Forms.PictureBox" width:21 height:21
    label lbl_mode "匹配模式" align:#left offset:[25,-21]
    dropdownlist ddl_mode "" items:#("前缀","后缀","包含","映射表优先") selection:3 offset:[25,0]

    button sep_mode_bot "" enabled:false height:3

    button sep_rule_top "" enabled:false height:3
    dotNetControl pic_rule "System.Windows.Forms.PictureBox" width:21 height:21
    label lbl_grp1 "命名规则 (对侧匹配)" align:#left offset:[25,-21]
    label    lblL "左侧字符串 (L):"
    edittext edt_L "" text:"L_" fieldwidth:80
    label    lblR "右侧字符串 (R):"
    edittext edt_R "" text:"R_" fieldwidth:80
    label lblMap "映射表 (每行 key=value)： "
    edittext edt_Map "" text:"" width:190 height:80 style:#multiLine
    button sep_rule_bot "" enabled:false height:3

    button sep_content_bot2 "" enabled:false height:3

    button btn_mirror "镜像当前帧（支持多链）" height:35
    label  lbl_info "当前已选择 0 条骨骼链" align:#left
    checkbox chk_undo "可撤销" checked:true

    button sep_author_top "" enabled:false height:3
    dotNetControl pic_author "System.Windows.Forms.PictureBox" width:180 height:45 align:#center
    button sep_author_bot "" enabled:false height:3

    button btn_nexus "N网主页" height:22
    button btn_bili  "B站主页" height:22
    button btn_update "更新地址(GitHub)" height:22  -- ★ 新增按钮
    button sep_links "" enabled:false height:3
    button btn_surprise "恭喜发现隐藏惊喜按钮！" height:30

    fn BM_AdjustLayout =
    (
        local margin = 10
        local usableW = BoneMirrorRollout.width - margin*2
        for c in #(ddl_axis, chk_children, chk_ignoreMissing,
                   sep_mode_top, ddl_mode, sep_mode_bot,
                   sep_rule_top, edt_L, edt_R, lblL, lblR, lblMap, edt_Map, sep_rule_bot,
                   sep_content_bot2,
                   btn_mirror, lbl_info, chk_undo, sep_author_top, pic_author, sep_author_bot,
                   sep_links, btn_nexus, btn_bili, btn_update,
                   btn_surprise) do
        (
            try(c.pos.x = margin) catch()
            try(c.width = usableW) catch()
        )
    )

    fn BM_UpdateInfo =
    (
        local selRoots = BM_GetRootSelection (selection as array)
        lbl_info.text = "当前已选择 " + (selRoots.count as string) + " 条骨骼链"
    )

    on BoneMirrorRollout open do
    (
        BM_AdjustLayout()
        BM_UpdateInfo()
        callbacks.removeScripts id:#BM_SelUpdate
        callbacks.addScript #selectionSetChanged "try(BoneMirrorRollout.BM_UpdateInfo())catch()" id:#BM_SelUpdate

        -- ========== 图片加载 ==========
        local scriptPath = ""
        try( scriptPath = getSourceFileName() ) catch(scriptPath = "")

        if scriptPath != "" then
        (
            local baseDir = getFilenamePath scriptPath
            local uiDir = baseDir + "UI\\"

            local imgPath1 = uiDir + "001.png"
            if doesFileExist imgPath1 then
            (
                try
                (
                    pic_axis.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath1
                    pic_axis.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage
                    pic_axis.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68
                    pic_axis.visible = true
                ) catch()
            )

            local imgPath2 = uiDir + "002.png"
            if doesFileExist imgPath2 then
            (
                try
                (
                    pic_mode.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath2
                    pic_mode.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage
                    pic_mode.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68
                    pic_mode.visible = true
                ) catch()
            )

            local imgPath3 = uiDir + "003.png"
            if doesFileExist imgPath3 then
            (
                try
                (
                    pic_rule.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath3
                    pic_rule.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage
                    pic_rule.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68
                    pic_rule.visible = true
                ) catch()
            )

            local imgPath4 = uiDir + "Ash.png"
            if doesFileExist imgPath4 then
            (
                try
                (
                    pic_author.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath4
                    pic_author.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").Zoom
                    pic_author.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68
                    pic_author.visible = true
                ) catch()
            )
        )
    )
    on BoneMirrorRollout close do callbacks.removeScripts id:#BM_SelUpdate
    on BoneMirrorRollout resized sz do BM_AdjustLayout()

    on btn_mirror pressed do
    (
        local selRoots = BM_GetRootSelection (selection as array)
        if selRoots.count == 0 then
        (
            messageBox "请先选择骨骼链的根节点。"
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

    on btn_nexus pressed do
    (
        shellLaunch "https://next.nexusmods.com/profile/ashtoash815/mods" ""
    )
    on btn_bili pressed do
    (
        shellLaunch "https://space.bilibili.com/3493272253106937?spm_id_from=333.337.0.0" ""
    )
    on btn_update pressed do
    (
        shellLaunch "" ""  -- ★ 网址留空占位
    )
    on btn_surprise pressed do
    (
        shellLaunch "https://www.bilibili.com/video/BV1GJ411x7h7/" ""
    )
)

/* ---------- 显示 & 宏 ---------- */
fn BM_Show =
(
    try(destroyDialog BoneMirrorRollout) catch()
    createDialog BoneMirrorRollout 170 610 \
        style:#(#style_titlebar,#style_sysmenu,#style_resizing) \
        dockable:true
)

macroScript BoneMirrorTool
category:"Bone Tools"
toolTip:"Ash-骨骼姿态镜像"
buttonText:"Ash-骨骼镜像"
(
    on execute do BM_Show()
)

BM_Show()
