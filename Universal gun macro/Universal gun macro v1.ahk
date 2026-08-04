; ==========================
; GLOBALS
; ==========================

global equipSequence := ""
global hotkeyList := []
global functionList := ["Spawn Vehicle", "Equip Guns", "Rebind", "Combat Log"]
global functionMap := Map(
    "Spawn Vehicle", SpawnVehicle,
    "Equip Guns", EquipMacro,
    "Combat Log", CombatLog,
    "Solve Power", SolvePower
)
global weapons := LoadList("Weapons")
global gunStoreGuns := LoadList("GunStoreGuns")
global gunStoreExplosives := LoadList("GunStoreExplosives")
global garage := LoadList("Garage")
global Loadouts := []
global hotkeyView
global loadoutCreatorGui
global creatorWeaponList
global creatorLoadoutList
global creatorNameBox
global creatorLoadout := []
global currentOptionBox
global manageLoadoutGui
global manageLoadoutList
global manageNameBox
global editingLoadout := ""
global createHotkeyAfterSave := false
global activeHotkeys := []
global rebinds := []
global activeRebinds := []
global rebindCreatorGui
global rebindToBox
global currentOptionList := []
global firstGarageSpawnSequences := Map()


; ==========================
; STARTUP
; ==========================

LoadSettings()
BuildGui()
ApplyHotkeys()
RefreshHotkeys()

; ==========================
; HELPER
; ==========================

LoadList(section) {
    list := []
    file := "dynamic.ini"
    Loop 500 {
        value := IniRead(file, section, A_Index, "")
        if value != ""
            list.Push(value)
    }
    return list
}

SendSequence(sequence, *) {
    Send(sequence)
}

UpdateHotkeySequences(loadoutName) {
    global hotkeyList

    LoadLoadout(loadoutName)
    sequence := BuildSeq(LOADOUT)

    for hotkey in hotkeyList {
        if hotkey.Function = "Equip Guns" && hotkey.Option = loadoutName
            hotkey.Sequence := sequence
    }

    SaveSettings()
}

RebuildVehicleSequences() {
    global hotkeyList

    for hotkey in hotkeyList {
        if hotkey.Function = "Spawn Vehicle"
            hotkey.Sequence := BuildGarageSequence(hotkey.Option)
    }

    SaveSettings()
}

HotkeyAction(item, *) {
    global firstGarageSpawnSequences

    if item.Function = "Spawn Vehicle" {

        if !firstGarageSpawnSequences.Has(item.Option) {
            firstGarageSpawnSequences[item.Option] := BuildGarageFirstSequence(item.Option)
            Send(firstGarageSpawnSequences[item.Option])
            return
        }
    }

    Send(item.Sequence)
}

AddRebind(from, to) {

    IniWrite(
        from "|" to,
        "settings.ini",
        "Rebinds",
        IniRead("settings.ini", "Rebinds", "Count", 0) + 1
    )

    LoadRebinds()
}

; ==========================
; GUI
; ==========================

BuildGui() {
    global
    mainGui := Gui(, "Universal JailBreak Macro")
    mainGui.AddText("x20 y10","Hotkeys")
    hotkeyView := mainGui.AddListView("x20 y30 w550 h180", ["Key", "Function", "Option"])
    hotkeyView.ModifyCol(1,80)
    hotkeyView.ModifyCol(2,150)
    hotkeyView.ModifyCol(3,250)
    mainGui.AddButton("x20 y230 w100","Add Hotkey").OnEvent("Click",AddHotkeyGUI)
    mainGui.AddButton("x130 y230 w100","Remove").OnEvent("Click",RemoveHotkey)
    mainGui.AddButton("x250 y230 w120", "Manage Loadouts").OnEvent("Click", OpenManageLoadouts)
    mainGui.Show()
}

OpenRebindCreator() {
    global

    rebindCreatorGui := Gui(, "Create Rebind")

    rebindCreatorGui.AddText("x20 y10", "Rebind to key")

    rebindToBox := rebindCreatorGui.AddHotkey(
        "x20 y30 w150"
    )

    rebindCreatorGui.AddButton(
        "x20 y70 w100",
        "Save"
    ).OnEvent(
        "Click",
        SaveRebind
    )

    rebindCreatorGui.Show()
}

RefreshLoadoutOptions() {
    global currentOptionBox, Loadouts
    if !IsSet(currentOptionBox)
        return

    try {
        currentOptionBox.Delete()
        for loadoutName in Loadouts {
            currentOptionBox.Add([loadoutName])
        }
        currentOptionBox.Add(["+ Create New Loadout"])
    } catch {
        currentOptionBox := unset
    }
}

