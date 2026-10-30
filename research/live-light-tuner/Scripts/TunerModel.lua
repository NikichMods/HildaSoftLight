-- SPDX-License-Identifier: MPL-2.0
-- Pure tuner state: bounds, text and explicit non-executable settings format.
local M={}
M.fields={"lm","radius","x","y","z","kelvin"}
M.spec={lm={0,30,0.1,1,"lm"},radius={50,400,10,50,"cm"},
    x={-150,150,2,10,"cm"},y={-150,150,2,10,"cm"},z={-100,150,2,10,"cm"},kelvin={2500,8000,100,500,"K"}}
function M.new()
    return {selected=1,param=1,coarse=false,panel=true,note="Not saved",lights={
        {name="Front",on=true,shadow=false,lm=4,radius=200,x=60,y=0,z=30,kelvin=5000},
        {name="Back",on=false,shadow=false,lm=2,radius=150,x=-60,y=0,z=30,kelvin=5000}}}
end
function M.adjust(s,dir)
    local key=M.fields[s.param];local b=M.spec[key];local l=s.lights[s.selected]
    l[key]=math.max(b[1],math.min(b[2],math.floor((l[key]+dir*b[s.coarse and 4 or 3])*100+0.5)/100))
    s.note="Unsaved changes"
end
function M.serialize(s)
    local lines={"# HildaSoftLightLiveTuner settings schema=1"}
    for i,l in ipairs(s.lights)do
        for _,k in ipairs(M.fields)do lines[#lines+1]=i.."."..k.."="..string.format("%.2f",l[k])end
        lines[#lines+1]=i..".on="..(l.on and "1"or"0")
    end
    lines[#lines+1]="1.shadow="..(s.lights[1].shadow and "1"or"0")
    return table.concat(lines,"\n").."\n"
end
function M.parse(text)
    assert(type(text)=="string" and #text<=4096 and text:match("^# HildaSoftLightLiveTuner settings schema=1\n"),"settings schema/size")
    local s=M.new();local seen={};local count=0
    for line in text:gmatch("[^\n]+")do
        if line:sub(1,1)~="#"then
            local i,k,v=line:match("^([12])%.([a-z]+)=([%+%-%.%d]+)$")
            assert(i and tonumber(v),"malformed settings row")
            local id=i.."."..k;assert(not seen[id],"duplicate setting");seen[id]=true;count=count+1;i=tonumber(i);v=tonumber(v)
            if M.spec[k]then local b=M.spec[k];assert(v==v and v>=b[1]and v<=b[2],"setting outside bounds");s.lights[i][k]=v
            else
                assert((k=="on"or(k=="shadow"and i==1))and(v==0 or v==1),"unknown/invalid flag")
                s.lights[i][k]=v==1
            end
        end
    end
    assert(count==15,"incomplete settings")
    s.note="Loaded saved settings";return s
end
function M.resetPerf(s,t,clear)
    s.perf={last=nil,sum=0,n=0,start=t,settle=t+1}
    if clear or not s.results then s.results={}end
end
function M.sample(s,t)
    local p=s.perf
    if not p then M.resetPerf(s,t,true);return false end
    assert(type(t)=="number"and t==t and math.abs(t)<math.huge,"invalid real time")
    local delta=p.last and(t-p.last)or 0;p.last=t
    if delta<0 or delta>0.5 then M.resetPerf(s,t,false);return false end
    if t<p.settle or delta<=0 then return false end
    p.sum=p.sum+delta;p.n=p.n+1
    if p.sum>=1 then
        local key=s.lights[1].shadow and "ON"or"OFF"
        s.results[key]={ms=p.sum*1000/p.n,fps=p.n/p.sum,n=p.n}
        p.sum,p.n=0,0;return true
    end
    return false
end
local function flag(b)return b and "ON"or"OFF"end
function M.text(s,shadow_note)
    local l=s.lights[s.selected]
    local lines={"HILDA SOFT LIGHT | RESEARCH", "Editing "..l.name.." | Front "..flag(s.lights[1].on).." / Back "..flag(s.lights[2].on)}
    for i,k in ipairs(M.fields)do
        local b=M.spec[k]
        lines[#lines+1]=(s.param==i and "> "or"  ")..k..": "..string.format(k=="lm"and"%.1f"or"%.0f",l[k]).." "..b[5]
    end
    lines[#lines+1]="Front shadows: "..flag(s.lights[1].shadow).." | step "..(s.coarse and"LARGE"or"fine")
    for _,key in ipairs({"OFF","ON"})do local p=s.results and s.results[key]
        lines[#lines+1]=p and string.format("Shadow %s: %.2f ms / %.1f engine fps",key,p.ms,p.fps)or("Shadow "..key..": collecting engine frames")
    end
    if shadow_note then lines[#lines+1]=shadow_note end
    lines[#lines+1]=s.note
    lines[#lines+1]="NumPad: 7 light | 8/2 parameter"
    lines[#lines+1]="4/6 value | 5 step | 1 on/off | 3 shadow"
    lines[#lines+1]="9 save | 0 exit edit | * STOP"
    lines[#lines+1]="Ctrl+Alt+F10: enter/exit edit"
    return table.concat(lines,"\n")
end
return M
