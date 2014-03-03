----------------------------------------------------
-- 茗伊快速登出 ver 0.1 Build 20140303
-- Code by: 翟一鸣tinymins @ ZhaiYiMing.CoM
-- 电五·双梦镇·茗伊
----------------------------------------------------
Tms_LogOff = Tms_LogOff or {}
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
local _PluginVersion = {
	dwVersion = 0x0010000,
	szBuildDate = "20140303",
}
local _LogOffCache = {
    loaded = false,
    bLogOffExRunning = false,
}
_LogOffData = {
    bTimeOutLogOff = false,
    nTimeOutUnixTime = GetCurrentTime()+3600,
    bPlayerLeaveLogOff = false,
    szPlayerLeaveNames = "",
    bClientLevelOverLogOff = false,
    nClientLevelOver = 90,
}
for k, _ in pairs(_LogOffData) do
	RegisterCustomData("_LogOffData." .. k)
end
----------------------------------------------------
-- 数据初始化
Tms_LogOff.Loaded = function()
    if(_LogOffCache.loaded) then return end
    _LogOffCache.loaded = true
    
    Player_AppendAddonMenu({function()
        return {
            Tms_LogOff.GetMenuList()
        }
    end })
end
-----------------------------------------------
-- 通用函数
-----------------------------------------------
-- (string, number) Tms_LogOff.GetVersion()		-- HM的 获取字符串版本号 修改方便拿过来了
Tms_LogOff.GetVersion = function()
	local v = _PluginVersion.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end
-- (void)Tms_LogOff.LogOff(bCompletely, bUnfight)
Tms_LogOff.LogOffEx = function(bCompletely, bUnfight)
    if not bUnfight then TMS.LogOff(bCompletely) return end
    -- 已进战，释放化蝶。
    for i,v in ipairs({"化蝶","暗尘弥散","浮光掠影"}) do
        if TMS.CanUseSkill(v) then TMS.UseSkill(v) end
    end
    OutputMessage("MSG_SYS", "[茗伊插件]脱战登出已启动，请释放脱战技能，游戏将在脱战瞬间下线。\n")
    -- 添加呼吸函数等待脱战。
    TMS.BreatheCall("LOG_OFF",function()
        if not GetClientPlayer().bFightState then
            TMS.LogOff(bCompletely)    -- 已脱战，下线。
        end
    end)
end
Tms_LogOff.ConditionLogOff = function()
    local bLogOff = false
    if _LogOffData.bTimeOutLogOff and GetCurrentTime()>_LogOffData.nTimeOutUnixTime then bLogOff = true end
    local bAllPlayerLeave = true
    if _LogOffData.bPlayerLeaveLogOff and _LogOffData.szPlayerLeaveNames~="" then
        local tNearPlayer = TMS.GetNearPlayerList()
        for i,szName in pairs(string.split(_LogOffData.szPlayerLeaveNames, ',')) do
            for _,v in pairs(tNearPlayer) do
                if v.szName == szName then bAllPlayerLeave = false end
            end
        end
    else bAllPlayerLeave = false
    end
    if _LogOffData.bClientLevelOverLogOff and GetClientPlayer().nLevel>=_LogOffData.nClientLevelOver then bLogOff=true end
    bLogOff = bLogOff or bAllPlayerLeave
    if bLogOff then TMS.LogOff(true) end
