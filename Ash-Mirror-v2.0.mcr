-- 3ds Max MacroScript Command File (.mcr)
-- 仅适配MCR格式，保留所有原始逻辑与内容

global BoneMirrorRollout

/* ---------- Preset storage (Force replace mapping table presets, not affected by old files) ---------- */
global prefixBuiltins, suffixBuiltins, containBuiltins, mapBuiltins
global prefixPresets, suffixPresets, containPresets, mapPresets

-- 1. Mapping table built-in presets (Force replace with specified 2, remove old arm/leg mappings)
mapBuiltins = #(  -- Remove if judgment here, force overwrite old values regardless of previous definitions
    #("SuperHero", "SpiderMan_01=BatMan_114514"),
    #("两个傻逼", "冥月千雪=你的中二魔王\n你的中二魔王=绝世大傻逼\nDante陽=绝世大傻逼\n你的中二魔王=Dante陽")
)
-- Mapping table user presets: Force initialize based on new built-in presets, overwrite content loaded from old files
mapPresets = #()
for p in mapBuiltins do append mapPresets p

-- 2. Other modes' built-in presets (Keep original structure, only ensure initialization)
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
-- Other modes' user presets initialization (Only if undefined)
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

/* ---------- String Helpers ---------- */
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

/* ---------- Mapping Table Parsing (Keep original logic, compatible with full mapping text) ---------- */
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

