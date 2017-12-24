

--------设置-----------
local setting = {
Enable = true,  --总开关（默认开）
WHISPER = false, --密语功能开关（默认关）
Isbapplied = false, --铁骨上身时是否报告，false：不报告，true：报告
minPurified = 30, --未出池伤害最小比例
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
local st,ss = 0,0


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

local function report(str,b)
	if b then t = GetTime() if t-T >setting.tt then T=t else return end end 
	
	SendChatMessage(str,"SAY") 

		
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
			ss=0
			if not OnAura(dstName,215479) then 
				report(dstName.."断铁骨被"..MELEE.."命中，请覆盖"..ISB,true) 
			end
		end
		if d ==115069 then 
			if not data[dstName] then  data[dstName]=CreateTable() end --建档
			data[dstName].POOL = data[dstName].POOL + g 
			ss=0
			if (not OnAura(dstName,215479)) and (not setting.whitelist[spellid]) then 
				report(dstName.."断铁骨被"..GetSpellLink(spellid).."命中，请覆盖"..ISB,true)  
			end
		end
		if a ==124255 then --醉拳吸收
			data[dstName].DOT = data[dstName].DOT + g				
		end 
	end
	if eventtype =="SPELL_PERIODIC_DAMAGE"  and spellid ==124255 then
		local k = select(4, ...) --醉拳打脸
		data[dstName].DOT = data[dstName].DOT + k
--		print(data[dstName].DOT,"dddd")
	end
	
	if ss==1 then --清空酒池报告未出池率  Gesetting.ttime()>st+0.6 and
		ss=0
		local p =(1 - data[dstName].DOT/data[dstName].POOL) --未出池伤害
		local p1 = math.floor(p*1000)/10		
		if p1<setting.minPurified then 
			report(dstName.."未出池伤害："..p1.."%,请更多使用"..PFB,false) 			
		if setting.WHISPER then  SendChatMessage("未出池伤害："..p1.."%,请更多使用"..PFB,"WHISPER",nil,dstName) end 
		--	print(data[dstName].DOT,data[dstName].POOL)
		else report(dstName.."未出池伤害："..p1.."%，打得不错！",false) 			
		end 
		if not OnAura(dstName,1022) then --无保护祝福时清零		
--			print(data[dstName].DOT,data[dstName].POOL)
			data[dstName]=CreateTable() 
		end 	
	end	
	

	--活血报告
	if eventtype == "SPELL_AURA_REMOVED" and (spellid==124273 or spellid==124274 or spellid==124275) and UnitStagger(dstName)==0 then
		st = GetTime()
		ss = 1
--		print(data[dstName].DOT,data[dstName].POOL)
		--print(UnitStagger(dstName))
	end 
	
		
 --以下仅在战斗中工作
			
	--铁骨报告
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