end
Tms_LogOff.ToggleConditionLogOff = function(bRunning)
    local szTip = ""
    if bRunning==nil then bRunning = not _LogOffCache.bLogOffExRunning end
    _LogOffCache.bLogOffExRunning = bRunning
    if _LogOffCache.bLogOffExRunning then
        TMS.BreatheCall("TMS_ConditionLogOff", Tms_LogOff.ConditionLogOff, 1000)
        szTip = szTip .. "----------------------------------------------\n"
        szTip = szTip .. "[茗伊插件]游戏将在符合以下条件之一时退出登录：\n"
        if _LogOffData.bTimeOutLogOff then
            local tDate = TimeToDate(_LogOffData.nTimeOutUnixTime)
            szTip = szTip .. "※当系统时间超过：" .. (string.format("%04d年%02d月%02d日 %02d:%02d:%02d (%d秒后)", tDate.year, tDate.month, tDate.day, tDate.hour, tDate.minute, tDate.second, _LogOffData.nTimeOutUnixTime-GetCurrentTime())) .. "\n"
        end
        if _LogOffData.bPlayerLeaveLogOff then
            szTip = szTip .. "※当下列玩家全部消失于视野：" .. _LogOffData.szPlayerLeaveNames .. "\n"
        end
        if _LogOffData.bClientLevelOverLogOff then
            szTip = szTip .. "※当自身等级达到" .. _LogOffData.nClientLevelOver .. "级时。\n"
        end
        szTip = szTip .. "----------------------------------------------\n"
    else
        TMS.BreatheCall("TMS_ConditionLogOff")
        szTip = szTip .. "[茗伊插件]条件登出已关闭\n"
    end
    TMS.print(szTip)
end
---------------------------------------------------
-- 创建菜单
function Tms_LogOff.GetMenuList()
	local szVersion,v  = Tms_LogOff.GetVersion()
	return
    {  -- 主菜单
        szOption = "茗伊快速登出",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_LEFT",
        { szOption = "当前版本 "..szVersion.."  ".._PluginVersion.szBuildDate,bDisable = true, },
        {  -- 符合条件下线
			szOption = "符合条件下线 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _LogOffCache.bLogOffExRunning,
			fnAction = function()
                Tms_LogOff.ToggleConditionLogOff()
			end,
			fnAutoClose = function() return true end,
            {  -- 开始
                szOption = "开始 ",
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
                bCheck = true,
                bChecked = _LogOffCache.bLogOffExRunning,
                fnAction = function()
                    Tms_LogOff.ToggleConditionLogOff()
                end,
                fnMouseEnter = function()
                    TMS.MenuTip("【条件登出】\n点击开始运行，当条件满足时自动下线。\n再次点击取消设定。")
                end,
                fnAutoClose = function() return true end
            },
            {bDevide = true},
            {  -- 指定时间后下线
                szOption = "指定时间后下线 ",
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
                bCheck = true,
                bChecked = _LogOffData.bTimeOutLogOff,
                fnAction = function()
                    if _LogOffData.bTimeOutLogOff then
                        _LogOffData.bTimeOutLogOff = false
                    else
                        -- 弹出界面
                        GetUserInputNumber(3600, 2592000, nil, function(num) _LogOffData.nTimeOutUnixTime = GetCurrentTime()+num _LogOffData.bTimeOutLogOff=true end, function() end, function() end)
                    end
                end,
                fnMouseEnter = function()
                    TMS.MenuTip("【条件登出】\n点击设定在指定秒数之后下线，如一小时后则输入3600点击确定。\n再次点击取消设定。")
                end,
                fnAutoClose = function() return true end
            },
            {  -- 指定玩家消失后下线
                szOption = "指定玩家消失后下线 ",
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
                bCheck = true,
                bChecked = _LogOffData.bPlayerLeaveLogOff,
                fnAction = function()
                    if _LogOffData.bPlayerLeaveLogOff then
                        _LogOffData.bPlayerLeaveLogOff = false
                    else
                        -- 弹出界面
                        GetUserInput("输入玩家名称，多个名称用逗号分隔。", function(nVal)
                            nVal = (string.gsub(nVal, "^%s*(.-)%s*$", "%1"))
                            nVal = (string.gsub(nVal, "，", ","))
                            _LogOffData.szPlayerLeaveNames = nVal
                            if nVal~="" then _LogOffData.bPlayerLeaveLogOff=true end
                        end, function() end, function() end, nil, _LogOffData.szPlayerLeaveNames )
                    end
                end,
                fnMouseEnter = function()
                    TMS.MenuTip("【条件登出】\n点击设定在指定玩家全部消失之后下线，多个名字之间用半角逗号分隔。\n再次点击取消设定。")
                end,
                fnAutoClose = function() return true end
            },
            {  -- 自身等级到达指定值下线
                szOption = "自身等级到达指定值下线 ",
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
                bCheck = true,
                bChecked = _LogOffData.bClientLevelOverLogOff,
                fnAction = function()
                    if _LogOffData.bClientLevelOverLogOff then
                        _LogOffData.bClientLevelOverLogOff = false
                    else
                        -- 弹出界面
                        GetUserInputNumber(90, 100, nil, function(num) _LogOffData.nClientLevelOver = num _LogOffData.bClientLevelOverLogOff=true end, function() end, function() end)
                    end
                end,
                fnMouseEnter = function()
                    TMS.MenuTip("【条件登出】\n点击设定在自身等级到达指定值之后下线，如24级则输入24点击确定。\n再次点击取消设定。")
                end,
                fnAutoClose = function() return true end
            },
		},
        {bDevide = true},
        {  -- 返回角色选择
			szOption = "返回角色选择 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
                Tms_LogOff.LogOffEx(false)
			end,
			fnMouseEnter = function()
				TMS.MenuTip("【快速登出】\n强制返回角色选择页面。")
			end,
			fnAutoClose = function() return true end
		},
        {  -- 返回用户登录
			szOption = "返回用户登录 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
                Tms_LogOff.LogOffEx(true)
			end,
			fnMouseEnter = function()
				TMS.MenuTip("【快速登出】\n强制返回账户登录页面。")
			end,
			fnAutoClose = function() return true end
		},
        {  -- 脱战后返回角色选择
			szOption = "脱战后返回角色选择 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
                Tms_LogOff.LogOffEx(false, true)
			end,
			fnMouseEnter = function()
				TMS.MenuTip("【快速登出】\n在下一次脱离战斗的一瞬间返回角色选择页面。")
			end,
			fnAutoClose = function() return true end
		},
        {  -- 脱战后返回用户登录
			szOption = "脱战后返回用户登录 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
                Tms_LogOff.LogOffEx(true, true)
			end,
			fnMouseEnter = function()
				TMS.MenuTip("【快速登出】\n在下一次脱离战斗的一瞬间返回账户登录页面。")
			end,
			fnAutoClose = function() return true end
		},
    }
