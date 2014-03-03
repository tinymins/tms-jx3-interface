Tms_WYAuto = Tms_WYAuto or {}
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
local _WYAuto = {
	dwVersion = 0x0020000,
	szBuildDate = "20140129",
}
-----------------------------------------------
-- ……
-----------------------------------------------
_WYAutoData = {
    bAuto = true,
    bAutoJW = true,
    bAutoArea = false,
    bTabPvp = false,
    bAutoQKJY = false,  -- 乾坤剑意自动选中开关
    bAutoWDLD = false,  -- 屋顶漏洞自动选中开关
    bUnfocusJX = true,  -- 禁止选中剑心开关
    bEchoMsg = true,    -- 消息发布总开关
    cEchoChanel = PLAYER_TALK_CHANNEL.LOCAL_SYS,    -- 消息发布频道
    bTargetLock = true, -- 目标锁定开关
    nTargetLockMode = 0, -- 目标锁定模式： 0 自动转火 1 锁定附近敌对NPC 2 自定义锁定
    nTargetLockNearNpcDistance = 20,    -- 锁定附近敌对NPC最大距离
    nTargetLockNearNpcSortMode = 0,     -- 距离最近/等级最低/未进战的/已进战的/在揍我的/揍别人的/血量最少/血量百分比最少
}
for k, _ in pairs(_WYAutoData) do
	RegisterCustomData("_WYAutoData." .. k)
end
_WYAutoCache = {
    loaded = false,
}
----------------------------------------------------
-- 数据初始化
Tms_WYAuto.Loaded = function()
    if(_WYAutoCache.loaded) then return end
    _WYAutoCache.loaded = true
    
    local tMenu = {
        function()
            return {Tms_WYAuto.GetMenuList()}
        end,
    }
    Player_AppendAddonMenu(tMenu)
    Tms_WYAuto.Reload()
    
    -- println(PLAYER_TALK_CHANNEL.LOCAL_SYS, "[手残辅助]数据加载成功，欢迎使用挽月堂手残辅助。")
    OutputMessage("MSG_SYS", "[手残辅助]数据加载成功，欢迎使用挽月堂手残辅助。\n")
end
Tms_WYAuto.Reload = function()
    Tms_WYAuto.tBreatheAction["JW"]=nil
    Tms_WYAuto.tBreatheAction["QKJY"]=nil
    Tms_WYAuto.tBreatheAction["LockNearNpc"]=nil
    if not _WYAutoData.bAuto then return end
    if _WYAutoData.bAutoJW == true then Tms_WYAuto.tBreatheAction["JW"]=AutoJW end
    if _WYAutoData.bTargetLock then 
        if _WYAutoData.nTargetLockMode == 0 then 
            if _WYAutoData.bAutoQKJY == true then
                Tms_WYAuto.tBreatheAction["QKJY"] = AutoQKJY
            end
        elseif _WYAutoData.nTargetLockMode == 1 then 
            Tms_WYAuto.tBreatheAction["LockNearNpc"] = AutoSelectNearTarget
        elseif _WYAutoData.nTargetLockMode == 2 then 
            return
        end
    end
end
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
    end
	if nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
		OutputMessage("MSG_SYS", szText)
	elseif _WYAutoData.bEchoMsg then
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
        -- println(szKey)
		-- assert(fnAction)
		if type(fnAction) == "function" then fnAction() end
	end
end
Tms_WYAuto.OnFrameBreathe=Tms_WYAuto.Breathe
----------------------------------------------------
local _SelectPoint = UserSelect.SelectPoint ---HOOK区域选中函数 改为默认直接选中----
function UserSelect.SelectPoint(fnAction, fnCancel, fnCondition, box) --获取释放点 函数
	_SelectPoint(fnAction, fnCancel, fnCondition, box) --显示区域选择
	if _WYAutoData.bAuto and _WYAutoData.bAutoArea then -- 开关打开
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
        -- OnAddOnUseSkill(dwSkillID, 1)
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
-- (void)禁止选中剑心
function AutoUnfocusJX()
    if _WYAutoData.bAuto and _WYAutoData.bUnfocusJX then -- 禁止选中剑心开关打开
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
-- 目标锁定 事件绑定
_WYAutoCache.J_NpcList = {}
_WYAutoCache.NearEnemyNpcList = {}
_WYAutoCache.LastTarget = {
    eTargetType = TARGET.NOT_TARGET,
    dwTargetID = 1,
}

