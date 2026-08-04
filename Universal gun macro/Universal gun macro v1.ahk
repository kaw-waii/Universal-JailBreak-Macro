; ==========================
; GLOBALS
; ==========================

global LOADOUT := []
global dragStartRow := 0
global dragging := false
global weapons := ["pistol", "shotgun", "rifle", "revolver", "flintlock", "ak-47", "sword", "uzi", "forcefield launcher", "plasma pistol", "plasma shotgun", "sniper", "c4", "smoke grenade", "grenade", "rocket launcher"]
global gunStoreGuns := ["pistol", "shotgun", "rifle", "revolver", "flintlock", "ak-47", "sword", "uzi", "forcefield launcher", "plasma pistol", "plasma shotgun", "sniper"]
global gunStoreExplosives := ["c4", "c4 ammo", "smoke grenade", "smokecartridge", "grenade", "grenade ammo", "rocket ammo",  "rocket launcher"]
global equipSequence := ""
global equipKey := "F3"
global exitKey := "F6"
global weaponList
global loadoutList
global equipBox
global exitBox
global selectedLoadoutRow := 1

; ==========================
; STARTUP
; ==========================

LoadSettings()
BuildGui()
RebuildMacro()
ApplyHotkeys()

; ==========================
; GUI
; ==========================

BuildGui() {
    global

    mainGui := Gui(, "Universal JailBreak Macro")

    mainGui.AddText("x20 y10", "Available Weapons")
    weaponList := mainGui.AddListBox(
        "x20 y30 w160 h260"
    )

    mainGui.AddText("x260 y10", "Current Loadout")
    loadoutList := mainGui.AddListView(
        "x260 y30 w200 h260",
        ["", "Weapon"]
    )

    loadoutList.OnEvent(
        "Click",
        LoadoutClicked
    )

    loadoutList.ModifyCol(1, 25)
    loadoutList.ModifyCol(2, 150)

    mainGui.AddButton(
        "x190 y90 w50",
        ">>"
    ).OnEvent(
        "Click",
        AddWeapon
    )

    mainGui.AddButton(
        "x190 y140 w50",
        "<<"
    ).OnEvent(
        "Click",
        RemoveWeapon
    )

    mainGui.AddButton(
        "x260 y300 w75",
        "Move Up"
    ).OnEvent(
        "Click",
        MoveUp
    )

    mainGui.AddButton(
        "x345 y300 w75",
        "Move Down"
    ).OnEvent(
        "Click",
        MoveDown
    )

    mainGui.AddText(
        "x20 y330",
        "Equip Hotkey"
    )

    equipBox := mainGui.AddHotkey(
        "x20 y350 w160",
        equipKey
    )

    mainGui.AddText(
        "x260 y330",
        "Exit Hotkey"
    )

    exitBox := mainGui.AddHotkey(
        "x260 y350 w160",
        exitKey
    )

    mainGui.AddButton(
        "x20 y380 w100",
        "Save"
    ).OnEvent(
        "Click",
        SaveSettings
    )

    mainGui.AddButton(
        "x140 y380 w100",
        "Reload"
    ).OnEvent(
        "Click",
        ReloadConfig
    )

    RefreshLists()

    mainGui.Show()
}

; ==========================
; LIST MANAGEMENT
; ==========================

RefreshLists() {
    global

    weaponList.Delete()

    for weapon in weapons
    {
        exists := false

        for item in LOADOUT
        {
            if item = weapon
            {
                exists := true
                break
            }
        }

        if !exists
            weaponList.Add([weapon])
    }  

    loadoutList.Delete() 

    for index, weapon in LOADOUT
    {
        arrow := ""

        if index = selectedLoadoutRow
            arrow := "▶"

        loadoutList.Add(
            "",
            arrow,
            weapon
        )
    }
}

AddWeapon(*) {
    global 

    item := weaponList.Text

    if item = ""
        return 

    LOADOUT.Push(item)

    RefreshLists()
}

RemoveWeapon(*) {
    global

    if selectedLoadoutRow < 1
        return

    if selectedLoadoutRow > LOADOUT.Length
        return

    LOADOUT.RemoveAt(selectedLoadoutRow)


    ; move selection to a valid item
    if selectedLoadoutRow > LOADOUT.Length
        selectedLoadoutRow := LOADOUT.Length


    RefreshLists()
}

; ==========================
; SAVE / LOAD
; ==========================

LoadSettings() {
    global 

    equipKey := IniRead(
        "settings.ini",
        "Keys",
        "Equip",
        "F3"
    ) 

    exitKey := IniRead(
        "settings.ini",
        "Keys",
        "Exit",
        "F6"
    ) 

    LOADOUT := [] 

    Loop 50
    {
        item := IniRead(
            "settings.ini",
            "Loadout",
            A_Index,
            ""
        ) 

        if item != ""
            LOADOUT.Push(item)
    } 

    if LOADOUT.Length = 0
    {
        LOADOUT := []
    }
}

