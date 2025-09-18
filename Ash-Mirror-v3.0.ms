global BoneMirrorRollout

/* ---------- Preset storage (Force replace preset mapping table, not affected by old files) ---------- */
global prefixBuiltins, suffixBuiltins, containBuiltins, mapBuiltins
global prefixPresets, suffixPresets, containPresets, mapPresets

-- 1. Built-in presets for mapping table (Force replace with 2 specified presets, delete old arm/leg mappings)
mapBuiltins = #(  -- Remove if judgment here, force overwrite old values regardless of previous definition
    #("SuperHero", "SpiderMan_01=BatMan_114514"),
    #("两个傻逼", "冥月千雪=你的中二魔王\n你的中二魔王=绝世大傻逼\nDante陽=绝世大傻逼\n你的中二魔王=Dante陽")
)
-- User presets for mapping table: Force initialization based on new built-in presets, overwrite content loaded from old files
mapPresets = #()
for p in mapBuiltins do append mapPresets p

-- 2. Built-in presets for other modes (Keep original structure unchanged, only ensure initialization)
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
-- Initialization for user presets of other modes (Only when undefined)
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

/* ---------- String utilities (Fix core name extraction, ensure no extra filtering) ---------- */
fn BM_StripPrefix nm =
(
    local p = findString nm ":"
    if p != undefined then
        #(substring nm 1 p, substring nm (p+1) (nm.count - p))  -- Only split "prefix:core name", keep original format of core name
    else
        #("", nm)
)

fn BM_CoreName nm =
(
    local pr = BM_StripPrefix nm
    pr[2]  -- Directly return original core name (e.g., "R_Thigh_pull_ST") without extra character filtering
)

fn BM_StartsWith s prefix =
(
    (prefix != "") and matchPattern s pattern:(prefix + "*")
)
fn BM_EndsWith s suffix =
(
    (suffix != "") and matchPattern s pattern:("*" + suffix)
)

/* ---------- Mapping table parsing (Keep original logic, compatible with complete mapping text) ---------- */
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

/* ---------- Find target bone (Core fix: Bidirectional matching for contain mode + Global search) ---------- */
-- New: Global search for target bone (No dependency on hierarchy, solve cross-parent node matching issue)
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
    -- Force type check: Ensure core is a valid string
    if classOf core != String or core == "" then return undefined

    -- Mapping table priority mode: Try mapping table first, then fallback to L/R rules
    if mode == "Map First" then
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

    -- Core fix: Bidirectional symmetric matching for contain mode (Check current side symbol first, then process opposite side)
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
            -- Fix 1: Check R and L independently, no dependency on else if (Prioritize R→L when selecting right side)
            local hasR = (Rstr != "" and (findString core Rstr) != undefined)
            local hasL = (Lstr != "" and (findString core Lstr) != undefined)

            if hasR then  -- Right bone: Replace R with L (Solve issue where right side can't match left core)
                t = substituteString core Rstr Lstr
            else if hasL then  -- Left bone: Replace L with R (Keep original logic)
                t = substituteString core Lstr Rstr

            -- Fix 2: Avoid invalid replacement (e.g., replacement result same as original core name)
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
    local candidates = #()  -- Fix 3: Use candidate list to store all possible target bones

    -- 1. Try to find under corresponding parent node (Keep original hierarchy matching)
    if srcParent != undefined do
    (
        local tgtParent = BM_FindCounterpartNode srcParent mode Lstr Rstr mapStr
        if tgtParent != undefined then
        (
            local inParent = BM_FindNodeByCoreInParent tgtParent tgtCore
            if inParent != undefined do append candidates inParent
        )
    )

    -- 2. Try to find under top-level hierarchy (Solve parent node mismatch issue)
    local top = BM_GetTopAncestor node
    if top != undefined then
    (
        local inHierarchy = BM_FindNodeByCoreInHierarchy top tgtCore
        if inHierarchy != undefined do append candidates inHierarchy
    )

    -- 3. Force global search (Final fallback, solve cross-hierarchy/cross-parent node matching issue)
    local globalNode = BM_GlobalFindNodeByCore tgtCore
    if globalNode != undefined do append candidates globalNode

    -- Return first valid target bone that is not itself
    for cand in candidates where cand != undefined and cand != node do
        return cand
        
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

-- New: Create local mirror matrix
fn BM_MakeLocalMirrorMatrix mode =
(
    case mode of
    (
        "X"   : matrix3 [-1,0,0] [0,1,0] [0,0,1] [0,0,0]
        "Y"   : matrix3 [1,0,0] [0,-1,0] [0,0,1] [0,0,0]
        "Z"   : matrix3 [1,0,0] [0,1,0] [0,0,-1] [0,0,0]
        "XY"  : matrix3 [-1,0,0] [0,-1,0] [0,0,1] [0,0,0]
        "XZ"  : matrix3 [-1,0,0] [0,1,0] [0,0,-1] [0,0,0]
        "YZ"  : matrix3 [1,0,0] [0,-1,0] [0,0,-1] [0,0,0]
        "XYZ" : matrix3 [-1,0,0] [0,-1,0] [0,0,-1] [0,0,0]
        default: matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]
    )
)