OpenManageLoadouts(*) {
    global
    manageLoadoutGui := Gui(, "Manage Loadouts")
    manageLoadoutList := manageLoadoutGui.AddListBox("x20 y20 w200 h250")
    manageNameBox := manageLoadoutGui.AddEdit("x240 y20 w180")
    manageLoadoutGui.AddButton("x240 y60 w180", "Create New").OnEvent("Click", CreateLoadout)
    manageLoadoutGui.AddButton("x240 y100 w180", "Edit").OnEvent("Click", EditLoadout)
    manageLoadoutGui.AddButton("x240 y140 w180", "Rename").OnEvent("Click", RenameLoadout)
    manageLoadoutGui.AddButton("x240 y180 w180", "Delete").OnEvent("Click", DeleteLoadout)
    manageLoadoutList.OnEvent("Change", SelectManagedLoadout)
    RefreshManageLoadouts()
    manageLoadoutGui.Show()
}

RefreshManageLoadouts() {
    global
    manageLoadoutList.Delete()
    for loadout in Loadouts {
        manageLoadoutList.Add([loadout])
    }
}

SelectManagedLoadout(*) {
    global
    name := manageLoadoutList.Text
    if name != ""
        manageNameBox.Value := name
}

RenameLoadout(*) {
    global
    oldName := manageLoadoutList.Text
    newName := manageNameBox.Value
    if oldName = "" || newName = ""
        return

    if oldName = newName
        return

    for name in Loadouts {
        if name = newName {
            MsgBox("A loadout with that name already exists.")
            return
        }
    }
    oldSection := "Loadout_" oldName
    newSection := "Loadout_" newName
    Loop 100 {
        item := IniRead("settings.ini", oldSection, A_Index, "")
        if item = ""
            break

        IniWrite(item, "settings.ini", newSection, A_Index)
    }
    IniDelete("settings.ini", oldSection)
    for index, name in Loadouts {
        if name = oldName {
            Loadouts[index] := newName
            IniWrite(newName, "settings.ini", "Loadouts", index)
            break
        }
    }
    RefreshManageLoadouts()
    RefreshLoadoutOptions()
}

DeleteLoadout(*) {
    global
    name := manageLoadoutList.Text
    if name = ""
        return

    result := MsgBox("Delete '" name "'?", "Confirm delete", "YesNo")
    if result != "Yes"
        return

    IniDelete( "settings.ini", "Loadout_" name)
    for index, loadoutName in Loadouts {
        if loadoutName = name {
            Loadouts.RemoveAt(index)
            break
        }
    }
    IniDelete("settings.ini", "Loadouts")
    for index, loadoutName in Loadouts {
        IniWrite(loadoutName, "settings.ini", "Loadouts", index)
    }
    RefreshManageLoadouts()
    RefreshLoadoutOptions()
}

EditLoadout(*) {
    global
    name := manageLoadoutList.Text
    if name = ""
        return

    editingLoadout := name
    creatorLoadout := []
    Loop 100 {
        weapon := IniRead("settings.ini", "Loadout_" name, A_Index, "")
        if weapon = ""
            break

        creatorLoadout.Push(weapon)
    }
    OpenLoadoutCreator()
    manageLoadoutGui.Destroy()
}

; ==========================
; SAVE / LOAD
; ==========================

LoadSettings() {
    global
    Loadouts := []
    Loop 100 {
        name := IniRead("settings.ini", "Loadouts", A_Index, "")
        if name = ""
            break

        Loadouts.Push(name)
    }
    LoadHotkeys()
    LoadRebinds()
    LOADOUT := []
    if Loadouts.Length > 0
        LoadLoadout(Loadouts[1])
}

SaveRebind(*) {

    global rebindToBox

    to := rebindToBox.Value

    if to = "" {
        MsgBox("Choose a key.")
        return
    }

    count := IniRead(
        "settings.ini",
        "Rebinds",
        "Count",
        0
    )

    count++

    IniWrite(
        to,
        "settings.ini",
        "Rebinds",
        count
    )

    IniWrite(
        count,
        "settings.ini",
        "Rebinds",
        "Count"
    )

    LoadRebinds()

    RefreshLoadoutOptions()

    rebindCreatorGui.Destroy()

    MsgBox("Rebind option created.")
}

