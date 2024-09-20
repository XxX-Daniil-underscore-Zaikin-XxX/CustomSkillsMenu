Scriptname metaSkillMenuScript extends Quest  
{Controller script for MetaSkillMenu}
; Sorry for anybody reading this, this is not a good mod to learn from. I'm doing some weird shit here.

bool b_CustomSkillsExists = false
bool b_SkillTreesInstalled = false
bool b_CustomSkillsPapryusAPIExists = false

string asSkillId = ""

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

function load_data()
    string poolName = "menuInfoPool"
    ; turn files to array of strings
    int CSFFiles = JValue.addToPool(JValue.readFromDirectory("data/SKSE/Plugins/CustomSkills/", ".json"), poolName)
    jvalue.writetofile(CSFFiles, "data/interface/MetaSkillsMenu/rawData.json")

    ; start at the beginning
    string filekey = jmap.nextkey(CSFFiles)

    ; read hidedata
    int hideData
    if jcontainers.fileExistsAtPath("data/interface/MetaSkillsMenu/MSMHidden.json")
        hideData = JValue.addToPool(JValue.readFromFile("data/interface/MetaSkillsMenu/MSMHidden.json"), poolName)
    Else
        hideData = JValue.addToPool(Jmap.Object(), poolName)
    endif
    int allConfigsFormatted = JValue.addToPool(Jmap.Object(), poolName)
    ; WARNING
    ; We only load skill groups with a `showMenu`
    while filekey
        string filePoolName = "iterateFilePool"
        ; grab object associated with key
        int fileobj = JValue.addToPool(jmap.getobj(CSFFiles, filekey), filePoolName)
        string pluginName = StringUtil.Split(jmap.getstr(fileobj, "showMenu"), "|")[0]
        string fileName = StringUtil.Split(filekey, ".")[0]
        ;; oh my god why did I write this terrible code, it's jibberish
        ; yeah it sure is, did you write it on your phone or something?
        writelog("Loading skills from file: " + filekey)
        ; no clue what this is about, I think it's to do with old versions
        if ((!b_CustomSkillsPapryusAPIExists && JMap.getInt(fileobj, "CSFSKSE")))
            writelog("CSFSKSE Mod installed, but papyrus api not found: " + pluginName)
        else
            if (game.IsPluginInstalled(pluginName))
                ; copy the object (we'll change it and return it)
                int retobj = JValue.addToPool(jvalue.deepcopy(fileobj), filePoolName)

                ; Skill groups don't have a `Name` or `Description`, so we make do
                ; The user will have to set this manually
                JMap.setStr(retobj, "name", fileName)
                JMap.setStr(retobj, "description", "Skills belonging to " + fileName)

                ; get icon location, set flag if exists
                string icon_loc = jmap.getstr(fileobj, "icon_loc")
                if JContainers.fileExistsAtPath(icon_loc)
                    jmap.setint(retobj, "icon_exists", true as int)
                endif

                ; adds retobj under the key asSkillId to config storage
                jmap.setobj(allConfigsFormatted, fileName, retobj)

                ; check hideData for whether modNameThing is hidden
                string hiddenPath = "." + fileName + ".hidden"
                int valuetype = JValue.solvedValueType(hideData, hiddenPath)
                if valuetype != 2 ; if not int, i.e. if we don't find it
                    ; we go into the file and set it as false
                    JValue.SolveIntSetter(hideData, hiddenPath, false as int, true)
                endif ; MOD NAME THING HUH, WHAT A FUCKING AMAZING NAME ; haha, I'm keeping it then lol
                ; *now* we read it from the file
                jmap.setInt(retObj, "hidden", JValue.SolveInt(hideData, hiddenPath))
            else
                writelog("FAILED TO FIND MOD, MISSING ESP: " + pluginName, 2)
            endif
        endif
        ; go to next filekey
        filekey = jmap.nextkey(CSFFiles, filekey)
        JValue.cleanPool(filePoolName)
    endwhile

    ; check if we even found anything
    if jmap.count(allConfigsFormatted) > 0
        b_SkillTreesInstalled = true
    Else
        b_SkillTreesInstalled = false
    endif

    ; write our data to files
    jvalue.writetofile(hideData, "data/interface/MetaSkillsMenu/MSMHidden.json")
    jvalue.writetofile(allConfigsFormatted, "data/interface/MetaSkillsMenu/MSMData.json")

    JValue.cleanPool(poolName)
endfunction

event OpenMenu(string eventName, string strArg, float numArg, Form sender)
    doOpenMenu()
endEvent

function doOpenMenu()
    if b_CustomSkillsExists && b_SkillTreesInstalled
        UI.OpenCustomMenu("MetaSkillsMenu/CustomMetaMenu")
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

; CSF presents forms as e.g. example.esp|0xD61 - not compabitle with JContainers
Form function getFormFromCsfString(string csfString)
    string[] csfForm = StringUtil.Split(csfString, "|")
    string formFile = csfForm[0]
    int formId = PO3_SKSEFunctions.StringToInt(csfForm[1])

    Form retForm = Game.GetFormFromFile(formId, formFile)

    if (!retForm) 
        WriteLog("Could not find form " + csfForm[1] + " in mod " + formFile, 1)
    endif

    return retForm
EndFunction

event SelectedMenu(string eventName, string strArg, float numArg, Form sender)
    int MSMData = JValue.addToPool(JValue.readFromFile("data/interface/MetaSkillsMenu/MSMData.json"), "menuData")
    ; get chosen skill object from config
    int modObject = JValue.addToPool(JMap.getObj(MSMData, strArg), "menuData")
    GlobalVariable showMenuVar = getFormFromCsfString(JMap.getStr(modObject, "showMenu")) as GlobalVariable
    (showMenuVar as GlobalVariable).Mod(1.0)
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