SaveSettings(*) {
    global 

    equipKey := equipBox.Value
    exitKey := exitBox.Value 

    IniWrite(
        equipKey,
        "settings.ini",
        "Keys",
        "Equip"
    ) 

    IniWrite(
        exitKey,
        "settings.ini",
        "Keys",
        "Exit"
    ) 

    IniDelete(
        "settings.ini",
        "Loadout"
    ) 

    for i,item in LOADOUT
    {
        IniWrite(
            item,
            "settings.ini",
            "Loadout",
            i
        )
    } 

    RebuildMacro()

    ApplyHotkeys() 

    MsgBox("Saved!")
}

ReloadConfig(*) {
    LoadSettings()
    RefreshLists()
    RebuildMacro()
    ApplyHotkeys()
}

; ==========================
; LOADOUT SORTING
; ==========================

MoveLoadoutItem(from,to) {
    global 

    if from = to
        return 

    item := LOADOUT.RemoveAt(from)

    LOADOUT.InsertAt(
        to,
        item
    ) 

    selectedLoadoutRow := to

    RefreshLists()
}

MoveUp(*) {
    global 

    row := selectedLoadoutRow 

    if row <= 1
        return 

    MoveLoadoutItem(
        row,
        row - 1
    )
}

MoveDown(*) {
    global 

    row := selectedLoadoutRow 

    if row >= LOADOUT.Length
        return 

    MoveLoadoutItem(
        row,
        row + 1
    )
}

LoadoutClicked(ctrl, info) {
    global

    row := loadoutList.GetNext()

    if row
    {
        selectedLoadoutRow := row
        RefreshLists()
    }
}

; ==========================
; HOTKEYS
; ==========================

ApplyHotkeys() {
    global 

    try Hotkey(
        equipKey,
        EquipMacro,
        "On"
    ) 

    try Hotkey(
        exitKey,
        ExitApp,
        "On"
    )
}

EquipMacro(*) {
    global

    Send(equipSequence)
}

; ==========================
; BUILD MACRO SEQUENCE
; ==========================

RebuildMacro() {
    global

    equipSequence := BuildSeq()
}

BuildSeq() {
    global LOADOUT, gunStoreGuns, gunStoreExplosives 

    w := "{SC011}"
    a := "{SC01E}"
    s := "{SC01F}"
    d := "{SC020}" 

    seq := w a s d "{SC02B}" w w w w w w w w w w s a 

    currentIndex := 1 

    for _, item in LOADOUT
    {
        targetIndex := 0
        isExplosive := false 

        for index, v in gunStoreGuns
        {
            if (v = item)
            {
                targetIndex := index
                break
            }
        } 

        if targetIndex = 0
        {
            for index, v in gunStoreExplosives
            {
                if (v = item)
                {
                    targetIndex := index
                    isExplosive := true
                    break
                }
            }
        } 

        if targetIndex = 0
        {
            MsgBox(
                "Invalid loadout item: "
                item
            )

            return ""
        }  

        ; ======================
        ; NORMAL WEAPONS
        ; ======================

        if !isExplosive
        {
            steps := targetIndex - currentIndex 

            if steps > 0
            {
                Loop steps
                    seq .= d
            }
            else if steps < 0
            {
                Loop Abs(steps)
                    seq .= a
            } 

            seq .= "{Enter}"

            currentIndex := targetIndex

            continue
        }  

        ; ======================
        ; EXPLOSIVES
        ; ====================== 

        steps := 1 - currentIndex 

        if steps > 0
        {
            Loop steps
                seq .= d
        }
        else if steps < 0
        {
            Loop Abs(steps)
                seq .= a
        } 

        currentIndex := 1 

        seq .= a "{Enter}" s d 

        explosiveSteps := targetIndex - 1 

        if explosiveSteps > 0
        {
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

        if ammoIndex > 0
        {
            ammoSteps := ammoIndex - targetIndex 

            if ammoSteps > 0
            {
                Loop ammoSteps
                    seq .= d
            }
            else if ammoSteps < 0
            {
                Loop Abs(ammoSteps)
                    seq .= a
            } 

            seq .= "{Enter 10}" 

            if ammoSteps > 0
            {
                Loop ammoSteps
                    seq .= a
            }
            else if ammoSteps < 0
            {
                Loop Abs(ammoSteps)
                    seq .= d
            }
        }  

        if explosiveSteps > 0
        {
            Loop explosiveSteps
                seq .= a
        } 

        seq .= a w "{Enter}" s s d 

        currentIndex := 1
    } 

    seq .= "{SC02B}" 

    return seq
}
