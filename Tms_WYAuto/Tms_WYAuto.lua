Tms_WYAuto = Tms_WYAuto or {}
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
local _WYAuto = {
	dwVersion = 0x0010000,
	szBuildDate = "20131221",
}
-----------------------------------------------
-- ……
-----------------------------------------------
_WYAutoData = {
    bAuto = true,
    bAutoFY = false,
    bAutoCY = false,
    bAutoJW = true,
    bAutoArea = false,
    bTabPvp = false,
    bAutoQKJY = false,
    bUnfocusJX = true,
    bEchoMsg = true,
    cEchoChanel = PLAYER_TALK_CHANNEL.LOCAL_SYS,
}
for k, _ in pairs(_WYAutoData) do
	RegisterCustomData("_WYAutoData." .. k)
end
local _WYAutoCache = {
    loaded = false,
}
-----------------------------------------------
-- 通用函数
-----------------------------------------------
-- (string, number) Tms_WYAuto.GetVersion()		-- HM的 获取字符串版本号 修改方便拿过来了
Tms_WYAuto.GetVersion = function()
	local v = _WYAuto.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end
-- (void) Tms_WYAuto.MenuTip(string str)	-- MenuTip
Tms_WYAuto.MenuTip = function(str)
	local szText="<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(str) .." font=207 </text>"
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(szText, 450, {x, y, w, h})
end

--(void) print(optional nChannel, szText)     -- 输出消息
local function print(nChannel,szText)
	local me = GetClientPlayer()
	if type(nChannel) == "string" then
		szText = nChannel
		nChannel = _WYAutoData.cEchoChanel or PLAYER_TALK_CHANNEL.LOCAL_SYS
	end
	local tSay = {{ type = "text", text = szText }}
	if nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	elseif nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
		OutputMessage("MSG_SYS", szText)
	else
		me.Talk(nChannel,"",tSay)
	end
end
--(void) print(optional nChannel,szText)     -- 换行输出消息
local function println(nChannel,szText)
	if type(nChannel) == "string" then
        print(nChannel .. "\n")
    else
        print(nChannel, szText .. "\n")
	end
end

-----------------------------------------------
--
-----------------------------------------------
Tms_WYAuto.tBreatheAction = {}
Tms_WYAuto.OnFrameCreate =function() end
Tms_WYAuto.Breathe=function()
	if _WYAutoData.bAuto == false then
		return
	end
	for szKey, fnAction in pairs(Tms_WYAuto.tBreatheAction) do
		assert(fnAction)
		fnAction()
	end
end
Tms_WYAuto.OnFrameBreathe=Tms_WYAuto.Breathe
----------------------------------------------------
local _SelectPoint = UserSelect.SelectPoint ---HOOK区域选中函数 改为默认直接选中----
function UserSelect.SelectPoint(fnAction, fnCancel, fnCondition, box) --获取释放点 函数
	_SelectPoint(fnAction, fnCancel, fnCondition, box) --显示区域选择
	if  _WYAutoData.bAutoArea then
		local t = GetTargetHandle(GetClientPlayer().GetTarget()) or GetClientPlayer()
		UserSelect.DoSelectPoint(t.nX, t.nY, t.nZ)
	end
end
----------------------------------------------------
--注册 Tms_WYAuto.tBreatheAction["A"]=B	A索引 B函数
--注销 Tms_WYAuto.tBreatheAction["A"]=nil
----------------------------------------------------
--无目标技能释放--
function InvalidCast(dwSkillID, dwSkillLevel)
	local player = GetClientPlayer()
	local oTTP, oTID = player.GetTarget()
    dwSkillLevel = dwSkillLevel or player.GetSkillLevel(dwSkillID)
	local bCool, nLeft, nTotal = player.GetSkillCDProgress(dwSkillID, dwSkillLevel)
	if not bCool or nLeft == 0 and nTotal == 0 then
		SetTarget(TARGET.NOT_TARGET, 0)
		OnAddOnUseSkill(dwSkillID, dwSkillLevel)
        -- println(dwSkillID,"  ",dwSkillLevel)
        OnAddOnUseSkill(dwSkillID, 1)
		if player.dwID == oTID then
			SetTarget(TARGET.PLAYER, player.dwID)
		else
			SetTarget(oTTP, oTID)
		end
	end