end
-----------------------------------------------
-- 事件绑定
-----------------------------------------------
RegisterEvent("CUSTOM_DATA_LOADED", Tms_LogOff.Loaded)
-- RegisterEvent("BUFF_UPDATE", Tms_LogOff.Breathe)
-----------------------------------------------
-- 快捷键绑定
-----------------------------------------------
Hotkey.AddBinding("Tms_LogOff_Hotkey_RUI", "返回用户登陆页", "茗伊快速登出", function() Tms_LogOff.LogOffEx(true) end, nil)
Hotkey.AddBinding("Tms_LogOff_Hotkey_RRL", "返回角色选择页", "", function() Tms_LogOff.LogOffEx(false) end, nil)
Hotkey.AddBinding("Tms_LogOff_Hotkey_RUI_NOT_FIGHT", "脱战并返回用户登陆页", "", function() Tms_LogOff.LogOffEx(true, true) end, nil)
Hotkey.AddBinding("Tms_LogOff_Hotkey_RRL_NOT_FIGHT", "脱战并返回角色选择页", "", function() Tms_LogOff.LogOffEx(false, true) end, nil)
AppendCommand("logoff", function(szParam)
    local bCompletely, bUnfight = string.find(szParam, "角色")==nil, string.find(szParam, "脱战")~=nil
    Tms_LogOff.LogOffEx(bCompletely, bUnfight)
end)