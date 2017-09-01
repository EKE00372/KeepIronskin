
function SR_start()
--初始化
        for key,value in pairs(SR_data) do  
			SR_data[key] = 0
		end
		SR_data.boss = nil
end
SR_num=1
function SR_end()
--存储
	if nil then SR_print(SR_data) end
	SR_SavedReport[SR_num] = {}
	for key,value in pairs(SR_data) do  
		SR_SavedReport[SR_num][key]=value
	end
	SR_num = SR_num+1

end

SR_data = {
boss = nil,
PreStaggered = 0, --醉前伤害
Staggered = 0, --总池
Purified = 0, --活血掉的伤害
QuickPurified = 0, --快喝铁骨活血掉的伤害
DOT = 0, --跳出来的醉拳dot伤害
StaggerPool = 0 --实时醉拳池
}

SR_SavedReport = {  --存储记录

} 

function GetPurifyPercent()
	for i = 40,70 do
		if GetSpellDescription(119582):find(i) then
		PurifyPercent = string.sub(GetSpellDescription(119582), GetSpellDescription(119582):find(i))
	end
	end
	return PurifyPercent/100
end

function SR_print(tab)
  local PS = tab.PreStaggered
  local Sg = tab.Staggered
  local Pd = tab.Purified
  local QP = tab.QuickPurified
  local DOT = tab.DOT
      
  local PurifiedPer = Pd/Sg --活血率
  local QuickPurifiedPer = QP/Sg --快喝活血率
  local KickFace = PS-Sg --打脸
  local Taken = PS-Sg+DOT --总承受
  local belt = Pd/4*(1 + GetCritChance()/100*0.65) --腰带预期治疗
  local Pper = (Pd+QP)/PS --活血等效
  local beltper = Pd/4*(1 + GetCritChance()/100*0.65)/(PS-Pd-QP) --腰带等效减伤
  

  print("战斗：",tab.boss)
  print("醉前伤害：",SR_Numformat(PS),"    总池：",SR_Numformat(Sg))
  print("总承受：",SR_Numformat(Taken),"     打脸：",SR_Numformat(KickFace),"    醉拳DOT",SR_Numformat(DOT))
  print("活血",SR_Numformat(Pd).."("..SR_Numformat(PurifiedPer)..")","    快喝",SR_Numformat(QP).."("..SR_Numformat(QuickPurifiedPer)..")")
  print("醉等：",SR_Numformat(Pper),"    腰治",SR_Numformat(belt),"    腰等",SR_Numformat(beltper))
  

 -- print("误差：",(Pd+QP+DOT+SR_data.StaggerPool)/Sg)
 end
 



function SR_update(self,event,...)
	local eventtype = select(2, ...)
	local sourceGUID = select(4, ...)
	local sourceName = select(5, ...)
	local destName = select(9, ...)
	local spellid = select(12, ...)
	if eventtype == "SPELL_ABSORBED" and destName ==UnitName("player") then --更新总醉拳池
		local a,b,c,d,e,f,g = select(16, ...)
		
		if a ==115069 then SR_data.Staggered = SR_data.Staggered + d SR_data.StaggerPool = SR_data.StaggerPool + d end
		if d ==115069 then SR_data.Staggered = SR_data.Staggered + g SR_data.StaggerPool = SR_data.StaggerPool + g end
		
	end 
    if eventtype =="SWING_DAMAGE"  and destName ==UnitName("player")then
		if SR_data.boss == nil then SR_data.boss = sourceName end
		local k = select(12, ...) --平砍打脸
		local a = select(17, ...) --平砍吸收
		SR_data.PreStaggered = SR_data.PreStaggered + k + a 
	end
	if eventtype =="SPELL_DAMAGE"  and destName ==UnitName("player")then
		if SR_data.boss == nil then SR_data.boss = sourceName end
		local k = select(15, ...) --法术打脸
		local a = select(20, ...) --法术吸收
		SR_data.PreStaggered = SR_data.PreStaggered + k + a
	end
	if eventtype =="SPELL_CAST_SUCCESS" and spellid==119582  and sourceName ==UnitName("player") then --活血消除
			SR_data.Purified = SR_data.Purified + SR_data.StaggerPool * GetPurifyPercent()
			SR_data.StaggerPool = SR_data.StaggerPool * (1-GetPurifyPercent())
		
	end
	if eventtype =="SPELL_CAST_SUCCESS" and spellid==115308  and sourceName ==UnitName("player") then --快喝铁骨
	  	SR_data.QuickPurified = SR_data.QuickPurified + SR_data.StaggerPool * 0.05
		SR_data.StaggerPool = SR_data.StaggerPool * 0.95
		
	end
	if eventtype =="SPELL_PERIODIC_DAMAGE"  and destName ==UnitName("player") and spellid ==124255 then
	
		local k = select(15, ...) --醉拳打脸
		local a = select(20, ...) --醉拳吸收
		SR_data.DOT = SR_data.DOT + k 
		SR_data.StaggerPool = SR_data.StaggerPool -  k
		if a then 
			SR_data.DOT = SR_data.DOT + a 
			SR_data.StaggerPool = SR_data.StaggerPool - a
		end
	end
end

function SR_Numformat(num)
	if num>1000000000 then return string.format("%.1f", num/1000000000).."b" end
	if num>1000000 then return string.format("%.1f", num/1000000).."m" end
	if num>1000 then return string.format("%.1f", num/1000).."k" end
	if num<1 then return string.format("%.1f", num*100).."%" end
end

StRp = CreateFrame("frame") 
StRp:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
StRp:SetScript("OnEvent",SR_update)

StRp1 = CreateFrame("frame") 
StRp1:SetScript("OnEvent", function(self, event, ...)
if UnitClass("player"):find("武僧") and GetSpecialization()==1 then
    if (event == "PLAYER_REGEN_DISABLED") then
        SR_start()
    elseif (event == "PLAYER_REGEN_ENABLED") then
		SR_data.DOT = SR_data.DOT + SR_data.StaggerPool
		SR_data.StaggerPool = 0
		SR_end()
    end
  end
end)
StRp1:RegisterEvent("PLAYER_REGEN_ENABLED")
StRp1:RegisterEvent("PLAYER_REGEN_DISABLED")




function SR_all(cmd)
	if cmd =="all" then 
	for i=1,#SR_SavedReport do
		print(" ")
	    print("=====战斗序号："..i.."=====")
		SR_print(SR_SavedReport[i])
	end 
	elseif SR_SavedReport[tonumber(cmd)] then 
		print(" ")
	    print("=====战斗序号："..cmd.."=====")
		SR_print(SR_SavedReport[tonumber(cmd)])
	else
		print(" ")	 
		print("-------------------")		
		SR_print(SR_data)
	end
end

SLASH_Stagger1 = "/sr"
SLASH_Stagger2 = "/staggerreport"
SlashCmdList["Stagger"] = SR_all