end
---------------------------------------------------
-- (bool)返回玩家是否拥有指定id的buff
function buff(id)
    for _,v in pairs(GetClientPlayer().GetBuffList() or {}) do
		if v.dwID == id then
      		return true
    	end
    end
    return false
end
---------------------------------------------------
-- (bool)返回玩家是否处于可挂扶摇状态
function stand()
 	local N = GetClientPlayer()
	if N then
		local state = N.nMoveState
		if state == MOVE_STATE.ON_STAND or state == MOVE_STATE.ON_FLOAT or state == MOVE_STATE.ON_FREEZE or state == MOVE_STATE.ON_ENTRAP then
			return true
		end
	end
	return false
end
---------------------------------------------------
-- (void)扶摇自动补
function AutoFY()
	if stand() and not buff(208) then
		InvalidCast(9002)
	end
end
---------------------------------------------------
-- (void)乾坤剑意自动选中
_WYAutoCache.J_NpcList = {}
_WYAutoCache.LastTarget = {
    eTargetType = TARGET.NOT_TARGET,
    dwTargetID = 1,
}

RegisterEvent("NPC_ENTER_SCENE",function()
    local player = GetClientPlayer()
    local tar = GetTargetHandle(player.GetTarget())
    if(tar and tar.szName and tar.szName ~= "乾坤剑意") then
        _WYAutoCache.LastTarget.eTargetType, _WYAutoCache.LastTarget.dwTargetID = player.GetTarget()
    end
    -- println(_WYAutoCache.LastTarget.eTargetType, _WYAutoCache.LastTarget.dwTargetID,tar.szName,"DEFAULT TAR")
    local tar = GetNpc(arg0)
    -- println("NPC_ENTER_SCENE",tar.szName)
    if tar.szName=="乾坤剑意" then
        -- println("NPC_ADDED",arg0,tar.szName)
        _WYAutoCache.J_NpcList[arg0] = tar
    end
end)
RegisterEvent("NPC_LEAVE_SCENE",function()
    -- local tar = GetNpc(arg0)
    -- println("NPC_LEAVE_SCENE",tar.szName)
    _WYAutoCache.J_NpcList[arg0] = nil
end)
function AutoQKJY()
    local player = GetClientPlayer()
    local tar = GetTargetHandle(player.GetTarget())
    for tid,ttar in pairs(_WYAutoCache.J_NpcList) do
        if(tar and tar.nCurrentLife > 0 and tar.szName == ttar.szName) then
            return
        elseif ttar and ttar.nCurrentLife > 0 then
            SetTarget(TARGET.NPC,tid)
            -- println(tid,ttar.szName,"SELECTED")
            return
        end
    end
    if(not tar) then SetTarget(_WYAutoCache.LastTarget.eTargetType, _WYAutoCache.LastTarget.dwTargetID) end
end
---------------------------------------------------
-- (void)禁止选中剑心
function AutoUnfocusJX()
    if _WYAutoData.bUnfocusJX then -- 禁止选中剑心开关打开
        local player = GetClientPlayer()
        local tar = GetTargetHandle(player.GetTarget())
        if(tar and tar.szName == "剑心") then
            player.StopCurrentAction()
            SetTarget(TARGET.PLAYER,player.dwID)
        end
    end
end
RegisterEvent("DO_SKILL_PREPARE_PROGRESS",AutoUnfocusJX) -- 技能开始读条 -- arg0=技能准备帧数 -- arg1=技能ID -- arg2=技能等级
RegisterEvent("DO_SKILL_CAST",AutoUnfocusJX) -- 技能释放 -- arg0=人物ID -- arg1=技能ID -- arg2=技能等级
RegisterEvent("PLAYER_STATE_UPDATE",AutoUnfocusJX)
RegisterEvent("SYNC_ROLE_DATA_END",AutoUnfocusJX)

