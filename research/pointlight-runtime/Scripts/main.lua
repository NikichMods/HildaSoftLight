-- SPDX-License-Identifier: MPL-2.0
-- Research only: one manually armed light per process. No production version.
local C={intensity=60,units=2,radius=350,offset={X=60,Y=0,Z=30},
    color={R=1,G=0.9,B=0.75,A=1},timeout_ms=90000}
local HILDA="/Game/MainContent/Act/Character_BP/hilda_BP.hilda_BP_C"
local LIGHT="/Script/Engine.PointLightComponent"
local phase,stop_intent="armed",false
local own,pawn_ref,root_ref,mesh_ref,hud_ref=nil,nil,nil,nil,nil
local monitor_handle,timeout_handle=nil,nil
local last_position,first_position,first_root=nil,nil,nil
local toggles,checks=0,0
local expected_on=false
local cleanup,dispatch
local function log(event,detail)print("HSL_PROBE event="..event.." "..(detail or "").."\n")end
local function valid(o)return o~=nil and o:IsValid()end
local function path(o)return assert(o:GetFullName():match("^[^ ]+ (.+)$"))end
local function cls(o)return path(o:GetClass())end
local function same(a,b)return valid(a) and valid(b) and a:GetAddress()==b:GetAddress()end
local function ref(o)return {path=path(o),class=cls(o),address=o:GetAddress()}end
local function find(r)
    if not r then return nil end
    local o=StaticFindObject(r.path)
    if not valid(o)then return nil end
    assert(path(o)==r.path and cls(o)==r.class and o:GetAddress()==r.address,"object identity replaced")
    return o
end
local function static(lib,method,...)
    local p="/Script/Engine."..lib..":"..method
    local f=StaticFindObject(p);local cdo=StaticFindObject("/Script/Engine.Default__"..lib)
    assert(valid(f) and f:type()=="UFunction" and f:GetFullName()=="Function "..p
        and valid(cdo) and cls(cdo)=="/Script/Engine."..lib,"missing exact static API "..p)
    return f(cdo,...)
end
local function alive(o)return valid(o) and static("KismetSystemLibrary","IsValid",o)==true end
local function instance(o)
    return alive(o) and not o:HasAnyFlags(EObjectFlags.RF_ClassDefaultObject|EObjectFlags.RF_ArchetypeObject)
end
local function derives(o,base)
    local c=o:GetClass()
    for _=1,32 do
        if not valid(c)then return false end
        if path(c)==base then return true end
        c=c:GetSuperStruct()
    end
    error("ancestry bound")
end
local function xyz(v)
    local r={X=v.X,Y=v.Y,Z=v.Z}
    for _,n in pairs(r)do assert(type(n)=="number" and n==n and math.abs(n)<math.huge,"non-finite vector")end
    return r