RegisterEvent("NPC_ENTER_SCENE",function()
    local player = GetClientPlayer()
    -- local tar = GetTargetHandle(player.GetTarget())
    -- println(_WYAutoCache.LastTarget.eTargetType, _WYAutoCache.LastTarget.dwTargetID,tar.szName,"DEFAULT TAR")
    local tar = GetNpc(arg0)
    -- println("NPC_ENTER_SCENE".."\t"..tar.szName)
    if tar.szName=="乾坤剑意" then
        -- println("NPC_ADDED",arg0,tar.szName)
        _WYAutoCache.J_NpcList[arg0] = tar
    end
    -- println("dwID"..player.dwID.." "..tar.szName.." "..arg0)
    -- if IsEnemy(player.dwID, tar.dwID) then println("Enemy") else println("Friend") end
    -- if tar.szName ~= "剑心" then println("~=剑心") else println("=剑心") end
    if IsEnemy(player.dwID, tar.dwID) and tar.szName ~= "剑心" and tar.szName ~= "训练木桩" then _WYAutoCache.NearEnemyNpcList[arg0] = tar end
end)
RegisterEvent("NPC_LEAVE_SCENE",function()
    -- local tar = GetNpc(arg0)
    -- println("NPC_LEAVE_SCENE",tar.szName)
    _WYAutoCache.J_NpcList[arg0] = nil
    _WYAutoCache.NearEnemyNpcList[arg0] = nil
end)

---------------------------------------------------
-- (void)乾坤剑意自动选中
function AutoQKJY()
    local player = GetClientPlayer()
    local tar = GetTargetHandle( player.GetTarget() )
    for tid,ttar in pairs(_WYAutoCache.J_NpcList) do
        if(tar and tar.nCurrentLife > 0 and tar.szName == ttar.szName) then
            return
        elseif ttar and ttar.nCurrentLife > 0 then
            if ( tar and tar.szName ) then
                _WYAutoCache.LastTarget.eTargetType, _WYAutoCache.LastTarget.dwTargetID = player.GetTarget()
            end
            SetTarget(TARGET.NPC,tid)
            -- println(tid,ttar.szName,"SELECTED")
            return
        end
    end
    if(not tar) then SetTarget(_WYAutoCache.LastTarget.eTargetType, _WYAutoCache.LastTarget.dwTargetID) end
end
---------------------------------------------------
-- (void)自动选中指定范围内敌对NPC
function AutoSelectNearTarget()
    local player = GetClientPlayer()
    if _WYAutoData.bTargetLock and _WYAutoData.nTargetLockMode == 1 then 
        local dwNpcID = 0            -- 记录 距离最近/等级最低/未进战的/已进战的/在揍我的/血量最少/血量百分比最少 的NPC的ID
        local nLowestNpcPropertiesValue = 9999 -- 参考量的最小值
        local dwNearestNpcID = 0
        local nNearestDistance = 9999
        for npcid,npc in pairs(_WYAutoCache.NearEnemyNpcList) do
            -- println(""..npcid.." "..npc.dwID)
            local switch = {
                [0] = function(player,npc)    -- 距离最近
                    return GetCharacterDistance(player.dwID, npc.dwID)
                end,
                [1] = function(player,npc)    -- 等级最低
                    return npc.nLevel
                end,
                [2] = function(player,npc)    -- 未进战的
                    if npc.bFightState then return -1 else return -2 end
                end,
                [3] = function(player,npc)    -- 已进战的
                    if npc.bFightState then return -2 else return -1 end
                end,
                [4] = function(player,npc)    -- 在揍我的
                    if npc.bFightState and npc.GetTarget() and npc.GetTarget().dwID == player.dwID then return -2 else return -1 end
                end,
                [5] = function(player,npc)    -- 揍别人的
                    if npc.bFightState and npc.GetTarget() and npc.GetTarget().dwID ~= player.dwID then return -2 else return -1 end
                end,
                [6] = function(player,npc)    -- 血量最少
                    return npc.nCurrentLife
                end,
                [7] = function(player,npc)    -- 血量百分比最少
                    return npc.nCurrentLife*100/npc.nMaxLife
                end,
            }
            local f = switch[_WYAutoData.nTargetLockNearNpcSortMode]
            if(f) then
                local nNpcPropertiesValue = f(player,npc)
                local nDistance = GetCharacterDistance(player.dwID, npc.dwID)
                if (npc and nDistance/64 < _WYAutoData.nTargetLockNearNpcDistance and (npc.nCurrentLife > 0 and nNpcPropertiesValue < nLowestNpcPropertiesValue) ) then
                    nLowestNpcPropertiesValue = nNpcPropertiesValue
                    dwNpcID = npcid
                end
                if dwNearestNpcID == 0 or nDistance < nNearestDistance and nDistance/64 < _WYAutoData.nTargetLockNearNpcDistance then
                    nNearestDistance = nDistance
                    dwNearestNpcID = npcid
                end
            -- else                -- for case default
                -- print "Case default."
            end
        end
        -- 选中符合要求的最佳目标 没有则选中最近的目标
        if dwNpcID ~= 0 and nLowestNpcPropertiesValue ~= -1 then SetTarget(TARGET.NPC,dwNpcID) else SetTarget(TARGET.NPC,dwNearestNpcID) end
    end