---------------------------------------------------
-- (void)七秀自动剑舞
function AutoJW()
    -- 获取当前玩家装备的内功ID
	local Kungfu = UI_GetPlayerMountKungfuID() --GetClientPlayer().GetKungfuMount().dwSkillID
	if Kungfu and Kungfu ~= 10080 and Kungfu ~= 10081 then
		return
	end
	if stand() and not buff(409) then
		InvalidCast(537)
	end
end
---------------------------------------------------
-- (void)纯阳自动补减伤
function AutoCY()
    -- 获取当前玩家装备的内功ID
	local Kungfu = UI_GetPlayerMountKungfuID() --GetClientPlayer().GetKungfuMount().dwSkillID
	if Kungfu and Kungfu ~= 10015 and Kungfu ~= 10014 then
		return
	end
	if not buff(2781)  and (not buff(1376) or not buff(2983) ) then  --2781
		InvalidCast(312)
	end
	local player=GetClientPlayer()
	local n=player.nCurrentMana/player.nMaxMana
	local q=GetClientPlayer().nAccumulateValue
	if n<=0.7 and q==10 and not buff(2781) then
		InvalidCast(316)
	end
end
---------------------------------------------------
--skName    skID	buffID
--坐忘无我  312		1376 2983
--抱元守缺  316
--扶摇直上  9002	208
----------------------------------------------------

----------------------------------------------------
-- 数据初始化
Tms_WYAuto.Load = function()
    if(_WYAutoCache.loaded) then return end
    _WYAutoCache.loaded = true
    
    local tMenu = {
        function()
            return {Tms_WYAuto.GetMenuList()}
        end,
    }
    Player_AppendAddonMenu(tMenu)
    
    if _WYAutoData.bAutoFY == true then
        Tms_WYAuto.tBreatheAction["FY"]=AutoFY
    else
        Tms_WYAuto.tBreatheAction["FY"]=nil
    end
    if _WYAutoData.bAutoJW == true then
        Tms_WYAuto.tBreatheAction["JW"]=AutoJW
    else
        Tms_WYAuto.tBreatheAction["JW"]=nil
    end
    if _WYAutoData.bAutoCY == true then
        Tms_WYAuto.tBreatheAction["CY"]=AutoCY
    else
        Tms_WYAuto.tBreatheAction["CY"]=nil
    end
    if _WYAutoData.bAutoQKJY == true then
        Tms_WYAuto.tBreatheAction["QKJY"]=AutoQKJY
    else
        Tms_WYAuto.tBreatheAction["QKJY"]=nil
    end
    
    println(PLAYER_TALK_CHANNEL.LOCAL_SYS, "[手残辅助]数据加载成功，欢迎使用挽月堂手残辅助。")