RefreshRebindOptions() {
    global currentOptionBox, rebinds, currentOptionList

    if !IsSet(currentOptionBox)
        return

    try {

        currentOptionList := []

        for key in rebinds
            currentOptionList.Push(key)

        currentOptionList.Push("+ Create New Rebind")

        currentOptionBox.Delete()
        currentOptionBox.Add(currentOptionList)

    }
    catch {
        currentOptionBox := unset
    }
}

LoadRebinds() {

    global rebinds

    rebinds := []

    Loop 100 {

        value := IniRead(
            "settings.ini",
            "Rebinds",
            A_Index,
            ""
        )

        if value = ""
            continue

        rebinds.Push(value)
    }
}

LoadHotkeys() {
    global hotkeyList
    hotkeyList := []
    Loop {
        value := IniRead("settings.ini", "Hotkeys", A_Index, "")
        if value = ""
            break

        parts := StrSplit(value, "|")
        if parts.Length < 2
            continue

        sequence := parts.Length >= 4 ? parts[4] : ""

        if sequence = "" {

            if parts[2] = "Equip Guns" {
                LoadLoadout(parts[3])
                sequence := BuildSeq(LOADOUT)
            }

            else if parts[2] = "Spawn Vehicle" {
                sequence := BuildGarageSequence(parts[3])
            }
        }

        hotkeyList.Push({
            Key: parts[1],
            Function: parts[2],
            Option: parts.Length >= 3 ? parts[3] : "",
            Sequence: sequence
        })
    }
}

SaveSettings(*) {
    global
    ; Save loadout
    IniDelete("settings.ini", "Loadout")
    for i, item in LOADOUT {
        IniWrite(item, "settings.ini", "Loadout", i)
    }
    ;Save hotkeys
    IniDelete("settings.ini", "Hotkeys")
    for i, hkey in hotkeyList {
        IniWrite(hkey.Key "|" hkey.Function "|" hkey.Option "|" hkey.Sequence, "settings.ini", "Hotkeys", i)
    }
    ApplyHotkeys()
    MsgBox("Saved!")
}

SaveHotkeys() {
    global hotkeyList

    IniDelete("settings.ini", "Hotkeys")

    for index, hkey in hotkeyList {
        IniWrite(
            hkey.Key "|" hkey.Function "|" hkey.Option "|" hkey.Sequence,
            "settings.ini",
            "Hotkeys",
            index
        )
    }
}

ReloadConfig(*) {
    LoadSettings()
    ApplyHotkeys()
}

; ==========================
; Options
; ==========================

UpdateOptionControl(optionBox, funcBox, defaultFunction := "", defaultOption := "", *) {
    global Loadouts, garage, rebinds, currentOptionList

    currentOptionList := []
    optionBox.Delete()

    if funcBox.Text = "Spawn Vehicle" {

        for vehicle in garage
            currentOptionList.Push(vehicle)

    }
    else if funcBox.Text = "Equip Guns" {

        for loadoutName in Loadouts
            currentOptionList.Push(loadoutName)

        currentOptionList.Push("+ Create New Loadout")

    }
    else if funcBox.Text = "Rebind" {

        for key in rebinds
            currentOptionList.Push(key)

        currentOptionList.Push("+ Create New Rebind")

    }

    if currentOptionList.Length > 0
        optionBox.Add(currentOptionList)

    optionBox.Enabled := true

    if defaultOption != "" {
        for index, value in currentOptionList {
            if value = defaultOption {
                optionBox.Choose(index)
                break
            }
        }
    }
}

; ==========================
; LOADOUT
; ==========================

LoadLoadout(name) {
    global LOADOUT
    LOADOUT := []
    Loop 100 {
        weapon := IniRead("settings.ini", "Loadout_" name, A_Index, "")
        if weapon = ""
            break

        LOADOUT.Push(weapon)
    }
}

SaveLoadout(name, weapons) {
    global Loadouts
    section := "Loadout_" name
    ; check overwrite
    exists := false
    for oldName in Loadouts {
        if oldName = name {
            exists := true
            break
        }
    }
    if exists {
        result := MsgBox(
            "A loadout named '" name "' already exists.`nOverwrite it?",
            "Confirm overwrite",
            "YesNo"
        )
        if result != "Yes"
            return false
    }
    else{
        Loadouts.Push(name)
        IniWrite( name, "settings.ini", "Loadouts", Loadouts.Length)
    }
    ; replace old loadout
    IniDelete("settings.ini", section)

    for index, weapon in weapons {
        IniWrite( weapon, "settings.ini", section, index)
    }
    return true
}