/* ---------- Mirror application ---------- */
fn BM_ApplyMirrorRecursive node M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing useLocalRotationMirror localMirrorAxes =
(
    local tgt = BM_FindCounterpartNode node mode Lstr Rstr mapStr
    if tgt != undefined and tgt != node then
    (
        local newTM
        
        -- Choose different calculation methods based on whether local rotation mirror is used
        if useLocalRotationMirror then
        (
            -- Local rotation mirror logic
            local localMirror = BM_MakeLocalMirrorMatrix localMirrorAxes
            local src_local = if node.parent != undefined then (inverse node.parent.transform) * node.transform else node.transform
            newTM = localMirror * src_local * localMirror
            newTM = if tgt.parent != undefined then tgt.parent.transform * newTM else newTM
        )
        else
        (
            -- Original global mirror logic
            newTM = M * node.transform * M
        )

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
            BM_ApplyMirrorRecursive c M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing useLocalRotationMirror localMirrorAxes
)

-- Modify function definition, add parameters related to local rotation
fn BM_MirrorOneFrame t roots M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing useLocalRotationMirror localMirrorAxes =
(
    at time t
    (
        for r in roots do
            BM_ApplyMirrorRecursive r M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing useLocalRotationMirror localMirrorAxes
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

    -- JSON serialization: Adapt to #(name, complete text) structure of mapping table
    fn ArrToJson arr mode =
    (
        local s = "["
        for i = 1 to arr.count do
        (
            local p = arr[i]
            local name = BM_EscapeString p[1]
            if mode == "map" then
            (
                -- Mapping table: Store name and complete mapText
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

    -- Write to JSON file
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
                -- Mapping table: #(name, complete mapText)
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

    -- Write to MaxScript file
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

    -- Prioritize loading .ms file (But force overwrite mapping table presets to new built-in ones after loading)
    if doesFileExist msPath then
    (
        try (fileIn msPath) catch()
    )
    else if doesFileExist legacyMs then
    (
        try (fileIn legacyMs) catch()
    )

    -- Key fix: Force mapping table presets to new built-in presets, overwrite content loaded from old files
    mapPresets = #()
    for p in mapBuiltins do append mapPresets p

    -- Ensure initialization of presets for other modes (No impact)
    if prefixPresets == undefined then prefixPresets = copy prefixBuiltins
    if suffixPresets == undefined then suffixPresets = copy suffixBuiltins
    if containPresets == undefined then containPresets = copy containBuiltins

    -- Ensure built-in presets for other modes are at the front (Deduplication)
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
                    -- Mapping table: Deduplicate by name and mapText (mapPresets already forced to new built-in ones here, this logic is only for compatibility)
                    if arrRef[j][1] == b[1] and arrRef[j][2] == b[2] then match = true
                )
                else
                (
                    -- Other modes: Deduplicate by L and R
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
    mapPresets = EnsureBuiltinsAtFront mapPresets mapBuiltins "map"  -- Reconfirm mapping table presets

    true
)

/* ---------- Preset name input dialog ---------- */
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

/* ---------- Fix dialog: Deny deletion of built-in presets (No WordWrap, manual line break) ---------- */
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
    win.Text = "Oops, Failed~"
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

    -- Right text (Manual \n line break, no WordWrap)
    local lbl = dotNetObject "System.Windows.Forms.Label"
    lbl.Bounds = dotNetObject "System.Drawing.Rectangle" 160 10 200 80
    lbl.Text = "Trying to delete my presets?\nNo way!"
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

/* ---------- UI Rollout (Fix mapping table preset display/save, adjust GitHub button position) ---------- */
rollout BoneMirrorRollout "Ash-Mirror-v3.0" width:230 height:780
(
    -- Mirror axis related controls
    dotNetControl pic_axis "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"Mirror axis function icon, used to visually distinguish mirror axis setting area"
    label lbl_axis "Mirror Axis:" align:#left offset:[25,-21] tooltip:"Identify function of the drop-down box below: Select coordinate axis for bone mirror operation"
    dropdownlist ddl_axis "" items:#("X","Y","Z") selection:1 tooltip:"Select base coordinate axis for mirror operation (X/Y/Z), choose based on bone orientation in scene to ensure correct posture after mirroring"
    checkbox     chk_children "Include Children" checked:true tooltip:"Control mirror range: Check to process all child bones of selected bones; uncheck to process only selected top-level bones"
    checkbox     chk_ignoreMissing "Continue on Missing" checked:true tooltip:"Handle abnormal scenarios: Check to skip and continue processing other bones if counterpart of a bone is not found; uncheck to stop operation directly"

    -- Local rotation mirror related controls
    checkbox chk_useLocalRotation "Use Local Mirror" checked:false width:200 tooltip:"Enable to use local coordinate system for rotation mirroring, suitable for complex bone structures"
    dropdownlist ddlLocalAxes "Local Axis Flip: " items:#("X", "Y", "Z", "XY", "XZ", "YZ", "XYZ") default:6 width:200 enabled:false tooltip:"Select combination of flip axes in local coordinate system, different combinations are suitable for different bone structures"

    -- Matching mode separator and controls
    button sep_mode_top "" enabled:false height:3
    dotNetControl pic_mode "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"Matching mode function icon, used to visually distinguish bone matching mode setting area"
    label lbl_mode "Match Mode" align:#left offset:[25,-21] tooltip:"Identify function of the drop-down box below: Select matching logic for left-right counterparts of bones"
    dropdownlist ddl_mode "" items:#("Prefix","Suffix","Contain","Map First") selection:3 tooltip:"Select bone counterpart matching mode:\n1.Prefix: Identify left-right by bone name prefix (e.g., LeftArm/RightArm)\n2.Suffix: Identify left-right by bone name suffix (e.g., Arm_L/Arm_R)\n3.Contain: Identify left-right by characters in name (e.g., ArmLeft/ArmRight)\n4.Map First: Prioritize matching by custom mapping table, fallback to above rules if no match"
    button sep_mode_bot "" enabled:false height:3

    -- Naming rule separator and controls
    button sep_rule_top "" enabled:false height:3
    dotNetControl pic_rule "System.Windows.Forms.PictureBox" width:21 height:21 tooltip:"Naming rule function icon, used to visually distinguish bone naming rule setting area"
    label lbl_grp1 "Naming Rules (Counterpart Match)" align:#left offset:[25,-21] tooltip:"Identify function of this area: Set specific parameters for identifying left-right counterparts of bones in current matching mode"
    dropdownlist ddl_preset "Presets: " items:#("Custom") selection:1 tooltip:"Load saved naming rule presets: Select 'Custom' to enter parameters manually; select other presets to quickly apply common configurations"
    button btn_savePreset "Save as Preset" height:22 tooltip:"Save current naming rules (L/R strings or mapping table content) as new preset for future reuse"
    button btn_delPreset "Delete Preset" height:22 tooltip:"Delete currently selected preset (Built-in presets cannot be deleted), cannot be recovered after deletion, please confirm before operation"

    -- L/R string setting controls
    label    lblL "Left String (L):" tooltip:"Identify mark for left bones (e.g., L_, Left), used to identify left bones in non-mapping table modes"
    edittext edt_L "" text:"L_" fieldwidth:80 tooltip:"Enter identification string for left bones (e.g., L_, Left), must correspond to right identification string (effective in non-mapping table modes)"
    label    lblR "Right String (R):" tooltip:"Identify mark for right bones (e.g., R_, Right), used to identify right bones in non-mapping table modes"
    edittext edt_R "" text:"R_" fieldwidth:80 tooltip:"Enter identification string for right bones (e.g., R_, Right), must correspond to left identification string (effective in non-mapping table modes)"

    -- Mapping table setting controls
    label lblMap "Mapping Table (key=value per line): " tooltip:"Input area for custom bone mapping relationships, only effective in 'Map First' mode, format per line: 'source bone mark=target bone mark'"
    edittext edt_Map "" text:"" width:190 height:80 style:#multiLine tooltip:"Enter custom bone mapping rules:\n1.One rule per line, format: 'key=value' (e.g., SpiderMan_01=BatMan_114514)\n2.Supports bidirectional matching (key can map to value, value can also map to key)\n3.Only effective in 'Map First' mode"
    button sep_rule_bot "" enabled:false height:3

    button sep_content_bot2 "" enabled:false height:3

    -- Mirror execution controls
    button btn_mirror "Mirror Current Frame (Multi-Chain)" height:35 tooltip:"Execute core bone mirror operation: Mirror posture (position/rotation/scale) of selected bone chains to counterpart bones, support simultaneous processing of multiple bone chains, only effective for current time frame"
    label  lbl_info "0 Bone Chains Selected" align:#left tooltip:"Real-time display of number of selected bone root nodes in current scene (i.e., number of independent bone chains), helping confirm operation range"
    checkbox chk_undo "Undoable" checked:true tooltip:"Control whether operation is undoable: Check to record mirror operation in Max undo history, can undo via Ctrl+Z; uncheck to make operation non-undoable"
    
    -- 【Key Adjustment】Move GitHub update button below "Undoable" checkbox
    button btn_update "Update (GitHub)" height:22 tooltip:"Click to open script's GitHub repository address, accessible to latest version, update log and source code"

    -- Remove Ash image related controls: Delete original pic_author image control and upper/lower separators
    -- Link button controls (Remove GitHub button from original position)
    button btn_nexus "Nexus Page" height:22 tooltip:"Click to open author's Nexus Mods homepage, view other resources released by author"
    button btn_bili  "Bilibili Page" height:22 tooltip:"Click to open author's Bilibili homepage, view related tutorials, updates or contact author"
    button sep_links "" enabled:false height:3
    button btn_surprise "Surprise Button Found!" height:30 tooltip:"Bro! Click for surprise!"

    -- Trigger when local rotation checkbox state changes
    on chk_useLocalRotation changed state do
    (
        -- Enable flip axis drop-down box only when checked
        ddlLocalAxes.enabled = state
    )

    -- Refresh preset drop-down box (Compatible with new mapping table structure)
    fn BM_UpdatePresetDropdown =
    (
        local mode = ddl_mode.items[ddl_mode.selection]
        local items = #("Custom")
        -- Key: Traverse new mapPresets to ensure new presets are displayed
        case mode of
        (
            "Prefix": for p in prefixPresets do append items p[1]
            "Suffix": for p in suffixPresets do append items p[1]
            "Contain": for p in containPresets do append items p[1]
            "Map First": for p in mapPresets do append items p[1]  -- Must be 2 new presets here
            default: ()
        )
        ddl_preset.items = items
        ddl_preset.selection = 1
    )

    -- Save preset (Distinguish between mapping table and other modes)
    fn BM_AddPresetNamed mode name data =
    (
        if name == undefined or name == "" then return()
        case mode of
        (
            "Prefix": append prefixPresets #(name, data[1], data[2])
            "Suffix": append suffixPresets #(name, data[1], data[2])
            "Contain": append containPresets #(name, data[1], data[2])
            "Map First": append mapPresets #(name, data[1])  -- Store as #(name, complete mapping text)
            default: ()
        )
        BM_UpdatePresetDropdown()
        BM_SavePresetsToFiles()
        ddl_preset.selection = ddl_preset.items.count
    )

    -- Delete preset (Compatible with mapping table structure)
    fn BM_DeletePresetAt mode idx =
    (
        if idx < 1 then return false

        -- Calculate number of built-in presets (2 for mapping table now)
        local builtinCount = 0
        case mode of
        (
            "Prefix": builtinCount = prefixBuiltins.count
            "Suffix": builtinCount = suffixBuiltins.count
            "Contain": builtinCount = containBuiltins.count
            "Map First": builtinCount = mapBuiltins.count  -- 2 now (SuperHero and 两个傻逼)
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
            "Map First":
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

    -- Layout adjustment (Synchronize to include GitHub button in new position, remove Ash image related layout code)
    fn BM_AdjustLayout =
    (
        local margin = 10
        local usableW = BoneMirrorRollout.width - margin*2
        for c in #(ddl_axis, chk_children, chk_ignoreMissing, chk_useLocalRotation, ddlLocalAxes,
                   sep_mode_top, ddl_mode, sep_mode_bot,
                   sep_rule_top, ddl_preset, btn_savePreset, btn_delPreset, edt_L, edt_R, lblL, lblR, lblMap, edt_Map, sep_rule_bot,
                   sep_content_bot2,
                   btn_mirror, lbl_info, chk_undo, btn_update,  -- Add btn_update to layout list
                   btn_nexus, btn_bili, sep_links,  -- Remove btn_update from original position and Ash image related controls
                   btn_surprise) do
        (
            try(c.pos.x = margin) catch()
            try(c.width = usableW) catch()
        )
    )

    -- Update number of selected bone chains
    fn BM_UpdateInfo =
    (
        local selRoots = BM_GetRootSelection (selection as array)
        lbl_info.text = selRoots.count as string + " Bone Chains Selected"
    )

    -- Initialization when rollout opens (Force refresh mapping table presets, remove Ash image loading code)
    on BoneMirrorRollout open do
    (
        BM_AdjustLayout()
        BM_UpdateInfo()

        -- Force refresh mapping table presets after loading presets (Ensure they are new)
        BM_LoadPresetsFromFiles()
        BM_UpdatePresetDropdown()  -- Re-read mapPresets here to display new presets

        -- Monitor selection changes
        callbacks.removeScripts id:#BM_SelUpdate
        callbacks.addScript #selectionSetChanged "try(BoneMirrorRollout.BM_UpdateInfo())catch()" id:#BM_SelUpdate

        -- Load UI images (Remove Ash.png loading code)
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
        )
    )

    on BoneMirrorRollout close do callbacks.removeScripts id:#BM_SelUpdate
    on BoneMirrorRollout resized sz do BM_AdjustLayout()

    -- Refresh presets when matching mode is switched (Ensure mapping table displays new presets)
    on ddl_mode selected i do
    (
        BM_UpdatePresetDropdown()  -- Refresh drop-down box immediately when switching to mapping table mode
    )

    -- Fill content when preset is selected (Fix mapping table display)
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
                "Map First": arr = mapPresets  -- 2 new presets here
                default: arr = undefined
            )
            if arr != undefined and i-1 <= arr.count then
            (
                local p = arr[i-1]
                if p != undefined then
                (
                    if mode == "Map First" then
                    (
                        -- Mapping table: Fill complete text into edt_Map (Content of new preset)
                        edt_Map.text = p[2]
                    )
                    else
                    (
                        -- Other modes: Fill L/R into corresponding input boxes
                        edt_L.text = p[2]
                        edt_R.text = p[3]
                    )
                )
            )
        )
    )

    -- Save Preset button (Fix mapping table save logic)
    on btn_savePreset pressed do
    (
        local mode = ddl_mode.items[ddl_mode.selection]
        if mode == "Map First" then
        (
            local mapText = edt_Map.text
            -- Verify mapping table format (At least one "=" required)
            if (findString mapText "=") == undefined then
            (
                messageBox "Invalid mapping table format! Please enter key=value format (e.g., ArmL=ArmR)"
                return()
            )
            -- Generate default name (Take content before first "=")
            local defaultName = (substring mapText 1 (findString mapText "=" - 1)) + "Map"
            local name = BM_PromptString "Enter mapping table preset name: " defaultName
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
                messageBox "L and R strings cannot both be empty!"
                return()
            )
            local defaultName = l + "/" + r
            local name = BM_PromptString "Enter preset name: " defaultName
            if name != undefined then
            (
                BM_AddPresetNamed mode name #(l, r)
                messageBox "Preset saved and files updated!"
            )
        )
    )

    -- Delete Preset button (Logic unchanged, call fixed dialog)
    on btn_delPreset pressed do
    (
        local sel = ddl_preset.selection
        if sel <= 1 then
        (
            messageBox "No preset selected to delete!"
            return()
        )

        local presetName = ddl_preset.items[sel]
        local confirmDelete = queryBox ("Confirm to delete preset '" + presetName + "'?\nCannot be recovered after deletion!") title:"Confirm Deletion"
        
        if confirmDelete then
        (
            local mode = ddl_mode.items[ddl_mode.selection]
            local idx = sel - 1  -- Preset array index (Skip "Custom")
            local ok = BM_DeletePresetAt mode idx
            if ok then
            (
                BM_UpdatePresetDropdown()
                BM_SavePresetsToFiles()
                messageBox "Preset deleted and files updated!"
            )
        )
    )

    -- Mirror button behavior (Add parameter passing for local rotation)
    on btn_mirror pressed do
    (
        local selRoots = BM_GetRootSelection (selection as array)
        if selRoots.count == 0 then
        (
            messageBox "Please select bones to mirror first!"
            return()
        )

        local axisStr       = ddl_axis.items[ddl_axis.selection]
        local mode          = ddl_mode.items[ddl_mode.selection]
        local Lstr          = edt_L.text
        local Rstr          = edt_R.text
        local mapStr        = edt_Map.text
        local ignoreMissing = chk_ignoreMissing.checked
        
        -- Get parameters related to local rotation mirror
        local useLocalRotationMirror = chk_useLocalRotation.checked
        local localMirrorAxes = ddlLocalAxes.selected as string

        local M      = BM_MakeMirrorMatrix axisStr
        local doPos  = true
        local doRot  = true
        local doScl  = true
        local doChildren = chk_children.checked

        -- Execute mirror operation, ensure parameters are complete
        if chk_undo.checked then
        (
            undo "Bone Mirror" on
            (
                with animate on
                (
                    BM_MirrorOneFrame currentTime selRoots M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing useLocalRotationMirror localMirrorAxes
                )
            )
        )
        else
        (
            with animate on
            (
                BM_MirrorOneFrame currentTime selRoots M mode Lstr Rstr mapStr doPos doRot doScl doChildren ignoreMissing useLocalRotationMirror localMirrorAxes
            )
        )
    )

    -- Link buttons (Only adjust btn_update position, function unchanged)
    on btn_nexus pressed do shellLaunch "https://next.nexusmods.com/profile/ashtoash815/mods" ""
    on btn_bili pressed do shellLaunch "https://space.bilibili.com/3493272253106937?spm_id_from=333.337.0.0" ""
    on btn_update pressed do shellLaunch "https://github.com/AshToAsh815/3dsMax-Bones-mirror-tool-v1.1" ""  -- Button function logic unchanged
    on btn_surprise pressed do shellLaunch "https://www.bilibili.com/video/BV1GJ411x7h7/" ""
)

/* ---------- Display and Macro Definition ---------- */
fn BM_Show =
(
    try(destroyDialog BoneMirrorRollout) catch()
    createDialog BoneMirrorRollout 170 705 \
        style:#(#style_titlebar,#style_sysmenu,#style_resizing) \
        dockable:true
)

macroScript BoneMirrorTool
category:"Bone Tools"
toolTip:"Ash-Mirror"
buttonText:"Ash-Mirror"
(
    on execute do BM_Show()
)

-- Force initialization, then display rollout immediately
BM_Show()