end
---------------------------------------------------
-- 创建菜单
function Tms_WYAuto.GetMenuList()
	local szVersion,v  = Tms_WYAuto.GetVersion()
	local menu = {  -- 主菜单
			szOption = "挽月堂手残点这里",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_LEFT",{
				szOption = "当前版本 "..szVersion.."  ".._WYAuto.szBuildDate,bDisable = true,
			}
		}
	local menu_a_0 = {  -- 手残模式总开关
			szOption = "【手残模式总开关】 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAuto,
			fnAction = function()
                _WYAutoData.bAuto = not _WYAutoData.bAuto
                if _WYAutoData.bAuto == true then
                    println("[挽月堂手残专用]手残模式已开启")
                else
                    println("[挽月堂手残专用]手残模式已关闭")
                end
			end,
			fnMouseEnter = function()
				BuffCheck.MenuTip("【手残专用专治各种手残货】\n总开关，点击切换状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_a_1 = {  -- 发布频道
			szOption = "【发布频道】 ",
            --SYS
            {szOption = "系统频道", bMCheck = true, bChecked = _WYAutoData.cEchoChanel == PLAYER_TALK_CHANNEL.LOCAL_SYS, rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() _WYAutoData.cEchoChanel = PLAYER_TALK_CHANNEL.LOCAL_SYS end, fnAutoClose = function() return true end},
            --近聊频道
            {szOption = g_tStrings.tChannelName.MSG_NORMAL, bMCheck = true, bChecked = _WYAutoData.cEchoChanel == PLAYER_TALK_CHANNEL.NEARBY, rgb = GetMsgFontColor("MSG_NORMAL", true), fnAction = function() _WYAutoData.cEchoChanel = PLAYER_TALK_CHANNEL.NEARBY end, fnAutoClose = function() return true end},
            --团队频道
            {szOption = g_tStrings.tChannelName.MSG_TEAM, bMCheck = true, bChecked = _WYAutoData.cEchoChanel == PLAYER_TALK_CHANNEL.RAID, rgb = GetMsgFontColor("MSG_TEAM", true), fnAction = function() _WYAutoData.cEchoChanel = PLAYER_TALK_CHANNEL.RAID end, fnAutoClose = function() return true end},
            --帮会频道
            {szOption = g_tStrings.tChannelName.MSG_GUILD, bMCheck = true, bChecked = _WYAutoData.cEchoChanel == PLAYER_TALK_CHANNEL.TONG, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.cEchoChanel = PLAYER_TALK_CHANNEL.TONG end, fnAutoClose = function() return true end},
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bEchoMsg,
			fnAction = function()
                _WYAutoData.bEchoMsg = not _WYAutoData.bEchoMsg
                if _WYAutoData.bEchoMsg == true then
                    println("[挽月堂手残专用]设置发布已开启")
                else
                    println("[挽月堂手残专用]设置发布已关闭")
                end
			end,
			-- fnMouseEnter = function()
				-- BuffCheck.MenuTip("【手残专用专治各种手残货】\n总开关，点击切换状态。")
			-- end,
			fnAutoClose = function() return true end,
		}
	local menu_b_1 = {  -- 自动补扶摇
			szOption = "自动补扶摇 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAutoFY,
			fnAction = function()
                _WYAutoData.bAutoFY = not _WYAutoData.bAutoFY
                if _WYAutoData.bAutoFY == true then
                    Tms_WYAuto.tBreatheAction["FY"]=AutoFY
                    println("[挽月堂手残专用]自动补扶摇已开启")
                else
                    Tms_WYAuto.tBreatheAction["FY"]=nil
                    println("[挽月堂手残专用]自动补扶摇已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n扶摇好了就补，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_2 = {  -- 自动剑舞
			szOption = "自动剑舞 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAutoJW,
			fnAction = function()
                _WYAutoData.bAutoJW = not _WYAutoData.bAutoJW
                if _WYAutoData.bAutoJW == true then
                    Tms_WYAuto.tBreatheAction["JW"]=AutoJW
                    println("[挽月堂手残专用]自动剑舞已开启")
                else
                    Tms_WYAuto.tBreatheAction["JW"]=nil
                    println("[挽月堂手残专用]自动剑舞已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n自动剑舞，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_3 = {  -- 自动纯阳补减伤
			szOption = "自动纯阳补减伤 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAutoCY,
			fnAction = function()
                _WYAutoData.bAutoCY = not _WYAutoData.bAutoCY
                if _WYAutoData.bAutoCY == true then
                    Tms_WYAuto.tBreatheAction["CY"]=AutoCY
                    println("[挽月堂手残专用]纯阳自动补减伤已开启")
                else
                    Tms_WYAuto.tBreatheAction["CY"]=nil
                    println("[挽月堂手残专用]纯阳自动补减伤已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n纯阳坐忘经吐故抱元自动补，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_4 = {  -- 自动选中乾坤剑意
			szOption = "自动选中乾坤剑意 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAutoQKJY,
			fnAction = function()
                _WYAutoData.bAutoQKJY = not _WYAutoData.bAutoQKJY
                if _WYAutoData.bAutoQKJY == true then
                    Tms_WYAuto.tBreatheAction["QKJY"]=AutoQKJY
                    println("[挽月堂手残专用]自动选中乾坤剑意已开启")
                else
                    Tms_WYAuto.tBreatheAction["QKJY"]=nil
                    println("[挽月堂手残专用]自动选中乾坤剑意已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n自动选中乾坤剑意，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_5 = {  -- 禁止选中剑心
			szOption = "禁止选中剑心 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bUnfocusJX,
			fnAction = function()
                _WYAutoData.bUnfocusJX = not _WYAutoData.bUnfocusJX
                if _WYAutoData.bUnfocusJX == true then
                    println("[挽月堂手残专用]禁止选中剑心已开启")
                else
                    println("[挽月堂手残专用]禁止选中剑心已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n禁止选中剑心防止误伤，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_6 = {  -- 范围技能辅助
			szOption = "范围技能辅助 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAutoArea,
			fnAction = function()
                _WYAutoData.bAutoArea = not _WYAutoData.bAutoArea
                if _WYAutoData.bAutoArea==true then
                    println("[挽月堂手残专用]范围技能辅助已开启")
                else
                    println("[挽月堂手残专用]范围技能辅助已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n范围技能无目标向自己释放，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_7 = {  -- 只Tab玩家
			szOption = "只Tab玩家 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bTabPvp,
			fnAction = function()
                _WYAutoData.bTabPvp = not _WYAutoData.bTabPvp
                if _WYAutoData.bTabPvp == true then
                    println("[挽月堂手残专用]只Tab玩家已开启")
                else
                    println("[挽月堂手残专用]只Tab玩家已关闭")
                end
                --true限制搜索玩家 --pvp
                SearchTarget_SetOtherSettting("OnlyPlayer",_WYAutoData.bTabPvp, "Enmey")
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n只Tab玩家，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_c_1 = {  -- 退回角色列表
			szOption = "退回角色列表 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
                ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("返回角色选择页。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_c_2 = {  -- 退回登录界面
			szOption = "退回登录界面 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
			bCheck = false,
			bChecked = false,
			fnAction = function()
                ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("返回账号登录页。")
			end,
			fnAutoClose = function() return true end
		}
	--table.insert(menu_0_0, menu_0_0_0)
    -- table.insert(menu_0, menu_0_0)
    table.insert(menu, menu_a_0)
    table.insert(menu, menu_a_1)
	table.insert(menu, {bDevide = true})
	-- table.insert(menu, menu_b_1)
	table.insert(menu, menu_b_2)
	-- table.insert(menu, menu_b_3)
	table.insert(menu, menu_b_4)
	table.insert(menu, menu_b_5)
	table.insert(menu, menu_b_6)
	table.insert(menu, menu_b_7)
	table.insert(menu, {bDevide = true})
	table.insert(menu, menu_c_1)
	table.insert(menu, menu_c_2)
	return menu
end

---------------------------------------------------
-- 事件注册
-- RegisterEvent("LOGIN_GAME", function()
	-- local tMenu = {
		-- function()
			-- return {Tms_WYAuto.GetMenuList()}
		-- end,
	-- }
	-- Player_AppendAddonMenu(tMenu)
-- end)
RegisterEvent("CUSTOM_DATA_LOADED", Tms_WYAuto.Load)
-- RegisterEvent("BUFF_UPDATE", Tms_WYAuto.Breathe)
println(PLAYER_TALK_CHANNEL.LOCAL_SYS, "[手残辅助]插件加载中……")

---------------------------------------------------
--这一条语句最好放在lua文件的末尾，也就是你定义的函数的后面
Wnd.OpenWindow("Interface/Tms_WYAuto/Tms_WYAuto.ini","Tms_WYAuto")
--第一个参数是窗体文件路径，第二个参数是窗体名，也就是WYAuto.ini的第一行那个名字。
---------------------------------------------------