Scriptname DenjiAPI

;/
==========================================================
CUSTOM SKILLS MENU API
----------------------------------------------------------
The following are global functions intended for use
in other mods to interact with the Custom Skills Menu.
==========================================================
/;


;/
==========================================================
PATHS AND STRINGS
==========================================================
/;


; Gets path to the Custom Skills Menu data files
string Function GetCSMPath() global
    return "data/interface/MetaSkillsMenu"
EndFunction

; Path to resolve the Custom Skills Menu's data in the JDB
string Function GetCSMJDBPath() global
    return ".CustomSkillsMenuv3.MenuData"
EndFunction


; Main data file's filename
string Function GetDataFilename() global
    return "MSMData.json" 
EndFunction

; Hidden cache's filename
string Function GetHiddenFilename() global
    return "MSMHidden.json"
EndFunction

; Flash settings's filename
string Function GetFlashSettingsFilename() global
    return "MSM_FLASH_SETTINGS.json"
EndFunction
          

; Path to hidden cache file relative to Skyrim
string Function GetHiddenFilePath() global
    return GetCSMPath() + "/" + GetHiddenFilename()
EndFunction

; Path to main data file relative to Skyrim
string Function GetDataFilePath() global
    return GetCSMPath() + "/" + GetDataFilename()
EndFunction

; Path to flash settings
string Function GetFlashSettingsFilePath() global
    return GetCSMPath() + "/" + GetFlashSettingsFilename()
EndFunction


; path to JDB entry for the Hidden prop of skillKey
string function GetDBSkillHiddenPath(string skillKey) global
    return GetCSMJDBPath() + getSkillHiddenPath(skillKey)
endFunction

; JContainers path to Hidden prop of skillKey
string function GetSkillHiddenPath(string skillKey) global
    return "." + skillKey + ".Hidden"
endFunction


;/
==========================================================
HIDDEN OPERATIONS
----------------------------------------------------------
Operations to get/set whether skills are hidden.
For all below functions, we are assuming that the JDB is
the source of truth
==========================================================
/;


; determines whether skillKey is hidden via JDB
bool function GetHidden(string skillKey) global
    return JDB.solveInt(getDBSkillHiddenPath(skillKey))
endFunction

; sets skillKey's hidden to newHidden
function SetHidden(string skillKey, bool newHidden) global
    JDB.solveIntSetter(getDBSkillHiddenPath(skillKey), newHidden as Int)

    SetHiddenInFile(skillKey, newHidden, GetHiddenFilePath())
    SetHiddenInFile(skillKey, newHidden, GetDataFilePath())
endFunction

; inverts skillKey's hidden
function ToggleHidden(string skillKey) global
    SetHidden(skillKey, !GetHidden(skillKey))
endFunction

; determines skillKey's hidden from a file given filePath
; assumes file is formatted like MSMData.json
bool function GetHiddenInFile(string skillKey, string filePath) global
    int file = JValue.readFromFile(filePath)
    bool ret = JValue.solveInt(file, getSkillHiddenPath(skillKey))

    JValue.release(file)
    return ret
endFunction

; sets a skill's Hidden property in the given file
; assumes file is formatted like MSMData.json or MSMHidden.json
function SetHiddenInFile(string skillKey, bool newHidden, string filePath) global
    int file = JValue.readFromFile(filePath)
    bool oldHidden = GetHiddenInFile(skillKey, filePath)

    if oldHidden != newHidden
        JValue.solveIntSetter(file, getSkillHiddenPath(skillKey), newHidden as Int)
        JValue.writeToFile(file, filePath)

        bool updatedHidden = GetHiddenInFile(skillKey, filePath)
        if updatedHidden != newHidden
            WriteLog("Unable to update Hidden in " + filePath + " to " + newHidden, 2)
        endif
    endif

    JValue.release(file)
endFunction


;/
==========================================================
MISCELLANEOUS HELPERS
----------------------------------------------------------
Miscellaneous functions which make more sense as globals
==========================================================
/;


; writes printMessage to log
; error = 0 writes to console
; error = 1 displays a notification
; error = 2 opens a messagebox
function WriteLog(string printMessage, int error = 0) global
    string a = "Custom Skill Menu: "
    if error >= 1
        Debug.Notification(a + printMessage)
    endif
    if error >= 2
        Debug.MessageBox(a +"\n"+ printMessage)
    endif
    ConsoleUtil.PrintMessage(a + printMessage)
    Debug.Trace(a + printMessage)
endfunction