end
local function vec(v)return string.format("%.3f,%.3f,%.3f",v.X,v.Y,v.Z)end
local function distance(a,b)return math.sqrt((a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2)end
local function channels(o)
    local ch=o.LightingChannels
    assert(type(ch.bChannel0)=="boolean" and type(ch.bChannel1)=="boolean" and type(ch.bChannel2)=="boolean","lighting channel shape")
    return {ch.bChannel0,ch.bChannel1,ch.bChannel2}
end
local function mask(ch)return (ch[1]and 1 or 0)+(ch[2]and 2 or 0)+(ch[3]and 4 or 0)end
local function step(name,fn,...)
    log("PHASE","name="..name.." edge=BEGIN")
    local r=table.pack(fn(...));log("PHASE","name="..name.." edge=END")
    return table.unpack(r,1,r.n)
end
local function guard(fn)
    local ok,err=pcall(fn)
    if not ok then
        log("FAILED","phase="..phase.." detail="..tostring(err):sub(1,240))
        local clean,why=pcall(cleanup,"failure")
        if not clean then log("CLEANUP_PENDING",tostring(why):sub(1,180))end
    end
end
local function cancel(h,label)
    if h==nil then return end
    local removed=CancelDelayedAction(h)
    local remains=IsValidDelayedActionHandle(h)
    log("CANCEL","kind="..label.." handle="..h.." removed="..tostring(removed).." active="..tostring(remains))
    assert(remains==false,"own action still active: "..label)
end
cleanup=function(reason)
    if phase=="stopped" and not own and not monitor_handle and not timeout_handle then return end
    stop_intent=true;phase="stopping" -- Intent precedes any cancel/native operation.
    local errors={}
    local function attempt(fn)local ok,e=pcall(fn);if not ok then errors[#errors+1]=tostring(e):sub(1,160)end;return ok end
    if attempt(function()cancel(monitor_handle,"monitor")end)then monitor_handle=nil end
    if attempt(function()cancel(timeout_handle,"timeout")end)then timeout_handle=nil end
    attempt(function()
        local c=find(own)
        if alive(c)then
            assert(cls(c)==LIGHT and c:HasAnyFlags(EObjectFlags.RF_Transient),"refuse foreign cleanup")
            -- Hide even if a later native destroy fails. Never touch stock light.
            local hidden=pcall(function()c:SetVisibility(false,false);c:SetIntensity(0)end)
            log("HIDE_FOR_CLEANUP","returned="..tostring(hidden))
            step("destroy",function()c:K2_DestroyComponent(c)end)
            assert(not alive(c),"native logical destruction failed")
            log("DESTROYED","native_valid=false gc_not_forced=true")
        elseif own then log("DESTROYED","already_native_invalid=true gc_not_forced=true")end
        own=nil
    end)
    if #errors>0 then log("CLEANUP_PENDING",table.concat(errors," | "));return end
    phase="stopped";pawn_ref,root_ref,mesh_ref,hud_ref=nil,nil,nil,nil
    log("CLEANED","reason="..reason.." own_component=false action_handles=0 key_callbacks=inert toggles="..toggles.." checks="..checks)
end
local function gameplay()
    local hud,pawn=nil,nil
    for _,h in ipairs(FindAllOf("HUDMainUMG_BP_C")or{})do
        if instance(h) and h:IsInViewport()then
            local p=h:GetOwningPlayerPawn()
            if instance(p) and cls(p)==HILDA and derives(p,"/Script/Genesis.GenesisCharacter")then
                assert(hud==nil,"ambiguous gameplay HUD")
                hud,pawn=h,p
            end
        end
    end
    return hud,pawn
end
local function surface(p,root)
    local start=xyz(root:K2_GetComponentLocation())
    local finish={X=start.X,Y=start.Y,Z=start.Z-250}
    local hit={};local no_color={R=0,G=0,B=0,A=0}
    local found=step("floor_trace",static,"KismetSystemLibrary","LineTraceSingle",
        p,start,finish,0,false,{p},0,hit,true,no_color,no_color,0)
    assert(found==true and hit.bBlockingHit==true,"no nearby blocking floor; no light allocated")
    assert(hit.Component~=nil and hit.Component:type()=="FWeakObjectPtr","hit component weak-pointer shape")
    local comp=hit.Component:Get()
    assert(instance(comp) and derives(comp,"/Script/Engine.PrimitiveComponent")
        and not same(comp:GetOwner(),p),"trace did not identify foreign scene geometry")
    local ch=channels(comp);assert(mask(ch)>0,"surface has no lighting channel")
    log("SURFACE","component="..string.format("%q",path(comp)).." channels="..mask(ch).." trace_query=0 distance_max_cm=250")
    return ch
end
local function checked()
    local p,r,m,h,c=find(pawn_ref),find(root_ref),find(mesh_ref),find(hud_ref),find(own)
    assert(instance(p) and cls(p)==HILDA and instance(r) and instance(m) and instance(h)
        and h:IsInViewport() and same(h:GetOwningPlayerPawn(),p),"gameplay target no longer valid")
    assert(same(p:K2_GetRootComponent(),r) and same(p.Mesh,m),"pawn root/mesh changed")
    assert(alive(c) and cls(c)==LIGHT and same(c:GetOwner(),p) and same(c:GetOuter(),p)
        and same(c:GetAttachParent(),r) and c:HasAnyFlags(EObjectFlags.RF_Transient),"own component owner/attachment/flags changed")
    assert(c.Mobility==2 and c.CastShadows==false and c.bUseInverseSquaredFalloff==true
        and c.IntensityUnits==C.units and c.AttenuationRadius==C.radius
        and c.VolumetricScatteringIntensity==0 and c.IndirectLightingIntensity==0,"light settings changed")
    assert(c.bVisible==expected_on and c.Intensity==(expected_on and C.intensity or 0),"own light state changed externally")
    assert(mask(channels(c))&mask(channels(m))~=0,"Hilda/light channels no longer intersect")
    local actual=xyz(c:K2_GetComponentLocation())
    local expected=xyz(static("KismetMathLibrary","TransformLocation",r:K2_GetComponentToWorld(),C.offset))
    assert(distance(actual,expected)<1,"component world position does not follow root transform")
    last_position=actual;checks=checks+1
    return p,r,c
end
local function snapshot(event)
    local _,r,c=checked();local rp=xyz(r:K2_GetComponentLocation())
    log(event,"visible="..tostring(c.bVisible).." intensity="..c.Intensity.." component_cm="..vec(last_position)
        .." root_cm="..vec(rp).." moved_cm="..string.format("%.3f",distance(last_position,first_position))
        .." root_moved_cm="..string.format("%.3f",distance(rp,first_root)))
end
local function start()
    local h,p=gameplay()
    if not p then log("WAIT_GAMEPLAY","UIOnlyMap_DefaultPawn_skipped=true press_again_in_gameplay=true");return end
    phase="preparing"
    local r=p:K2_GetRootComponent();local m=p.Mesh
    assert(instance(r) and instance(m) and same(m:GetOwner(),p),"gameplay root/mesh unavailable")
    local model_channels=channels(m);assert(mask(model_channels)>0,"Hilda has no lighting channels")
    local floor_channels=surface(p,r)
    local union={}
    for i=1,3 do union[i]=model_channels[i]or floor_channels[i]end
    pawn_ref,root_ref,mesh_ref,hud_ref=ref(p),ref(r),ref(m),ref(h)
    log("TARGET","pawn="..string.format("%q",path(p)).." root="..string.format("%q",path(r))
        .." mesh_channels="..mask(model_channels).." geometry_channels="..mask(floor_channels).." own_channels="..mask(union))
    local class=StaticFindObject(LIGHT)
    assert(alive(class) and class:type()=="UClass" and path(class)==LIGHT,"exact light class unavailable")
    local name="HSL_Runtime_"..os.time()
    assert(not valid(StaticFindObject(path(p).."."..name)),"own name collision")
    local c=step("construct",StaticConstructObject,class,p,FName(name),EObjectFlags.RF_Transient)
    assert(valid(c) and cls(c)==LIGHT,"construction returned unexpected object")
    own=ref(c) -- Retain cleanup identity before all subsequent configuration/guards.
    assert(instance(c) and same(c:GetOwner(),p) and same(c:GetOuter(),p) and c.CreationMethod==0
        and c:HasAnyFlags(EObjectFlags.RF_Transient),"native ownership/flags failed")
    step("configure_dark",function()
        c:SetVisibility(false,false);c:SetIntensity(0);c:SetHiddenInGame(false,false);c:SetMobility(2)
        c.bUseInverseSquaredFalloff=true -- Own unregistered field; never change a registered stock light.
        c:SetIntensityUnits(C.units);c:SetAttenuationRadius(C.radius);c:SetCastShadows(false)
        c:SetCastVolumetricShadow(false);c:SetVolumetricScatteringIntensity(0);c:SetIndirectLightingIntensity(0)
        c:SetSourceRadius(0);c:SetSoftSourceRadius(0);c:SetSourceLength(0)
        c:SetLightColor(C.color,true);c:SetLightingChannels(union[1],union[2],union[3])
        assert(c.bVisible==false and c.Intensity==0 and c.bAffectsWorld==true,"pre-registration darkness/default contract")
    end)
    local transform=static("KismetMathLibrary","MakeTransform",C.offset,{Pitch=0,Yaw=0,Roll=0},{X=1,Y=1,Z=1})
    step("finish_register",function()p:FinishAddComponent(c,true,transform)end)
    assert(step("attach",function()return c:K2_AttachToComponent(r,FName("None"),0,0,0,false)end)==true,"attachment rejected")
    checked()
    local color=c:GetLightColor()
    assert(math.abs(color.R-C.color.R)<0.015 and math.abs(color.G-C.color.G)<0.015
        and math.abs(color.B-C.color.B)<0.015 and mask(channels(c))==mask(union),"color/channel readback differs")
    first_position=last_position;first_root=xyz(r:K2_GetComponentLocation())
    phase="ready"
    timeout_handle=ExecuteInGameThreadWithDelay(C.timeout_ms,function()
        if phase~="stopped"then stop_intent=true;dispatch(function()cleanup("timeout")end)end
    end)
    assert(type(timeout_handle)=="number","timeout handle missing")
    monitor_handle=LoopInGameThreadAfterFrames(30,function()
        if stop_intent or phase~="ready"then return end
        guard(function()checked()end) -- Bounded identity/transform guard; never writes follow transforms.
    end)
    assert(type(monitor_handle)=="number","monitor handle missing")
    log("READY","component="..string.format("%q",path(c)).." owner_attachment=true finish_returned=true direct_IsRegistered=unavailable"
        .." visible=false intensity_on_lm="..C.intensity.." radius_cm="..C.radius.." inverse_square=true linear_rgb=1,0.9,0.75"
        .." offset_cm="..vec(C.offset).." timeout_ms="..C.timeout_ms.." monitor="..monitor_handle.." timeout="..timeout_handle)
end
local function control()
    if stop_intent or phase=="stopped"or phase=="stopping"then return end
    if phase=="armed"then start();return end
    if phase~="ready"then return end
    local _,_,c=checked();local on=not c.bVisible
    c:SetIntensity(on and C.intensity or 0);c:SetVisibility(on,false)
    assert(c.bVisible==on and c.Intensity==(on and C.intensity or 0),"toggle readback failed")
    expected_on=on
    toggles=toggles+1;snapshot(on and "ON"or"OFF")
end
dispatch=function(fn)
    local ok,e=pcall(ExecuteInGameThread,function()guard(fn)end,EGameThreadMethod.EngineTick)
    if not ok then stop_intent=true;log("DISPATCH_FAILED","cleanup_requires_game_thread=true "..tostring(e):sub(1,180))end
end
local ok,err=pcall(function()
    for _,name in ipairs({"StaticFindObject","FindAllOf","StaticConstructObject","RegisterKeyBind","IsKeyBindRegistered",
        "ExecuteInGameThread","ExecuteInGameThreadWithDelay","LoopInGameThreadAfterFrames","CancelDelayedAction","IsValidDelayedActionHandle"})do
        assert(type(_G[name])=="function","missing API "..name)
    end
    assert(EngineTickAvailable==true and type(EGameThreadMethod.EngineTick)=="number","EngineTick unavailable")
    local mods={ModifierKey.CONTROL,ModifierKey.ALT}
    assert(not IsKeyBindRegistered(Key.F8,mods) and not IsKeyBindRegistered(Key.F7,mods),"control key collision")
    RegisterKeyBind(Key.F8,mods,function()if not stop_intent then dispatch(control)end end)
    RegisterKeyBind(Key.F7,mods,function()stop_intent=true;dispatch(function()cleanup("user")end)end)
end)
if ok then log("ARMED","CtrlAltF8=create_dark_then_toggle CtrlAltF7=stop one_attempt_per_process=true")
else phase="stopped";stop_intent=true;log("UNAVAILABLE",tostring(err):sub(1,220))end