end

---------------------------------------------------
-- (void)七秀自动剑舞
function AutoJW()
    -- 获取当前玩家装备的内功ID
	-- local Kungfu = UI_GetPlayerMountKungfuID() --GetClientPlayer().GetKungfuMount().dwSkillID
	-- if Kungfu and Kungfu ~= 10080 and Kungfu ~= 10081 then
		-- return
	-- end
	local me = GetClientPlayer()
	if not me or not me.GetKungfuMount() or me.GetOTActionState() ~= 0 then
		return
	end
	-- 7x
	if me.GetKungfuMount().dwMountType == 4 then
		-- auto dance
        if stand() and not buff(409) then
            InvalidCast(537)
        end
    end
end
----------------------------------------------------

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
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n总开关，点击切换状态。")
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
				-- Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n总开关，点击切换状态。")
			-- end,
			fnAutoClose = function() return true end,
		}
	local menu_b_1 = {  -- 目标锁定/增强
        szOption = "目标锁定/增强 ",
        szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT", 
        bCheck = true,
        bChecked = _WYAutoData.bTargetLock,
        fnAction = function()
            _WYAutoData.bTargetLock = not _WYAutoData.bTargetLock
            if _WYAutoData.bTargetLock == true then
                println("[挽月堂手残专用]目标锁定/增强已开启")
            else
                println("[挽月堂手残专用]目标锁定/增强已关闭")
            end
        end,
        fnAutoClose = function() return true end,
        {  -- 自动转火
            szOption = "自动转火 ",
            szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
            bMCheck = true,
            bCheck = true,
            bChecked = _WYAutoData.nTargetLockMode == 0,
            fnAction = function()
                _WYAutoData.nTargetLockMode = 0
                println("[挽月堂手残专用]目标锁定/增强·模式切换·自动转火")
                if _WYAutoData.bAutoQKJY then println("[挽月堂手残专用]目标锁定/增强·当前模式·自动转火乾坤剑意") end
                Tms_WYAuto.Reload()
            end,
            fnAutoClose = function() return true end,
            {  -- 自动选中乾坤剑意
                szOption = "自动选中乾坤剑意 ",
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
                bCheck = true,
                bChecked = _WYAutoData.bAutoQKJY,
                fnAction = function()
                    _WYAutoData.bAutoQKJY = not _WYAutoData.bAutoQKJY
                    Tms_WYAuto.Reload()
                    if _WYAutoData.bAutoQKJY == true then
                        println("[挽月堂手残专用]目标锁定/增强·自动选中乾坤剑意已开启")
                    else
                        println("[挽月堂手残专用]目标锁定/增强·自动选中乾坤剑意已关闭")
                    end
                end,
                fnMouseEnter = function()
                    Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n自动选中乾坤剑意，点击切换启用/禁用状态。")
                end,
                fnAutoClose = function() return true end
            },
            
        }, 
        {  -- 锁定附近敌对NPC
            szOption = "锁定附近敌对NPC ",
            szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
            bMCheck = true,
            bCheck = true,
            bChecked = _WYAutoData.nTargetLockMode == 1,
            fnAction = function()
                _WYAutoData.nTargetLockMode = 1
                println("[挽月堂手残专用]目标锁定/增强·模式切换·锁定附近敌对NPC")
                Tms_WYAuto.Reload()
            end,
            fnAutoClose = function() return true end,
            {  -- 设置最大距离
                szOption = "设置最大锁定距离 ",
                bCheck = false,
                bChecked = false,
                fnAction = function()
                    -- 弹出界面
                    GetUserInputNumber(_WYAutoData.nTargetLockNearNpcDistance, 100, nil, function(num) _WYAutoData.nTargetLockNearNpcDistance = num end, function() end, function() end)
                end,
                fnMouseEnter = function()
                    Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n设置最大距离。")
                end,
                fnAutoClose = function() return true end
            },
            { bDevide = true }, 
            {  -- 优先选中
                szOption = "优先选中： ",
                fnAutoClose = function() return true end,
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
                -- 距离最近
                {szOption = "距离最近", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 0, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 0 end, fnAutoClose = function() return true end},
                -- 等级最低
                {szOption = "等级最低", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 1, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 1 end, fnAutoClose = function() return true end},
                -- 未进战的
                {szOption = "未进战的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 2, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 2 end, fnAutoClose = function() return true end},
                -- 已进战的
                {szOption = "已进战的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 3, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 3 end, fnAutoClose = function() return true end},
                -- 在揍我的
                {szOption = "在揍我的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 4, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 4 end, fnAutoClose = function() return true end},
                -- 揍别人的
                {szOption = "揍别人的", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 5, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 5 end, fnAutoClose = function() return true end},
                -- 血量最少
                {szOption = "血量最少", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 6, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 6 end, fnAutoClose = function() return true end},
                -- 血量百分比最少
                {szOption = "血量百分比最少", bMCheck = true, bChecked = _WYAutoData.nTargetLockNearNpcSortMode == 7, rgb = GetMsgFontColor("MSG_GUILD", true), fnAction = function() _WYAutoData.nTargetLockNearNpcSortMode = 7 end, fnAutoClose = function() return true end},
            },
        }, 
        {  -- 自定义目标锁定
            szOption = "自定义目标锁定 ",
            szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_RIGHT",
            bMCheck = true,
            bCheck = true,
            bChecked = _WYAutoData.nTargetLockMode == 2,
            fnAction = function()
                _WYAutoData.nTargetLockMode = 2
                println("[挽月堂手残专用]目标锁定/增强·模式切换·自定义目标锁定")
                Tms_WYAuto.Reload()
            end,
            fnAutoClose = function() return true end,
            {  -- 条件编辑器
                szOption = "条件编辑器 ",
                szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
                bCheck = false,
                bChecked = false,
                fnAction = function()
                    -- 弹出界面
                end,
                fnMouseEnter = function()
                    Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n自定义目标锁定条件编辑器。")
                end,
                fnAutoClose = function() return true end
            },
        }, 
        { bDevide = true }, 
        {  -- 禁止选中剑心
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
        },
    }
	local menu_b_2 = {  -- 自动剑舞
			szOption = "自动剑舞 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = true,
			bChecked = _WYAutoData.bAutoJW,
			fnAction = function()
                _WYAutoData.bAutoJW = not _WYAutoData.bAutoJW
                Tms_WYAuto.Reload()
                if _WYAutoData.bAutoJW == true then
                    println("[挽月堂手残专用]自动剑舞已开启")
                else
                    println("[挽月堂手残专用]自动剑舞已关闭")
                end
			end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n自动剑舞，点击切换启用/禁用状态。")
			end,
			fnAutoClose = function() return true end
		}
	local menu_b_3 = {  -- 范围技能辅助
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
	local menu_b_4 = {  -- 只Tab玩家
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
	local menu_b_5 = {  -- 其它
			szOption = "其它 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = false,
			fnAction = function() end,
			fnAutoClose = function() return true end,
            {  -- 修剪附近的羊毛
			szOption = "修剪附近的羊毛 ",
			szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=49;szLayer = "ICON_RIGHT",
			bCheck = false,
			fnAction = function() 
                for tid,tar in pairs(tTMS.NearPlayerList) do
                    if tar and tar.dwSchoolID == 2 then
                        local tSay = {
                            {type = "name", name = GetClientPlayer().szName},
                            {type = "text", text = "麻利的拔光了"},
                            {type = "name", name = tar.szName},
                            {type = "text", text = "的羊毛。"},
                        }
                        GetClientPlayer().Talk( _WYAutoData.cEchoChanel or PLAYER_TALK_CHANNEL.NEARBY, "", tSay)
                        -- print(PLAYER_TALK_CHANNEL.NEARBY, "[" .. GetClientPlayer().szName .. "]麻利的拔光了[" .. tar.szName .. "]的羊毛。")
                    end
                end
                local tSay = {
                    {type = "name", name = GetClientPlayer().szName},
                    {type = "text", text = "收拾了一下背包里的羊毛，希望今年能卖个好价钱。"},
                }
                GetClientPlayer().Talk( _WYAutoData.cEchoChanel or PLAYER_TALK_CHANNEL.NEARBY, "", tSay)
            end,
			fnMouseEnter = function()
				Tms_WYAuto.MenuTip("【手残专用专治各种手残货】\n修剪一下附近所有的蠢羊。")
			end,
			fnAutoClose = function() return true end
		}
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
	table.insert(menu, menu_b_1)
	table.insert(menu, menu_b_2)
	table.insert(menu, menu_b_3)
	table.insert(menu, menu_b_4)
	table.insert(menu, menu_b_5)
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
RegisterEvent("CUSTOM_DATA_LOADED", Tms_WYAuto.Loaded)
-- RegisterEvent("BUFF_UPDATE", Tms_WYAuto.Breathe)
RegisterEvent("CUSTOM_DATA_LOADED", Tms_WYAuto.Reload)
println(PLAYER_TALK_CHANNEL.LOCAL_SYS, "[手残辅助]插件加载中……")

---------------------------------------------------
--这一条语句最好放在lua文件的末尾，也就是你定义的函数的后面
Wnd.OpenWindow("Interface/Tms_WYAuto/Tms_WYAuto.ini","Tms_WYAuto")
--第一个参数是窗体文件路径，第二个参数是窗体名，也就是WYAuto.ini的第一行那个名字。
---------------------------------------------------