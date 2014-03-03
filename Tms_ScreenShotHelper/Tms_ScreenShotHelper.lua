----------------------------------------------------
-- 茗伊截图助手 ver 0.1 Build 20140226
-- Code by: 翟一鸣tinymins @ ZhaiYiMing.CoM
-- 电五·双梦镇·茗伊
----------------------------------------------------
Tms_ScreenShotHelper = Tms_ScreenShotHelper or {}
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
local _PluginVersion = {
	dwVersion = 0x0010000,
	szBuildDate = "20140226",
}
local _ScreenShotHelperDataDefault = {
    bUseGlobalSetting = true,
    szFileExName = "jpg",
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = "./ScreenShot/",
}
local _ScreenShotHelperDataGlobal = LoadLUAData("/Interface/Tms_ScreenShotHelper/Global.dat")
_ScreenShotHelperDataGlobal = _ScreenShotHelperDataGlobal or _ScreenShotHelperDataDefault
_ScreenShotHelperData = _ScreenShotHelperData or _ScreenShotHelperDataDefault
for k, _ in pairs(_ScreenShotHelperData) do
	RegisterCustomData("_ScreenShotHelperData." .. k)
end
local _ScreenShotHelperCache = {
    loaded = false,
}
----------------------------------------------------
-- 数据初始化
Tms_ScreenShotHelper.Loaded = function()
    if(_ScreenShotHelperCache.loaded) then return end
    _ScreenShotHelperCache.loaded = true
    
    Player_AppendAddonMenu({function()
        return {
            Tms_ScreenShotHelper.GetMenuList()
        }
    end })
    -- Target_AppendAddonMenu({ function(dwID)
        -- return {
            -- Tms_ScreenShotHelper.GetTargetMenu(dwID),
        -- }
    -- end })
    Tms_ScreenShotHelper.Reload()
    TMS.BreatheCall("Tms_ScreenShot_Hotkey_Check", function() local nKey, nShift, nCtrl, nAlt = Hotkey.Get("Tms_ScreenShot_Hotkey") if nKey==0 then Hotkey.Set("Tms_ScreenShot_Hotkey",1,44,false,false,false) end end, 10000)
    
    OutputMessage("MSG_SYS", "[茗伊插件]数据加载成功，欢迎使用茗伊截图助手。\n")
end
Tms_ScreenShotHelper.Reload = function(bLoadGlobalData)
    if bLoadGlobalData==true then 
        _ScreenShotHelperDataGlobal = LoadLUAData("/Interface/Tms_ScreenShotHelper/Global.dat")
    elseif _ScreenShotHelperData.bUseGlobalSetting then
        SaveLUAData("/Interface/Tms_ScreenShotHelper/Global.dat", _ScreenShotHelperDataGlobal)
    end
end
-----------------------------------------------
-- 通用函数
-----------------------------------------------
-- (string, number) Tms_ScreenShotHelper.GetVersion()		-- HM的 获取字符串版本号 修改方便拿过来了
Tms_ScreenShotHelper.GetVersion = function()
	local v = _PluginVersion.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end

