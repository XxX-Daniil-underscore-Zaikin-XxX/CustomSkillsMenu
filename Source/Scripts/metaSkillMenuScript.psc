Scriptname metaSkillMenuScript extends Quest  
{Controller script for MetaSkillMenu}

; whether the mod and its requirements are installed
bool b_CustomSkillsExists = false
; whether any Custom Skills are installed
bool b_SkillTreesInstalled = false
; whether the Custom Skills native api is installed
bool b_CustomSkillsPapryusAPIExists = false
; whether any Custom Skills are actually viewable (i.e. not hidden)
bool b_SkillTreesPresent = false

event OnInit()
    startup()
endEvent

function startup()
    if doSafetyCheck()
        load_data()
        register_events()
    endif
endfunction

bool function doSafetyCheck()
    If !jcontainers.isInstalled()
        Writelog("JContainers is not detected!\nMake sure you are using the correct JContainers version for your game version.\n\n(jcontainers.isInstalled() did not return true)", 2)
        b_CustomSkillsExists = false
        b_CustomSkillsPapryusAPIExists = false
        return false
    else
        if CustomSkills.GetAPIVersion()
            b_CustomSkillsPapryusAPIExists = true
            b_CustomSkillsExists = true
        elseif jcontainers.fileExistsAtPath("data/NetScriptFramework/Plugins/CustomSkills.dll")
            b_CustomSkillsPapryusAPIExists = false
            b_CustomSkillsExists = true
        else
            b_CustomSkillsPapryusAPIExists = false
            b_CustomSkillsExists = false
            Writelog("Custom Skill Framework by Meh321 was not detected, make sure the mod is installed correctly.\n(Failed to find CustomSkills.dll) or CustomSkills API", 2)
            return false
        endif
        writelog("b_CustomSkillsExists "+b_CustomSkillsExists)
        writelog("b_SkillTreesInstalled "+b_SkillTreesInstalled)
        writelog("b_CustomSkillsPapryusAPIExists "+b_CustomSkillsPapryusAPIExists)
        return true
    endif
endFunction

function register_events()
    registerformodevent("MetaSkillMenu_Open", "OpenMenu")
    registerformodevent("MetaSkillMenu_Close", "CloseMenu")
    registerformodevent("MetaSkillMenu_Selection", "SelectedMenu")
endfunction

; Attempts to read an object from a given filepath. If it doesn't succeed, return an empty object
int function tryGetObjFromFile(string filePath, string poolName)
    if jcontainers.fileExistsAtPath(filePath)
        return JValue.addToPool(JValue.readFromFile(filePath), poolName)
    Else
        return JValue.addToPool(Jmap.Object(), poolName)
    endif
EndFunction