/* ---------- Find Target Bone ---------- */
fn BM_FindCounterpartCore core mode Lstr Rstr mapStr =
(
    local t = undefined

    -- Mapping Table Priority Mode: Try mapping table first, then fallback to L/R rules
    if mode == "Mapping Table Priority" then
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

    -- Other modes' logic remains unchanged
    case mode of
    (
        "Prefix":
        (
            if BM_StartsWith core Lstr then t = substituteString core Lstr Rstr
            else if BM_StartsWith core Rstr then t = substituteString core Rstr Lstr
        )
        "Suffix":
        (
            if BM_EndsWith core Lstr then
                t = (substring core 1 (core.count - Lstr.count)) + Rstr
            else if BM_EndsWith core Rstr then
                t = (substring core 1 (core.count - Rstr.count)) + Lstr
        )
        "Contain":
        (
            if (Lstr != "" and (findString core Lstr) != undefined) then
                t = substituteString core Lstr Rstr
            else if (Rstr != "" and (findString core Rstr) != undefined) then
                t = substituteString core Rstr Lstr
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

/* ---------- Matrix ---------- */
fn BM_MakeMirrorMatrix axisStr =
(
    case axisStr of
    (
        "X": (scaleMatrix [-1,1,1])
        "Y": (scaleMatrix [1,-1,1])
        "Z": (scaleMatrix [1,1,-1])
    )
)

/* ---------- Mirror Application ---------- */
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

/* ---------- Preset file IO (Adapt to new mapping table structure, force overwrite to new built-in presets after loading) ---------- */
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

    -- JSON Serialization: Adapt to mapping table's #(name, full text) structure
    fn ArrToJson arr mode =
    (
        local s = "["
        for i = 1 to arr.count do
        (
            local p = arr[i]
            local name = BM_EscapeString p[1]
            if mode == "map" then
            (
                -- Mapping table: Store name and full mapText
                local mapText = BM_EscapeString p[2]
                s += "{\"name\":\"" + name + "\",\"mapText\":\"" + mapText + "\"}"
            )
            else
            (
                -- Other modes: Store name, L, R
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

    -- Write JSON file
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

    -- MaxScript file serialization: Adapt to mapping table structure
    fn ArrToMs arr mode =
    (
        local s = "#(\n"
        for i = 1 to arr.count do
        (
            local p = arr[i]
            local n = BM_EscapeString p[1]
            if mode == "map" then
            (
                -- Mapping table: #(name, full mapText)
                local mapText = BM_EscapeString p[2]
                s += "#(\"" + n + "\", \"" + mapText + "\")"
            )
            else
            (
                -- Other modes: #(name, L, R)
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

    -- Write MaxScript file
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

    -- Prioritize loading .ms file (but force overwrite mapping table presets to new built-in ones after loading)
    if doesFileExist msPath then
    (
        try (fileIn msPath) catch()
    )
    else if doesFileExist legacyMs then
    (
        try (fileIn legacyMs) catch()
    )

    -- Critical Fix: Force mapping table presets to new built-in ones, overwrite content loaded from old files
    mapPresets = #()
    for p in mapBuiltins do append mapPresets p

    -- Ensure other modes' presets are initialized (unaffected)
    if prefixPresets == undefined then prefixPresets = copy prefixBuiltins
    if suffixPresets == undefined then suffixPresets = copy suffixBuiltins
    if containPresets == undefined then containPresets = copy containBuiltins

    -- Ensure built-in presets are at the top (de-duplicate)
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
                    -- Mapping table: De-duplicate by name and mapText (mapPresets already forced to new built-in, this is for compatibility)
                    if arrRef[j][1] == b[1] and arrRef[j][2] == b[2] then match = true
                )
                else
                (
                    -- Other modes: De-duplicate by L and R
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
    mapPresets = EnsureBuiltinsAtFront mapPresets mapBuiltins "map"  -- Re-confirm mapping table presets

    true
)

/* ---------- Preset Name Input Dialog ---------- */
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
        btnOk.Text = "OK"
        btnOk.DialogResult = (dotNetClass "System.Windows.Forms.DialogResult").OK
        btnOk.Bounds = dotNetObject "System.Drawing.Rectangle" 200 70 75 25

        local btnCancel = dotNetObject "System.Windows.Forms.Button"
        btnCancel.Text = "Cancel"
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

/* ---------- Fix Dialog: Deny Built-in Preset Deletion (No WordWrap, manual line break) ---------- */
fn BM_ShowBuiltinDenyDialog =
(
    -- Get image path
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

    -- Create dialog window
    local win = dotNetObject "System.Windows.Forms.Form"
    win.Text = "Oops, Nope~"
    win.FormBorderStyle = (dotNetClass "System.Windows.Forms.FormBorderStyle").FixedDialog
    win.StartPosition = (dotNetClass "System.Windows.Forms.FormStartPosition").CenterScreen
    win.ClientSize = dotNetObject "System.Drawing.Size" 380 140
    win.MaximizeBox = false
    win.MinimizeBox = false
    win.ShowInTaskbar = false
    win.TopMost = true
    win.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 255 255 255

    -- Left image control
    local pic = dotNetObject "System.Windows.Forms.PictureBox"
    pic.Bounds = dotNetObject "System.Drawing.Rectangle" 10 10 120 120
    pic.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage
    pic.BackColor = (dotNetClass "System.Drawing.Color").Transparent
    if imgPath != "" and doesFileExist imgPath then
    (
        try(pic.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath) catch()
    )
    win.Controls.Add(pic)

    -- Right text (manual \n line break, no WordWrap)
    local lbl = dotNetObject "System.Windows.Forms.Label"
    lbl.Bounds = dotNetObject "System.Drawing.Rectangle" 130 10 250 80
    lbl.Text = "Delete my presets?\nNo way!"
    lbl.AutoSize = false
    lbl.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter
    lbl.Font = dotNetObject "System.Drawing.Font" "Microsoft YaHei" 15
    win.Controls.Add(lbl)

    -- OK button
    local btnOk = dotNetObject "System.Windows.Forms.Button"
    btnOk.Text = "Man!What can I say?"
    btnOk.DialogResult = (dotNetClass "System.Windows.Forms.DialogResult").OK
    btnOk.Bounds = dotNetObject "System.Drawing.Rectangle" 155 100 200 25
    win.Controls.Add(btnOk)
    win.AcceptButton = btnOk

    -- Show and dispose
    win.ShowDialog()
    win.Dispose()
)

/* ---------- UI Rollout (Fix mapping table preset display/save) ---------- */
rollout BoneMirrorRollout "Ash-Mirror v2.0" width:230 height:710
(
    -- Mirror axis related controls
    dotNetControl pic_axis "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"Mirror axis function icon, used to visually distinguish the mirror axis setting area"
    label lbl_axis "Mirror Axis:" align:#left offset:[25,-21] tooltip:"Identifies the function of the dropdown below: Select the coordinate axis for bone mirroring"
    dropdownlist ddl_axis "" items:#("X","Y","Z") selection:1 tooltip:"Select the base coordinate axis for mirroring (X/Y/Z). Choose based on bone orientation in the scene to ensure correct mirrored posture"
    checkbox     chk_children "Include Children" checked:true tooltip:"Control mirror range: Check to process all child bones of selected bones; uncheck to process only top-level selected bones"
    checkbox     chk_ignoreMissing "Continue on Missing Nodes" checked:true tooltip:"Handle abnormal scenarios: Check to skip missing counterpart nodes and continue processing others; uncheck to stop immediately"

    -- Matching mode separator and controls
    button sep_mode_top "" enabled:false height:3
    dotNetControl pic_mode "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"Matching mode function icon, used to visually distinguish the bone matching mode setting area"
    label lbl_mode "Matching Mode" align:#left offset:[25,-21] tooltip:"Identifies the function of the dropdown below: Select the matching logic for identifying left-right bone counterparts"
    dropdownlist ddl_mode "" items:#("Prefix","Suffix","Contain","Mapping Table Priority") selection:3 tooltip:"Select bone counterpart matching mode:\n1.Prefix: Identify left-right by bone name prefix (e.g., LeftArm/RightArm)\n2.Suffix: Identify left-right by bone name suffix (e.g., Arm_L/Arm_R)\n3.Contain: Identify left-right by characters in name (e.g., ArmLeft/ArmRight)\n4.Mapping Table Priority: Use custom mapping table first, fallback to above rules if no match"
    button sep_mode_bot "" enabled:false height:3

    -- Naming rule separator and controls
    button sep_rule_top "" enabled:false height:3
    dotNetControl pic_rule "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"Naming rule function icon, used to visually distinguish the bone naming rule setting area"
    label lbl_grp1 "Naming Rules (Counterpart Match)" align:#left offset:[25,-21] tooltip:"Identifies area function: Set specific parameters for identifying left-right bone counterparts in current mode"
    dropdownlist ddl_preset "Naming Presets:" items:#("Custom") selection:1 tooltip:"Load saved naming rule presets: Select 'Custom' to enter parameters manually; select other presets to apply common configurations quickly"
    button btn_savePreset "Save as Preset" height:22 tooltip:"Save current naming rules (L/R strings or mapping table content) as a new preset for future reuse"
    button btn_delPreset "Delete Preset" height:22 tooltip:"Delete currently selected preset (built-in presets cannot be deleted). Deletion is irreversible, please confirm before proceeding"

    -- L/R string setting controls
    label    lblL "Left String (L):" tooltip:"Identifier for left bones (e.g., L_, Left), used to recognize left bones in non-mapping table modes"
    edittext edt_L "" text:"L_" fieldwidth:80 tooltip:"Enter identifier string for left bones (e.g., L_, Left). Must correspond to right identifier string (takes effect in non-mapping table modes)"
    label    lblR "Right String (R):" tooltip:"Identifier for right bones (e.g., R_, Right), used to recognize right bones in non-mapping table modes"
    edittext edt_R "" text:"R_" fieldwidth:80 tooltip:"Enter identifier string for right bones (e.g., R_, Right). Must correspond to left identifier string (takes effect in non-mapping table modes)"

    -- Mapping table setting controls
    label lblMap "Mapping Table (key=value per line): " tooltip:"Input area for custom bone mapping relationships. Only takes effect in 'Mapping Table Priority' mode. Format per line: 'source bone identifier=target bone identifier'"
    edittext edt_Map "" text:"" width:190 height:80 style:#multiLine tooltip:"Enter custom bone mapping rules:\n1.One rule per line, format 'key=value' (e.g., SpiderMan_01=BatMan_114514)\n2.Supports bidirectional matching (key maps to value, value also maps to key)\n3.Only takes effect in 'Mapping Table Priority' mode"
    button sep_rule_bot "" enabled:false height:3

    button sep_content_bot2 "" enabled:false height:3

    -- Mirror execution controls
    button btn_mirror "Mirror Current Frame (Multi-Chain)" height:35 tooltip:"Execute core bone mirroring: Mirror posture (position/rotation/scale) of selected bone chains to counterpart bones. Supports simultaneous processing of multiple bone chains. Only affects current time frame"
    label  lbl_info "Currently selected 0 bone chains" align:#left tooltip:"Real-time display of the number of selected bone root nodes (i.e., number of independent bone chains) in the current scene to help confirm operation range"
    checkbox chk_undo "Undoable" checked:true tooltip:"Control if operation is undoable: Check to record mirroring in Max undo history (undo with Ctrl+Z); uncheck to make operation non-undoable"

    -- Author info area controls
    button sep_author_top "" enabled:false height:3
    dotNetControl pic_author "System.Windows.Forms.PictureBox" width:180 height:45 align:#center tooltip:"Author identification image, used to display script author information"
    button sep_author_bot "" enabled:false height:3

    -- Link button controls
    button btn_nexus "Nexus Page" height:22 tooltip:"Click to open the author's Nexus Mods homepage, where you can view other resources released by the author"
    button btn_bili  "Bilibili Page" height:22 tooltip:"Click to open the author's Bilibili homepage, where you can view related tutorials, updates, or contact the author"
    button btn_update "Update (GitHub)" height:22 tooltip:"Click to open the script's GitHub repository, where you can get the latest version, update log, and source code"
    button sep_links "" enabled:false height:3
    button btn_surprise "Surprise button!" height:30 tooltip:"Click me for a surprise"

    -- Refresh preset dropdown (adapt to new mapping table structure)
    fn BM_UpdatePresetDropdown =
    (
        local mode = ddl_mode.items[ddl_mode.selection]
        local items = #("Custom")
        -- Critical: Traverse new mapPresets to ensure new presets are displayed
        case mode of
        (
            "Prefix": for p in prefixPresets do append items p[1]
            "Suffix": for p in suffixPresets do append items p[1]
            "Contain": for p in containPresets do append items p[1]
            "Mapping Table Priority": for p in mapPresets do append items p[1]  -- This will definitely be the new 2 presets
            default: ()
        )
        ddl_preset.items = items
        ddl_preset.selection = 1
    )

    -- Save preset (distinguish between mapping table and other modes)
    fn BM_AddPresetNamed mode name data =
    (
        if name == undefined or name == "" then return()
        case mode of
        (
            "Prefix": append prefixPresets #(name, data[1], data[2])
            "Suffix": append suffixPresets #(name, data[1], data[2])
            "Contain": append containPresets #(name, data[1], data[2])
            "Mapping Table Priority": append mapPresets #(name, data[1])  -- Store as #(name, full mapping text)
            default: ()
        )
        BM_UpdatePresetDropdown()
        BM_SavePresetsToFiles()
        ddl_preset.selection = ddl_preset.items.count
    )

    -- Delete preset (adapt to mapping table structure)
    fn BM_DeletePresetAt mode idx =
    (
        if idx < 1 then return false

        -- Calculate number of built-in presets (mapping table now has 2)
        local builtinCount = 0
        case mode of
        (
            "Prefix": builtinCount = prefixBuiltins.count
            "Suffix": builtinCount = suffixBuiltins.count
            "Contain": builtinCount = containBuiltins.count
            "Mapping Table Priority": builtinCount = mapBuiltins.count  -- Now 2 ("SuperHero" and "两个傻逼")
            default: builtinCount = 0
        )

        -- Built-in presets cannot be deleted
        if idx <= builtinCount then
        (
            BM_ShowBuiltinDenyDialog()
            return false
        )

        -- Execute deletion
        case mode of
        (
            "Prefix":
            (
                if idx <= prefixPresets.count then
                (
                    prefixPresets = for i = 1 to prefixPresets.count where i != idx collect prefixPresets[i]
                    true
                )
                else false
            )
            "Suffix":
            (
                if idx <= suffixPresets.count then
                (
                    suffixPresets = for i = 1 to suffixPresets.count where i != idx collect suffixPresets[i]
                    true
                )
                else false
            )
            "Contain":
            (
                if idx <= containPresets.count then
                (
                    containPresets = for i = 1 to containPresets.count where i != idx collect containPresets[i]
                    true
                )
                else false
            )
            "Mapping Table Priority":
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

    -- Layout adjustment
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
    )

    -- Update selected bone chain count
    fn BM_UpdateInfo =
    (
        local selRoots = BM_GetRootSelection (selection as array)
        lbl_info.text = "Currently selected " + (selRoots.count as string) + " bone chains"
    )

    -- Initialize when rollout opens (force refresh mapping table presets)
    on BoneMirrorRollout open do
    (
        BM_AdjustLayout()
        BM_UpdateInfo()

        -- After loading presets, force refresh mapping table presets (ensure they are new)
        BM_LoadPresetsFromFiles()
        BM_UpdatePresetDropdown()  -- This will re-read mapPresets and display new presets

        -- Listen for selection changes
        callbacks.removeScripts id:#BM_SelUpdate
        callbacks.addScript #selectionSetChanged "try(BoneMirrorRollout.BM_UpdateInfo())catch()" id:#BM_SelUpdate

        -- Load UI images
        local scriptPath = ""
        try( scriptPath = getSourceFileName() ) catch(scriptPath = "")
        if scriptPath != "" then
        (
            local baseDir = getFilenamePath scriptPath
            local uiDir = baseDir + "UI\\"

            local imgPath1 = uiDir + "001.png"
            if doesFileExist imgPath1 then
                try(pic_axis.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath1; pic_axis.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage; pic_axis.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68) catch()

            local imgPath2 = uiDir + "002.png"
            if doesFileExist imgPath2 then
                try(pic_mode.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath2; pic_mode.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage; pic_mode.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68) catch()

            local imgPath3 = uiDir + "003.png"
            if doesFileExist imgPath3 then
                try(pic_rule.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath3; pic_rule.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage; pic_rule.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68) catch()

            local imgPath4 = uiDir + "Ash.png"
            if doesFileExist imgPath4 then
                try(pic_author.Image = (dotNetClass "System.Drawing.Image").fromFile imgPath4; pic_author.SizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage; pic_author.backColor = (dotNetClass "System.Drawing.Color").FromArgb 68 68 68) catch()
        )
    )

    on BoneMirrorRollout close do callbacks.removeScripts id:#BM_SelUpdate
    on BoneMirrorRollout resized sz do BM_AdjustLayout()

    -- Refresh presets when switching matching modes (ensure mapping table displays new presets)
    on ddl_mode selected i do
    (
        BM_UpdatePresetDropdown()  -- Refresh dropdown immediately when switching to mapping table mode
    )

    -- Populate content when selecting preset (fix mapping table display)
    on ddl_preset selected i do
    (
        if i > 1 then
        (
            local mode = ddl_mode.items[ddl_mode.selection]
            local arr = undefined
            case mode of
            (
                "Prefix": arr = prefixPresets
                "Suffix": arr = suffixPresets
                "Contain": arr = containPresets
                "Mapping Table Priority": arr = mapPresets  -- These are the new 2 presets
                default: arr = undefined
            )
            if arr != undefined and i-1 <= arr.count then
            (
                local p = arr[i-1]
                if p != undefined then
                (
                    if mode == "Mapping Table Priority" then
                    (
                        -- Mapping table: Populate full text to edt_Map (content of new presets)
                        edt_Map.text = p[2]
                    )
                    else
                    (
                        -- Other modes: Populate L/R to corresponding input boxes
                        edt_L.text = p[2]
                        edt_R.text = p[3]
                    )
                )
            )
        )
    )

    -- Save Preset button (fix mapping table save logic)
    on btn_savePreset pressed do
    (
        local mode = ddl_mode.items[ddl_mode.selection]
        if mode == "Mapping Table Priority" then
        (
            local mapText = edt_Map.text
            -- Verify mapping table format (must contain at least one "=")
            if (findString mapText "=") == undefined then
            (
                messageBox "Invalid Mapping Table Format! Please enter key=value format (e.g., ArmL=ArmR)"
                return()
            )
            -- Generate default name (take content before first "=")
            local defaultName = (substring mapText 1 (findString mapText "=" - 1)) + "Mapping"
            local name = BM_PromptString "Please enter mapping table preset name:" defaultName
            if name != undefined then
            (
                BM_AddPresetNamed mode name #(mapText)
                messageBox "Mapping table preset saved and files updated!"
            )
        )
        else
        (
            local l = edt_L.text
            local r = edt_R.text
            if l == "" and r == "" then
            (
                messageBox "L and R strings can't both be empty!"
                return()
            )
            local defaultName = l + "/" + r
            local name = BM_PromptString "Please enter preset name:" defaultName
            if name != undefined then
            (
                BM_AddPresetNamed mode name #(l, r)
                messageBox "Preset saved and files updated!"
            )
        )
    )

    -- Delete Preset button (logic unchanged, call fixed dialog)
    on btn_delPreset pressed do
    (
        local sel = ddl_preset.selection
        if sel <= 1 then
        (
            messageBox "You haven't selected a preset to delete!"
            return()
        )

        local presetName = ddl_preset.items[sel]
        local confirmDelete = queryBox ("Are you sure you want to delete preset '" + presetName + "'?\nIt can't be recovered!") title:"Confirm Deletion"
        
        if confirmDelete then
        (
            local mode = ddl_mode.items[ddl_mode.selection]
            local idx = sel - 1  -- Preset array index (skip "Custom")
            local ok = BM_DeletePresetAt mode idx
            if ok then
            (
                BM_UpdatePresetDropdown()
                BM_SavePresetsToFiles()
                messageBox "Preset deleted and files updated!"
            )
        )
    )

    -- Mirror button behavior (unchanged)
    on btn_mirror pressed do
    (
        local selRoots = BM_GetRootSelection (selection as array)
        if selRoots.count == 0 then
        (
            messageBox "What are you trying to mirror without selecting any bones? Huh? Answer me!"
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

    -- Link buttons (unchanged)
    on btn_nexus pressed do shellLaunch "https://next.nexusmods.com/profile/ashtoash815/mods" ""
    on btn_bili pressed do shellLaunch "https://space.bilibili.com/3493272253106937?spm_id_from=333.337.0.0" ""
    on btn_update pressed do shellLaunch "https://github.com/AshToAsh815/3dsMax-Bones-mirror-tool-v1.1" ""
    on btn_surprise pressed do shellLaunch "https://www.bilibili.com/video/BV1GJ411x7h7/" ""
)

/* ---------- MacroScript Definition (MCR核心入口) ---------- */
macroScript BoneMirrorTool
category:"Bone Tools"
toolTip:"Ash-Mirror"
buttonText:"Ash-Mirror"
(
    on execute do
    (
        -- 强制初始化并显示Rollout
        try(destroyDialog BoneMirrorRollout) catch()
        createDialog BoneMirrorRollout 170 710 \
            style:#(#style_titlebar,#style_sysmenu,#style_resizing) \
            dockable:true
    )
)
