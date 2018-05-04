--------设置-----------
local config = {
tt = 2, --默认报告间隔
MaxStaggerTaken = 80, --醉拳承受率上限
Maxdot = 400*1000, --dot上限，当每跳dot伤害大于该值时视为dot伤害过高
whitelist = { --白名单，受到这些伤害时不会报告
	[209858]=true, --死疽
	[124255]=true, --醉拳
	[240448]=true, --震荡
	[243237]=true, --崩裂
	},

--以下为各功能开关，true=开，false=关	
Enable = true, --总开关
w = false,			 	--密语开关，如果打开，将会抄送一份报告密语给目标
isbapply = false, 		--是否报告铁骨上身
isbfade = true,			--是否报告铁骨消失
pfblvl = true, 			--是否报告活血使用水平 如果醉拳承受超过醉拳承受率上限提示使用更多活血
casts = true,			--是否报告技能使用情况
hit = true, 			--是否报告断铁骨时被命中
purify = true, 			--是否报告裸活血
}
--------变量声明-----------
local buff ={
["isb"] = 215479,
}
local spell = {
["isb"] = 115308,	--铁骨酒
["pfb"] = 119582,	--活血酒
["melee"] = 6603,	--平砍
["ks"] = 121253,--醉酿投
["tp"] = 100780,--猛虎掌
["bob"] = 115399,--玄牛酒
["bof"] = 115181,--火焰之息
["stagger"] = 115069, --醉拳
["dot"] =124255, --醉拳dot
}
local channel ={ --通报频道
["s"] = "SAY",
["g"] = "GUILD",
["w"] = "WHISPER",
["r"] ="RAID",
}
local data = {} --酒池数据
local T,t,checkpool= 0,0,0 --时间间隔变量

--------core-----------
local function CreateTable() --建档

	t = {
	["dot"] = 0, --醉拳承受
	["pool"] = 0,	--醉拳吸收
	["hits"] = 0,	--被命中次数
	["isb"] = 0, --断铁骨命中次数	
	["purify"] = 0, --裸活血次数
	["combatstart"] = 0, --战斗开始
	["combatend"] = 0,	--战斗结束
	["casts"] ={ --施法统计
		[spell.isb] = 0,
		[spell.pfb] = 0,
		[spell.ks] = 0,
		[spell.tp] = 0,
		[spell.bob] = 0,
		[spell.bof] = 0,		
		},	
	}
	return t
end 
local function shortnum(x)
	if x>=10^6 then return string.format("%.1f",x/10^6).."m" end 	
	if x>=10^3 then return string.format("%.1f",x/10^3).."k" end 
	return string.format("%.1f",x)
end 
local function PrintTable(name,tab)
	tab.combatend = GetTime()
	local p = 1-tab.dot/tab.pool		
		p = math.floor(p*1000)/10
	local q = 1-tab.isb/tab.hits
		q = math.floor(q*1000)/10
	if  config.casts and p<80 then 
		print("玩家："..name.."的本次战斗结束","战斗时长："..shortnum(tab.combatend-tab.combatstart).."秒")
		--print("醉拳承受："..shortnum(tab.dot),"醉拳吸收："..shortnum(tab.pool),"活血率："..p.."%")
		print("活血率："..p.."%  ","铁骨覆盖率："..q.."%")
		--print("被命中次数："..tab.hits,"其中断铁骨被命中次数："..tab.isb,"覆盖率："..q.."%")
		if tab.purify>0 then print("裸活血次数："..tab.purify)	end 
		print("施法统计：")
		for id,count in pairs(tab.casts) do 		
			print(GetSpellLink(id),count)
		end 
	end 
	data[name] = nil
end 


local function OnAura(dstName,id) --判断指定buff/debuff是否存在
	local spellname = GetSpellInfo(id)
	if UnitAura(dstName,spellname) then return 1 end 	
	return nil
end

local function report(str,b,name) --报告，参数含义分别为：报告内容，是否遵守间隔设置，密语目标
	if b then t = GetTime() if t-T >config.tt then T=t else return end end 
	SendChatMessage(str,channel.s) 
	
	if config.w and name then SendChatMessage(str,"WHISPER",nil,name) end 
	
		
