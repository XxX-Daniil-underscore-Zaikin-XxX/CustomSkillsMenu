Scriptname metaSkillMenuMCM extends SKI_ConfigBase
{Meta Skills Menu MCM}

; code

metaSkillMenuScript property metaSkillMenuMain auto

string flashDataPath = DenjiAPI.GetCSMPath() + "/MSM_FLASH_SETTINGS.json"

int OpenCustomSkillMenuKeycode = 0

event OnConfigInit()
    if OpenCustomSkillMenuKeycode != 0
        registerforkey(OpenCustomSkillMenuKeycode)
    endif
endEvent

Event OnPageReset(string page)
    AddHeaderOption("KeyBinds: ")
    AddHeaderOption("Hidden: ")
    AddKeyMapOptionST("RebindCSMKeycode", "Show Custom Skills Menu", OpenCustomSkillMenuKeycode)
    SetCursorPosition(4)
    if (Jcontainers.fileExistsAtPath(flashDataPath))
        int data1 = JValue.ReadFromFile(flashDataPath)
        AddToggleOptionST("HintToggleState", "Hide Hint", jmap.getInt(data1, "hide_hint") as bool)
    endif
    SetCursorPosition(3)
    SetCursorFillMode(TOP_TO_BOTTOM)
    
    If (jcontainers.fileExistsAtPath(DenjiAPI.GetHiddenFilePath()) && jcontainers.fileExistsAtPath(DenjiAPI.GetDataFilePath()))
        int data = JValue.ReadFromFile(DenjiAPI.GetDataFilePath())
        String dataKey = JMap.NextKey(data)
        while dataKey
            string csfName = JValue.SolveStr(data, "."+dataKey+".Name")
            bool isHidden = JValue.SolveInt(data, "."+dataKey+".Hidden") as bool
            AddToggleOptionST("ToggleHidden___"+dataKey, csfName, isHidden)
            datakey = JMap.NextKey(data, datakey)
        endwhile
    Else
        AddHeaderOption("Error, CSM database files not found.")
    endif
endEvent

state HintToggleState
    event OnSelectST()
        if (Jcontainers.fileExistsAtPath(flashDataPath))
            int data = JValue.ReadFromFile(flashDataPath)
            jmap.setInt(data, "hide_hint", (!jmap.getInt(data, "hide_hint") as bool) as int)
            Jvalue.WriteToFile(data, flashDataPath)
            SetToggleOptionValueST(jmap.getInt(data, "hide_hint") as bool,false,"HintToggleState")
        endif
    endEvent

    event onHighlightST()
        SetInfoText("Hide the hint in the tweenmenu telling you how to access the custom skills menu.")
    endEvent
endState 

event OnSelectST()
    string[] stateNameFull = StringUtil.Split(GetState(), "___")
    if stateNameFull.Length > 1
        String csfName = stateNameFull[1]

        DenjiAPI.ToggleHidden(csfName)
        bool newHidden = DenjiAPI.GetHidden(csfName)

        SetToggleOptionValueST(newHidden, false, GetState())
    endif
endEvent

event onHighlightST()
    string[] stateNameFull = StringUtil.Split(GetState(), "___")
    if stateNameFull.Length > 1
        string csfName = stateNameFull[1]
        int data = JValue.ReadFromFile(DenjiAPI.GetDataFilePath())
        SetInfoText("ESP Name: " \
            + JValue.SolveStr(data, "."+csfName+".plugin") \
            + "\n" + "Icon path: " \
            + JValue.SolveStr(data, "."+csfName+".icon_loc") \
        )
        jvalue.release(data)
    endif
endEvent

state RebindCSMKeycode
    event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
        unregisterforallkeys()
        OpenCustomSkillMenuKeycode = keyCode
        registerforkey(OpenCustomSkillMenuKeycode)
        SetKeyMapOptionValueST(keyCode)
    endevent
endState

Event OnKeyDown(int keycode)
    If (keycode == OpenCustomSkillMenuKeycode) && !UI.IsMenuOpen("CustomMenu")
        metaSkillMenuMain.doOpenMenu()
    endif
endEvent