Tms_ScreenShotHelper.ShotScreen = function(nShowUI, nQuality, bFullPath)
    if nQuality==nil then
        local szFilePath, nQuality ,bFullPath, szFolderPath, bStationVisible, _SettingData
        _SettingData = (_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal) or _ScreenShotHelperData
        local tDateTime = TimeToDate(GetCurrentTime())
        local i=0
        szFolderPath = _SettingData.szFilePath
        if not IsFileExist(szFolderPath) then
            szFolderPath = _ScreenShotHelperDataDefault.szFilePath
            OutputMessage("MSG_SYS", "截图文件夹设置错误：".._SettingData.szFilePath.."目录不存在。已保存截图到默认位置。\n")
        end
        repeat
            szFilePath = szFolderPath .. (string.format("%04d-%02d-%02d_%02d-%02d-%02d-%03d", tDateTime.year, tDateTime.month, tDateTime.day, tDateTime.hour, tDateTime.minute, tDateTime.second, i)) .."." .. _SettingData.szFileExName
            i=i+1
        until not IsFileExist(szFilePath)
        nQuality = _SettingData.nQuality
        bFullPath = true -- bFullPath = (string.sub(szFilePath,2,2) == ":")
        bStationVisible = Station.IsVisible()
        if nShowUI == 0 then
            if bStationVisible then Station.Hide() end
            TMS.DelayCall(function()
                Tms_ScreenShotHelper.ShotScreen(szFilePath, nQuality, bFullPath)
                if bStationVisible then Station.Show() end
            end,100)
        elseif nShowUI == 1 then
            if not bStationVisible then Station.Show() end
            TMS.DelayCall(function()
                Tms_ScreenShotHelper.ShotScreen(szFilePath, nQuality, bFullPath)
                if not bStationVisible then Station.Hide() end
            end,100)
        else
            if bStationVisible and _SettingData.bAutoHideUI then Station.Hide() end
            TMS.DelayCall(function()
                Tms_ScreenShotHelper.ShotScreen(szFilePath, nQuality, bFullPath)
                if bStationVisible and _SettingData.bAutoHideUI then Station.Show() end
            end,100)
        end
    else
        local szFullPath = ScreenShot(nShowUI, nQuality, bFullPath)
        OutputMessage("MSG_SYS", "[茗伊插件]截图成功，文件已保存："..szFullPath.."\n")
    end
