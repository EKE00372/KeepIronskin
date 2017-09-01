--------设置-----------
local tt = 2  --喊话最小间隔，默认2秒

local whitelist = { --白名单，受到这些伤害时不会报告
[209858]=true, --死疽
[124255]=true, --醉拳
}
--------core-----------
local T,t = 0,0
local ISB = GetSpellLink(215479)
local data = {}

local function CreateTable()
	t = {
	["DOT"] = 0,
	["POOL"] = 0,
	}
	return t
end 


local function OnIronskin(dstName)
	for i=1,40 do
		local buffid = select(11,UnitBuff(dstName,i))
		if buffid == 215479 then return 1 end 
	end
	return nil
end

local function report(str,b)
	if b then t = GetTime() if t-T >tt then T=t else return end end 
	
	SendChatMessage(str,"SAY") 
		
end

local function keep(self,event,timestamp,eventtype,hideCaster,srcGUID, srcName, srcFlags,srcRFlags,dstGUID,dstName, dstFlags,dstRFlags,...)	
	--if UnitPosition("player") then return end --仅在副本中工作
	--if GetInspectSpecialization(dstName)~=268 then return end --仅目标为酒仙时工作
	if not InCombatLockdown() then return end --仅在战斗中工作
	
	local spellid = select(1, ...)
	
		if eventtype == "SWING_DAMAGE" and (not OnIronskin(dstName)) then 
			report(dstName.."断铁骨被平砍命中，请覆盖"..ISB,true) 
		end
		if eventtype == "SPELL_DAMAGE" and (not OnIronskin(dstName)) and (not whitelist[spellid])then 
			report(dstName.."断铁骨被"..GetSpellLink(spellid).."命中，请覆盖"..ISB,true) 
		end
		if eventtype == "SPELL_PERIODIC_DAMAGE" and (not OnIronskin(dstName)) and (not whitelist[spellid]) then 
			report(dstName.."断铁骨被"..GetSpellLink(spellid).."命中，请覆盖"..ISB,true) 
		end
		if eventtype == "SPELL_AURA_REMOVED" and spellid==215479  then 
			report(dstName.."已经失去"..ISB.."，治疗注意！",false) 
		end		
		if eventtype == "SPELL_ABSORBED"  then 
			local a,b,c,d,e,f,g = select(5, ...)
			if a ==115069 then print(a,d) end
			if d ==115069 then print(d,g) end
		end 
end

KeepIronskin = CreateFrame("frame") 
KeepIronskin:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
KeepIronskin:SetScript("OnEvent",keep) 

