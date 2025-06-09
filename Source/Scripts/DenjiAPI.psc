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
          

; Path to hidden cache file relative to Skyrim
string Function GetHiddenFilePath() global
    return GetCSMPath() + "/" + GetHiddenFilename()
EndFunction

; Path to main data file relative to Skyrim
string Function GetDataFilePath() global
    return GetCSMPath() + "/" + GetDataFilename()
EndFunction

;/
==========================================================
HIDDEN OPERATIONS
----------------------------------------------------------
Operations to get/set whether skills are hidden.
For all below functions, we are assuming that the JDB is
the source of truth
==========================================================
/;


; gets path to JDB entry for the Hidden prop of skillName
string function GetDBSkillHiddenPath(string skillName) global
    return GetCSMJDBPath() + getSkillHiddenPath(skillName)
endFunction

; gets JContainers path to Hidden prop of skillName
string function GetSkillHiddenPath(string skillName) global
    return "." + skillName + ".Hidden"
endFunction

; determines whether skillName is hidden via JDB
bool function GetHidden(string skillName) global
    return JDB.solveInt(getDBSkillHiddenPath(skillName))
endFunction

; sets skillName's hidden to newHidden
function SetHidden(string skillName, bool newHidden) global
    JDB.solveIntSetter(getDBSkillHiddenPath(skillName), newHidden as Int)

    SetHiddenInFile(skillName, newHidden, GetHiddenFilePath())
    SetHiddenInFile(skillName, newHidden, GetDataFilePath())
endFunction

; inverts skillName's hidden
function ToggleHidden(string skillName) global
    SetHidden(skillName, !GetHidden(skillName))
endFunction

; determines skillName's hidden from a file given filePath
; assumes file is formatted like MSMData.json
bool function GetHiddenInFile(string skillName, string filePath) global
    int file = JValue.readFromFile(filePath)
    bool ret = JValue.solveInt(file, getSkillHiddenPath(skillName))

    JValue.release(file)
    return ret
endFunction

; sets a skill's Hidden property in the given file
; assumes file is formatted like MSMData.json or MSMHidden.json
function SetHiddenInFile(string skillName, bool newHidden, string filePath) global
    int file = JValue.readFromFile(filePath)
    bool oldHidden = GetHiddenInFile(skillName, filePath)

    if oldHidden != newHidden
        JValue.solveIntSetter(file, getSkillHiddenPath(skillName), newHidden as Int)
        JValue.writeToFile(file, filePath)

        bool updatedHidden = GetHiddenInFile(skillName, filePath)
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