CheckCreateLoadout(optionBox, *) {

    if optionBox.Text = "+ Create New Loadout" {

        createHotkeyAfterSave := false
        OpenLoadoutCreator()
        optionBox.Text := ""

    }

    else if optionBox.Text = "+ Create New Rebind" {

        OpenRebindCreator()
        optionBox.Text := ""

    }
}

OpenLoadoutCreator() {
    global

    if !IsSet(creatorLoadout)
        creatorLoadout := []

    loadoutCreatorGui := Gui(, "Create Loadout")
    loadoutCreatorGui.AddText("x20 y10", "Available Weapons")
    creatorWeaponList := loadoutCreatorGui.AddListBox("x20 y30 w160 h260")
    loadoutCreatorGui.AddText("x260 y10", "Loadout")
    creatorLoadoutList := loadoutCreatorGui.AddListView("x260 y30 w200 h260", ["Weapon"])
    creatorNameBox := loadoutCreatorGui.AddEdit("x20 y310 w200", editingLoadout)
    loadoutCreatorGui.AddButton("x20 y335 w80", "Save").OnEvent("Click", SaveNewLoadout)
    loadoutCreatorGui.AddButton("x190 y100 w50", ">>").OnEvent("Click", CreatorAddWeapon)
    loadoutCreatorGui.AddButton("x190 y150 w50", "<<").OnEvent("Click", CreatorRemoveWeapon)
    loadoutCreatorGui.AddButton("x260 y310 w80", "Move Up").OnEvent("Click", CreatorMoveUp)
    loadoutCreatorGui.AddButton("x350 y310 w80", "Move Down").OnEvent("Click", CreatorMoveDown)
    RefreshCreatorLists()
    loadoutCreatorGui.Show()
}

RefreshCreatorLists() {
    global
    creatorWeaponList.Delete()
    for weapon in weapons {
        exists := false
        for item in creatorLoadout {
            if item = weapon {
                exists := true
                break
            }
        }
        if !exists {
            creatorWeaponList.Add([weapon])
        }
    }
    creatorLoadoutList.Delete()
    for weapon in creatorLoadout {
        creatorLoadoutList.Add("", weapon)
    }
}

CreatorAddWeapon(*) {
    global
    weapon := creatorWeaponList.Text
    if weapon = ""
        return

    creatorLoadout.Push(weapon)
    RefreshCreatorLists()
}

CreatorRemoveWeapon(*) {
    global
    row := creatorLoadoutList.GetNext()
    if row {
        creatorLoadout.RemoveAt(row)
        RefreshCreatorLists()
    }
}

CreatorMoveUp(*) {
    global
    row := creatorLoadoutList.GetNext()
    if !row || row <= 1
        return

    item := creatorLoadout.RemoveAt(row)
    creatorLoadout.InsertAt(row - 1, item)
    RefreshCreatorLists()
}

CreatorMoveDown(*) {
    global
    row := creatorLoadoutList.GetNext()
    if !row || row >= creatorLoadout.Length
        return

    item := creatorLoadout.RemoveAt(row)
    creatorLoadout.InsertAt(row + 1, item)
    RefreshCreatorLists()
}

SaveNewLoadout(*) {
    global
    name := creatorNameBox.Value
    if name = "" {
        MsgBox("Enter a loadout name.")
        return
    }
    if creatorLoadout.Length = 0 {
        MsgBox("Loadout is empty.")
        return
    }

    if SaveLoadout(name, creatorLoadout) {
        LoadSettings()
        RefreshLoadoutOptions()
        loadoutCreatorGui.Destroy()
        if createHotkeyAfterSave {

            result := MsgBox("Create Hotkey for this Loadout?", "Loadout Saved", "YesNo")
            if result = "Yes" {
                AddHotkeyGUI("Equip Guns", name)
            }
        }
        else {
            MsgBox("Loadout saved!")
        }
    }
}

CreateLoadout(*) {
    global
    editingLoadout := ""
    creatorLoadout := []
    createHotkeyAfterSave := true
    OpenLoadoutCreator()
}

; ==========================
; HOTKEYS
; ==========================