end
local function trigger(self,event,timestamp,eventtype,hideCaster,srcGUID, srcName, srcFlags,srcRFlags,dstGUID,dstName, dstFlags,dstRFlags,...)	
	local other = {...}
	
	if not config.Enable then return end --总开关
	if UnitPosition("player") and  not GetMapInfo():find("Helheim") then return end --仅在副本中工作
	
	if eventtype == "SPELL_AURA_REMOVED" and other[1]==buff.isb  then --铁骨消失

		if config.isbfade and InCombatLockdown() then report(dstName.."已经失去"..GetSpellLink(spell.isb) .."，治疗注意！",false)  end 
	end	
	if eventtype == "SPELL_AURA_APPLIED" and other[1]==buff.isb  then --铁骨上身

		if  config.isbapply  then report(dstName.."已经获得"..GetSpellLink(spell.isb) .."，稳如POI！",false) end 
	end		
	
	if eventtype == "SPELL_CAST_SUCCESS" and data[srcName] and data[srcName].casts[other[1]] then	--施法次数统计
		if not data[srcName] then  data[srcName]=CreateTable() data[srcName].combatstart = GetTime() end --建档
		data[srcName].casts[other[1]] = data[srcName].casts[other[1]] + 1
		if other[1] == spell.pfb  then --裸活血次数
			local isbdura = {UnitAura(srcName,GetSpellInfo(215479))}
			if isbdura[6] <=2 then 
				data[srcName].purify = data[srcName].purify + 1 
				if config.purify then report(srcName.."在断铁骨下使用了"..GetSpellLink(spell.pfb).."请覆盖"..GetSpellLink(spell.isb) ,false,srcName)  end
			end 
		end 
	end 
	
	if eventtype == "SPELL_ABSORBED"  then --醉拳池更新
		if other[5] ==spell.stagger then --平砍命中
			if not data[dstName] then  data[dstName]=CreateTable() data[dstName].combatstart = GetTime() end --建档
			data[dstName].pool = data[dstName].pool + other[8]
			data[dstName].hits = data[dstName].hits + 1
			if not OnAura(dstName,buff.isb) then  --断铁骨平砍命中
				data[dstName].isb = data[dstName].isb + 1
				if config.hit then report(dstName.."断铁骨被"..MELEE.."命中，请覆盖"..GetSpellLink(spell.isb) ,true,dstName)  end 
			end
		end
		if other[8] ==spell.stagger then --技能命中
			if not data[dstName] then  data[dstName]=CreateTable() data[dstName].combatstart = GetTime() end --建档
			data[dstName].pool = data[dstName].pool + other[11]
			data[dstName].hits = data[dstName].hits + 1
			if (not OnAura(dstName,buff.isb)) and (not config.whitelist[other[1]]) then 
				data[dstName].isb = data[dstName].isb + 1 --断铁骨技能命中
				if config.hit then  report(dstName.."断铁骨被"..GetSpellLink(other[1]).."命中，请覆盖"..GetSpellLink(spell.isb) ,true,dstName)   end 
			end
		end
				
		if other[1] ==spell.dot then --醉拳dot被吸收
			data[dstName].dot = data[dstName].dot + other[11]	
		--	print(data[dstName].dot,data[dstName].pool)			
		end 
	
	end 
	
	if eventtype =="SPELL_PERIODIC_DAMAGE"  and other[1] ==spell.dot then	--醉拳打脸				
		local p =0
		data[dstName].dot = data[dstName].dot + other[4]
		
		if data[dstName].pool>0 then 
			p = data[dstName].dot/data[dstName].pool
			if p > config.MaxStaggerTaken/100 and other[4]>config.Maxdot then 		--醉拳承受过高
				p=math.floor(p*1000)/10
				if config.pfblvl then report(dstName.." 的醉拳dot承受："..p.."%，请更多使用"..GetSpellLink(spell.pfb),true,dstName) end 
			end 
		end 
	end
	
	if GetTime()>checkpool+3 and not InCombatLockdown() then  --每3秒检查是否脱战
		checkpool = GetTime()
		for name,tab in pairs(data) do  --遍历表，查看酒仙酒池是否归零
			if UnitStagger(name)==0 and tab.pool>0 then --如果目标酒池归零，视为脱战
			--开始计算战斗时长，铁骨覆盖率，活血率，技能使用情况
				
				PrintTable(name,tab)
				
			end 
		end 
	end
	
		
	
end 

KeepIronskin = CreateFrame("frame") 
KeepIronskin:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
KeepIronskin:SetScript("OnEvent",trigger) 


SLASH_KeepIronskin1 = "/kpis"
SlashCmdList["KeepIronskin"] = function () if config.Enable then config.Enable = false print("KeepIronskin已经关闭") else config.Enable = true print("KeepIronskin已经开启") end end 