function load_data()
    string poolName = "menuInfoPool"
    ; turn files to array of strings
    int CSFFiles = JValue.addToPool(JValue.readFromDirectory("data/SKSE/Plugins/CustomSkills/", ".json"), poolName)
    jvalue.writetofile(CSFFiles, "data/interface/MetaSkillsMenu/rawData.json")

    ; read saved data
    int hideData = tryGetObjFromFile("data/interface/MetaSkillsMenu/MSMHidden.json", poolName)
    int savedData = tryGetObjFromFile("data/interface/MetaSkillsMenu/MSMData.json", poolName)

    ; pre-format our data
    int loadedConfigs = JValue.addToPool(JMap.object(), poolName)
    JMap.setObj(loadedConfigs, "original", savedData)
    JMap.setObj(loadedConfigs, "new", CSFFiles)
    int allConfigsTrimmed = JValue.addToPool(JValue.evalLuaObj(loadedConfigs, "return msm.loadCustomMenu(jobject)"), poolName)

    ; process hidden data also
    int jConfWithHidden = JValue.addToPool(JMap.object(), poolName)
    JMap.setObj(jConfWithHidden, "menus", allConfigsTrimmed)
    JMap.setObj(jConfWithHidden, "hidden", hideData)
    int jHiddenReturn = JValue.addToPool(JValue.evalLuaObj(jConfWithHidden, "return msm.applyHiddenHelper(jobject)"), poolName)

    int jCustomMenuPreFormatted = JValue.addToPool(JMap.getObj(jHiddenReturn, "menus"), poolName)

    int allConfigsFormatted = JValue.addToPool(JMap.object(), poolName)

    ; start at the beginning
    string filekey = jmap.nextkey(jCustomMenuPreFormatted)
    ; WARNING
    ; We only load skill groups with a `ShowMenu`
    while filekey
        string filePoolName = "iterateFilePool"
        ; grab object associated with key
        int fileobj = JValue.addToPool(jmap.getobj(jCustomMenuPreFormatted, filekey), filePoolName)
        string pluginName = jmap.getstr(fileobj, "plugin")

        Writelog("Loading skills from file: " + filekey)
        WriteLog("Using this to display menu: " + JMap.getStr(fileobj, "ShowMenu"))
        WriteLog("Hidden? " + JMap.getInt(fileobj, "hidden"))
        if (game.IsPluginInstalled(pluginName))
            ; copy the object (we'll change it and return it)
            int retobj = JValue.addToPool(jvalue.deepcopy(fileobj), filePoolName)

            ; if at least one is unhidden, we set it to true
            if JMap.getInt(fileobj, "hidden") == 0
                b_SkillTreesPresent = True
            endif

            ; get icon location, set flag if exists
            string icon_loc = jmap.getstr(fileobj, "icon_loc")
            if JContainers.fileExistsAtPath(icon_loc)
                jmap.setint(retobj, "icon_exists", true as int)
            endif

            ; adds retobj under the key asSkillId to config storage
            jmap.setobj(allConfigsFormatted, filekey, retobj)
        else
            writelog("FAILED TO FIND MOD, MISSING ESP: " + pluginName, 2)
        endif

        ; go to next filekey
        filekey = jmap.nextkey(jCustomMenuPreFormatted, filekey)
        JValue.cleanPool(filePoolName)
    endwhile

    ; check if we even found anything
    if jmap.count(allConfigsFormatted) > 0
        b_SkillTreesInstalled = true
    Else
        b_SkillTreesInstalled = false
    endif

    ; write our data to files
    jvalue.writetofile(JMap.getObj(jHiddenReturn, "hidden"), "data/interface/MetaSkillsMenu/MSMHidden.json")
    jvalue.writetofile(allConfigsFormatted, "data/interface/MetaSkillsMenu/MSMData.json")

    ; write to DB for faster access
    JDB.solveObjSetter(".CustomSkillsMenuv3.MenuData", allConfigsFormatted, createMissingKeys=true)

    JValue.cleanPool(poolName)
endfunction

event OpenMenu(string eventName, string strArg, float numArg, Form sender)
    doOpenMenu()
endEvent

function doOpenMenu()
    if b_CustomSkillsExists && b_SkillTreesInstalled && b_SkillTreesPresent
        UI.OpenCustomMenu("MetaSkillsMenu/CustomMetaMenu")
    elseif b_SkillTreesInstalled && !b_SkillTreesPresent
        UI.Invoke("TweenMenu", "_root.TweenMenu_mc.ShowMenu")
        Writelog("Skill trees found, but none accessible through this menu.", 1)
    else
        UI.Invoke("TweenMenu", "_root.TweenMenu_mc.ShowMenu")
        Writelog("No skill trees found, closing menu.", 1)
    endif
endFunction

event CloseMenu(string eventName, string strArg, float numArg, Form sender)
    doCloseMenu()
endEvent

function doCloseMenu()
    UI.Invoke("TweenMenu", "_root.TweenMenu_mc.ShowMenu")
endFunction

event SelectedMenu(string eventName, string strArg, float numArg, Form sender)
    int MSMData = JValue.addToPool(JDB.solveObj(".CustomSkillsMenuv3.MenuData"), "menuData")
    if (!JValue.isExists(MSMData))
        MSMData = JValue.addToPool(JValue.readFromFile("data/interface/MetaSkillsMenu/MSMData.json"), "menuData")
        JDB.solveObjSetter(".CustomSkillsMenuv3.MenuData", MSMData, createMissingKeys=true)
    endif
    
    ; get chosen skill object from config
    int modObject = JValue.addToPool(JMap.getObj(MSMData, strArg), "menuData")

    GlobalVariable showMenuVar = JString.decodeFormStringToForm(JMap.getStr(modObject, "ShowMenu")) as GlobalVariable
    showMenuVar.Mod(1.0)
    UI.CloseCustomMenu()
    JValue.cleanPool("menuData")
endEvent

function WriteLog(string printMessage, int error = 0)
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