AddHotkeyGUI(defaultFunction := "", defaultOption := "", *) {
    global
    g := Gui(, "Add Hotkey")
    g.AddText(, "Key")
    keyBox := g.AddHotkey("w150")
    g.AddText(, "Function")
    funcBox := g.AddDropDownList("w200", functionList)
    g.AddText(, "Option")
    optionBox := g.AddDropDownList("w250", [])
    currentOptionBox := optionBox
    funcBox.OnEvent("Change", UpdateOptionControl.Bind(optionBox, funcBox))
    optionBox.OnEvent("Change", CheckCreateLoadout.Bind(optionBox))
    if defaultFunction != "" {

        for index, value in functionList {
            if value = defaultFunction {
                funcBox.Choose(index)
                break
            }
        }
        UpdateOptionControl(optionBox, funcBox, defaultFunction, defaultOption)
    }
    g.AddButton(, "Add").OnEvent("Click", SaveHotkey.Bind(g, keyBox, funcBox, optionBox))
    g.Show()
}

SaveHotkey(parent, keyBox, funcBox, optionBox, *) {
    global
    newKey := keyBox.Value
    if newKey = "" {
        MsgBox("Please select a hotkey.")
        return
    }
    for hkey in hotkeyList {
        if hkey.Key = newKey {
            MsgBox("This hotkey (" hkey.Key ") is already assigned.`nChoose another key.", "Duplicate Hotkey")
            return
        }
    }
    sequence := ""
    if funcBox.Text = "Equip Guns" {
        LoadLoadout(optionBox.Text)
        sequence := BuildSeq(LOADOUT)
    }
    else if funcBox.Text = "Spawn Vehicle" {
        sequence := BuildGarageSequence(optionBox.Text)
    }
    else if funcBox.Text = "Combat Log" {
        sequence := IniRead("dynamic.ini", "Paths", "logPath", "")
    }
    else if funcBox.Text = "Rebind" {
        sequence := optionBox.Text
    }
    hotkeyList.Push({Key: newKey, Function: funcBox.Text, Option: optionBox.Text, Sequence: sequence})
    SaveHotkeys()
    RefreshHotkeys()
    ApplyHotkeys()

    parent.Destroy()
}

RefreshHotkeys() {
    global
    hotkeyView.Delete()
    for item in hotkeyList {
        hotkeyView.Add("", item.Key, item.Function, item.Option)
    }
}

RemoveHotkey(*) {
    global

    row := hotkeyView.GetNext()

    if row {
        hotkeyList.RemoveAt(row)
        SaveHotkeys()
        ApplyHotkeys()
        RefreshHotkeys()
    }
}

ApplyHotkeys() {
    global hotkeyList, functionMap, activeHotkeys

    for key in activeHotkeys {
        try Hotkey(key, "Off")
    }

    activeHotkeys := []

    for item in hotkeyList {

        if item.Sequence != "" {
            Hotkey(item.Key, SendSequence.Bind(item.Sequence), "On")
        }
        else if functionMap.Has(item.Function) {
            Hotkey(item.Key, HotkeyAction.Bind(item), "On")
        }

        activeHotkeys.Push(item.Key)
    }
}

EquipMacro(sequence := "", *) {
    if sequence = ""
        return

    Send(sequence)
}

SpawnVehicle(vehicle := "", *) {
    global firstGarageSpawn

    if vehicle = ""
        return

    if firstGarageSpawn {
        sequence := BuildGarageFirstSequence(vehicle)
        firstGarageSpawn := false
    }
    else {
        sequence := BuildGarageSequence(vehicle)
    }

    Send(sequence)
}

BuildGarageFirstSequence(vehicle) {

    garageStart := IniRead("dynamic.ini", "Paths", "GarageFirstStart", "")

    if garageStart = "" {
        MsgBox("Garage first start path missing.")
        return ""
    }

    vehiclePath := BuildGaragePath(vehicle)

    if vehiclePath = ""
        return ""

    return garageStart vehiclePath "{Enter}{SC02B}"
}

LoadPath(name) {
    return IniRead("dynamic.ini", "Paths", name, "")
}

CombatLog(option := "", *) {
    sequence := LoadPath("logPath")

    if sequence = ""
        return

    Send(sequence)
}

SolvePower(option := "", *) {
    MsgBox("Solve power triggered.")
}

AddLoadoutHotkey(loadoutName) {
    global
    g := Gui(, "Create Loadout Hotkey")
    g.AddText(, "Key")
    keyBox := g.AddHotkey("w150")
    g.AddText(, "Loadout")
    g.AddText("w200", loadoutName)
    g.AddButton(, "Add").OnEvent("Click", SaveLoadoutHotkey.Bind(g, keyBox, loadoutName))
    g.Show()
}