end
---------------------------------------------------
-- 创建菜单
function Tms_ScreenShotHelper.GetMenuList()
	local szVersion,v  = Tms_ScreenShotHelper.GetVersion()
	return
    {  -- 主菜单
        szOption = "茗伊截图助手",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_LEFT",
        { szOption = "当前版本 "..szVersion.."  ".._PluginVersion.szBuildDate,bDisable = true, },
        {  -- 使用所有账号全局设定
			szOption = "【使用所有账号全局设定】 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _ScreenShotHelperData.bUseGlobalSetting,
			fnAction = function()
                _ScreenShotHelperData.bUseGlobalSetting = not _ScreenShotHelperData.bUseGlobalSetting
                if _ScreenShotHelperData.bUseGlobalSetting then Tms_ScreenShotHelper.Reload(true) end
			end,
			fnMouseEnter = function()
				TMS.MenuTip("【数据设定模式】\n勾选该项则该角色使用公共设定，取消勾选则该角色使用单独设定。")
			end,
			fnAutoClose = function() return true end
		},
        {bDevide = true},
        {  -- 截图时隐藏UI
			szOption = "【截图时隐藏UI】 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = (_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal.bAutoHideUI) or (not _ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperData.bAutoHideUI),
			fnAction = function()
                if _ScreenShotHelperData.bUseGlobalSetting then
                    _ScreenShotHelperDataGlobal.bAutoHideUI = not _ScreenShotHelperDataGlobal.bAutoHideUI
                else
                    _ScreenShotHelperData.bAutoHideUI = not _ScreenShotHelperData.bAutoHideUI
                end
                Tms_ScreenShotHelper.Reload() 
			end,
			fnMouseEnter = function()
				TMS.MenuTip("【茗伊截图助手】\n勾选该项则截图时自动隐藏UI。")
			end,
			fnAutoClose = function() return true end
		},
        {  -- 保存格式
			szOption = "图片保存格式 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function() end,
			fnAutoClose = function() return true end,
            --jpg
            {szOption = "jpg", bMCheck = true, bChecked = (_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal.szFileExName=="jpg") or (not _ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperData.szFileExName=="jpg"), rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() if _ScreenShotHelperData.bUseGlobalSetting then _ScreenShotHelperDataGlobal.szFileExName="jpg" else _ScreenShotHelperData.szFileExName="jpg" end Tms_ScreenShotHelper.Reload() end, fnAutoClose = function() return true end},
            --png
            {szOption = "png", bMCheck = true, bChecked = (_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal.szFileExName=="png") or (not _ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperData.szFileExName=="png"), rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() if _ScreenShotHelperData.bUseGlobalSetting then _ScreenShotHelperDataGlobal.szFileExName="png" else _ScreenShotHelperData.szFileExName="png" end Tms_ScreenShotHelper.Reload() end, fnAutoClose = function() return true end},
            --bmp
            {szOption = "bmp", bMCheck = true, bChecked = (_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal.szFileExName=="bmp") or (not _ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperData.szFileExName=="bmp"), rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() if _ScreenShotHelperData.bUseGlobalSetting then _ScreenShotHelperDataGlobal.szFileExName="bmp" else _ScreenShotHelperData.szFileExName="bmp" end Tms_ScreenShotHelper.Reload() end, fnAutoClose = function() return true end},
            --tga
            {szOption = "tga", bMCheck = true, bChecked = (_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal.szFileExName=="tga") or (not _ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperData.szFileExName=="tga"), rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() if _ScreenShotHelperData.bUseGlobalSetting then _ScreenShotHelperDataGlobal.szFileExName="tga" else _ScreenShotHelperData.szFileExName="tga" end Tms_ScreenShotHelper.Reload() end, fnAutoClose = function() return true end},
		},
        {  -- 保存图片精度
            szOption = "设置截图精度(0-100) ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
            bCheck = false,
            bChecked = false,
            fnAction = function()
                -- 弹出界面
                GetUserInputNumber((_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal.nQuality) or _ScreenShotHelperData.nQuality, 100, nil, function(num) if _ScreenShotHelperData.bUseGlobalSetting then _ScreenShotHelperDataGlobal.nQuality=num else _ScreenShotHelperData.nQuality=num end Tms_ScreenShotHelper.Reload() end, function() end, function() end)
            end,
            fnMouseEnter = function()
                TMS.MenuTip("【茗伊截图助手】\n设置截图精度(0-100)：越大越清晰 图片也会越占空间。")
            end,
            fnAutoClose = function() return true end
        },
        {  -- 设置截图文件夹
            szOption = "设置截图文件夹 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
            bCheck = false,
            bChecked = false,
            fnAction = function()
                GetUserInput("设置截图文件夹 输入为空则恢复默认文件夹", function(nVal)
                    nVal = string.gsub(nVal, "^%s*(.-)%s*$", "%1")
                    nVal = string.gsub(nVal, "^(.-)[\/]*$", "%1")
                    if nVal=="" then nVal = _ScreenShotHelperDataDefault.szFilePath else nVal = nVal .. "/" end
                    if _ScreenShotHelperData.bUseGlobalSetting then
                        _ScreenShotHelperDataGlobal.szFilePath = nVal
                    else
                        _ScreenShotHelperData.szFilePath = nVal
                    end
                    Tms_ScreenShotHelper.Reload()
                end, function() end, function() end, nil, (_ScreenShotHelperData.bUseGlobalSetting and _ScreenShotHelperDataGlobal.szFilePath) or _ScreenShotHelperData.szFilePath)
            end,
            fnMouseEnter = function()
                TMS.MenuTip("【茗伊截图助手】\n设置截图文件夹，截图文件将保存到设置的目录中，支持绝对路径和相对路径，相对路径基于/bin/zhcn/。")
            end,
            fnAutoClose = function() return true end
        },
    }
end
-----------------------------------------------
-- 事件绑定
-----------------------------------------------
RegisterEvent("CUSTOM_DATA_LOADED", Tms_ScreenShotHelper.Loaded)
-- RegisterEvent("BUFF_UPDATE", Tms_ScreenShotHelper.Breathe)
RegisterEvent("CUSTOM_DATA_LOADED", Tms_ScreenShotHelper.Reload)
-----------------------------------------------
-- 快捷键绑定
-----------------------------------------------
Hotkey.AddBinding("Tms_ScreenShot_Hotkey", "截图并保存", "茗伊屏幕截图", function() Tms_ScreenShotHelper.ShotScreen(-1) end, nil)
Hotkey.AddBinding("Tms_ScreenShot_Hotkey_HideUI", "隐藏UI截图并保存", "", function() Tms_ScreenShotHelper.ShotScreen(0) end, nil)
Hotkey.AddBinding("Tms_ScreenShot_Hotkey_ShowUI", "显示UI截图并保存", "", function() Tms_ScreenShotHelper.ShotScreen(1) end, nil)
OutputMessage("MSG_SYS", "[茗伊插件]插件加载中……\n")