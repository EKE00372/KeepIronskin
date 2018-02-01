

--------设置-----------
local setting = {
Enable = true,  --总开关（默认开）
WHISPER = false, --密语功能开关（默认关）
Isbapplied = false, --铁骨上身时是否报告，false：不报告，true：报告
MaxStaggerTaken = 80, --醉拳DOT的最大跳出比例 
Purified = true,  --是否报告活血使用恰当，如果脱战时跳出比例低于最大比例-10%，则报告“打得不错”
whitelist = { --白名单，受到这些伤害时不会报告
	[209858]=true, --死疽
	[124255]=true, --醉拳
	},
tt = 2,
}

--------core-----------
local T,t = 0,0
local ISB = GetSpellLink(215479) --铁骨酒LINK
local MELEE = GetSpellLink(6603) --平砍LINK
local PFB = GetSpellLink(119582) --活血酒LINK
local data = {} --酒池数据


local function CreateTable() --建档
	t = {
	["DOT"] = 0,
	["POOL"] = 0,
	}
	return t
end 


local function OnAura(dstName,id)
	local spellname = GetSpellInfo(id)
	if UnitAura(dstName,spellname) then return 1 end 	
	return nil
end

local function report(str,b,ID)
	if b then t = GetTime() if t-T >setting.tt then T=t else return end end 
	
	SendChatMessage(str,"SAY") 
	if setting.WHISPER then SendChatMessage(str,"WHISPER",nil,ID) end 
		
end

local function keep(self,event,timestamp,eventtype,hideCaster,srcGUID, srcName, srcFlags,srcRFlags,dstGUID,dstName, dstFlags,dstRFlags,...)	
	local spellid = select(1,...)
	if not setting.Enable then return end --总开关
	if UnitPosition("player") then return end --仅在副本中工作
		
	
	--断铁骨报告，酒池状态
	if eventtype == "SPELL_ABSORBED"  then --醉拳池更新
		local a,b,c,d,e,f,g = select(5, ...)
		if a ==115069 then
			if not data[dstName] then  data[dstName]=CreateTable() end --建档
			data[dstName].POOL = data[dstName].POOL + d 
			if not OnAura(dstName,215479) then 
				report(dstName.."断铁骨被"..MELEE.."命中，请覆盖"..ISB,true,dstName) 
			end
		end
		if d ==115069 then 
			if not data[dstName] then  data[dstName]=CreateTable() end --建档
			data[dstName].POOL = data[dstName].POOL + g 
			if (not OnAura(dstName,215479)) and (not setting.whitelist[spellid]) then 
				report(dstName.."断铁骨被"..GetSpellLink(spellid).."命中，请覆盖"..ISB,true,dstName)  
			end
		end
		
		--醉拳DOT被吸收
		local s = select(1,...)
		local dot = select(11,...)
		if s ==124255 then 
			data[dstName].DOT = data[dstName].DOT + dot		
		--	print(data[dstName].DOT,data[dstName].POOL)			
		end 
	end
	
	if eventtype =="SPELL_PERIODIC_DAMAGE"  and spellid ==124255 then	--醉拳打脸
		local k = select(4, ...) --打脸
		local p =0
		data[dstName].DOT = data[dstName].DOT + k
		
		p = data[dstName].DOT/data[dstName].POOL
		
		--print(data[dstName].DOT,data[dstName].POOL)
		if  p > setting.MaxStaggerTaken/100 and k>200000 then 		--醉拳承受过高
			p=math.floor(p*1000)/10
			report(dstName.." 的醉拳DOT承受："..p.."%，请更多使用"..PFB,true,dstName) 			
		end 
	end
	if data[dstName] then 
	if UnitStagger(dstName)==0 and data[dstName].POOL ~= 0 and not InCombatLockdown() then	--酒池脱战清零
		p = data[dstName].DOT/data[dstName].POOL
		
		if  0< p < (setting.MaxStaggerTaken-10)/100 and setting.Purified then  --醉拳消除不错
			p=math.floor(p*1000)/10
			report(dstName.." 本次战斗醉拳DOT承受："..p.."%，打得不错！",false) 			
		end 
		data[dstName]=CreateTable() 
	end
	end 
	
				
	--铁骨报告，仅在战斗中工作
	if eventtype == "SPELL_AURA_REMOVED" and spellid==215479 and InCombatLockdown()  then 
		report(dstName.."已经失去"..ISB.."，治疗注意！",false) 
	end	
	if eventtype == "SPELL_AURA_APPLIED" and spellid==215479 and setting.Isbapplied  and InCombatLockdown() then 
		report(dstName.."已经获得"..ISB.."，稳如POI！",false) 
	end			
	
		
		
end

KeepIronskin = CreateFrame("frame") 
KeepIronskin:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
KeepIronskin:SetScript("OnEvent",keep) 


SLASH_KeepIronskin1 = "/kpis"
SlashCmdList["KeepIronskin"] = function () if setting.Enable then setting.Enable = false print("KeepIronskin已经关闭") else setting.Enable = true print("KeepIronskin已经开启") end end 