SaveLoadoutHotkey(parent, keyBox, loadoutName, *) {
    global

    if keyBox.Value = "" {
        MsgBox("Select a key.")
        return
    }

    LoadLoadout(loadoutName)
    sequence := BuildSeq(LOADOUT)

    hotkeyList.Push({
        Key: keyBox.Value,
        Function: "Equip Guns",
        Option: loadoutName,
        Sequence: sequence
    })

    SaveHotkeys()
    RefreshHotkeys()
    ApplyHotkeys()

    parent.Destroy()
    MsgBox("Hotkey created!")
}

; ==========================
; BUILD MACRO SEQUENCE
; ==========================

BuildSeq(loadout := "") {
    global gunStoreGuns, gunStoreExplosives

    if !IsObject(loadout)
        loadout := LOADOUT

    w := "{SC011}"
    a := "{SC01E}"
    s := "{SC01F}"
    d := "{SC020}"

    seq := w a s d "{SC02B}" w w w w w w w w w w s a

    currentIndex := 1

    for _, item in loadout {

        targetIndex := 0
        isExplosive := false

        for index, v in gunStoreGuns {
            if v = item {
                targetIndex := index
                break
            }
        }

        if targetIndex = 0 {
            for index, v in gunStoreExplosives {
                if v = item {
                    targetIndex := index
                    isExplosive := true
                    break
                }
            }
        }

        if targetIndex = 0 {
            MsgBox("Invalid loadout item: " item)
            return ""
        }


        ; NORMAL WEAPONS
        if !isExplosive {

            steps := targetIndex - currentIndex

            if steps > 0 {
                Loop steps
                    seq .= d
            }
            else if steps < 0 {
                Loop Abs(steps)
                    seq .= a
            }

            seq .= "{Enter}"
            currentIndex := targetIndex
            continue
        }


        ; EXPLOSIVES

        steps := 1 - currentIndex

        if steps > 0 {
            Loop steps
                seq .= d
        }
        else if steps < 0 {
            Loop Abs(steps)
                seq .= a
        }

        currentIndex := 1

        seq .= a "{Enter}" s d


        explosiveSteps := targetIndex - 1

        if explosiveSteps > 0 {
            Loop explosiveSteps
                seq .= d
        }

        seq .= "{Enter}"


        ammoIndex := 0

        if item = "c4"
            ammoIndex := 2
        else if item = "smoke grenade"
            ammoIndex := 4
        else if item = "grenade"
            ammoIndex := 6
        else if item = "rocket launcher"
            ammoIndex := 7


        if ammoIndex > 0 {

            ammoSteps := ammoIndex - targetIndex

            if ammoSteps > 0 {
                Loop ammoSteps
                    seq .= d
            }
            else if ammoSteps < 0 {
                Loop Abs(ammoSteps)
                    seq .= a
            }


            seq .= "{Enter 10}"


            if ammoSteps > 0 {
                Loop ammoSteps
                    seq .= a
            }
            else if ammoSteps < 0 {
                Loop Abs(ammoSteps)
                    seq .= d
            }
        }


        if explosiveSteps > 0 {
            Loop explosiveSteps
                seq .= a
        }


        seq .= a w "{Enter}" s s d

        currentIndex := 1
    }

    seq .= "{SC02B}"

    return seq
}

BuildGaragePath(vehicle) {
    global garage

    reversedGarage := []

    for index, name in garage {
        reversedGarage.InsertAt(1, name)
    }

    location := 0

    for index, name in reversedGarage {
        if name = vehicle {
            location := index
            break
        }
    }

    if location = 0 {
        MsgBox("Vehicle not found: " vehicle)
        return ""
    }

    row := Ceil(location / 6)
    column := Mod(location - 1, 6) + 1

    s := "{SC01F}"
    a := "{SC01E}"
    d := "{SC020}"

    path := ""

    ; move down from slot 6
    if row > 1 {
        Loop (row - 1) {
            path .= s s
        }
    }
    ; move horizontally from column 6
    if column < 6 {
        Loop (6 - column) {
            path .= a
        }
    }
    return path
}

BuildGarageSequence(vehicle) {
    garageStart := IniRead("dynamic.ini", "Paths", "GarageStart", "")


    if garageStart = "" {
        MsgBox("Garage path missing.")
        return ""
    }
    vehiclePath := BuildGaragePath(vehicle)
    if vehiclePath = ""
        return ""

    return garageStart vehiclePath "{Enter}{SC02B}"
}
