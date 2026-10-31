-- SPDX-License-Identifier: MPL-2.0
-- VERSION is checked against the package VERSION file by tools/build.py.
local VERSION="0.1.0"
local Profile=require("Profile")
local UI=require("EditorView")
local Bindings=require("KeyboardBindings")
local source=debug.getinfo(1,"S").source
local HILDA="/Game/MainContent/Act/Character_BP/hilda_BP.hilda_BP_C"
local LIGHT="/Script/Engine.PointLightComponent"
local mode,frame,generation="waiting",0,0
local target,controller_ref,engine_ref,handle,state,directory
local owns,functions,held={},{},{}
local stage,marker_failed="startup",false
local cleanup,closeEditor,fault,openEditor
local resume_editor=false
local seed_keys=false
local session=tostring(os.time())
local function ascii(v)return tostring(v):gsub("[^ -~]",function(c)return string.format("\\x%02X",c:byte())end)end
local function log(event,detail)print("HSL version="..VERSION.." event="..event.." "..ascii(detail or"").."\n")end
local function valid(o)return o~=nil and o:IsValid()end
local function path(o)return assert(o:GetFullName():match("^[^ ]+ (.+)$"))end
local function cls(o)return path(o:GetClass())end
local function same(a,b)return valid(a)and valid(b)and a:GetAddress()==b:GetAddress()end
local function ref(o)return {path=path(o),address=o:GetAddress()}end
local function find(r)
    if not r then return nil end
    local o=StaticFindObject(r.path)
    if valid(o)and o:GetAddress()==r.address then return o end
end
local function native(module,lib,method,...)
    local key="/Script/"..module.."."..lib..":"..method
    local cached=functions[key]
    if not cached then
        local f=StaticFindObject(key);local cdo=StaticFindObject("/Script/"..module..".Default__"..lib)
        assert(valid(f)and f:type()=="UFunction"and f:GetFullName()=="Function "..key
            and valid(cdo)and cls(cdo)=="/Script/"..module.."."..lib,"missing exact API "..key)
        cached={f,cdo};functions[key]=cached -- native /Script objects, never a world/pawn cache
    end
    return cached[1](cached[2],...)
end
local function static(lib,method,...)
    return native((lib=="WidgetBlueprintLibrary"or lib=="WidgetLayoutLibrary")and"UMG"or"Engine",lib,method,...)
end
local function game(method,...)return native("Genesis","GameGlobal",method,...)end
local function alive(o)return valid(o)and static("KismetSystemLibrary","IsValid",o)==true end
local function instance(o)return alive(o)and not o:HasAnyFlags(EObjectFlags.RF_ClassDefaultObject|EObjectFlags.RF_ArchetypeObject)end
local function scene()return game("GetInputMode",true,false)==0 and game("GetInputMode",false,true)==0 end
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
local function health(p)local hp=game("GetHP",p);assert(finite(hp),"native HP shape");return hp>0 end
local function current(c)
    if not c then return nil,"unbound"end
    local p,h,w,v,pc,r,m=find(c.pawn),find(c.hud),find(c.world),find(c.viewport),find(c.controller),find(c.root),find(c.mesh)
    if not alive(p)then return nil,"pawn"end
    if not alive(w)or not alive(v)or not same(v.World,w)or not same(p:GetWorld(),w)then return nil,"world"end
    if not alive(h)or not h:IsInViewport()or not alive(pc)or not same(pc:K2_GetPawn(),p)
        or not same(h:GetOwningPlayerPawn(),p)then return nil,"hud_controller"end
    if not alive(r)or not alive(m)or not same(p:K2_GetRootComponent(),r)or not same(p.Mesh,m)then return nil,"root_mesh"end
    if not health(p)then return nil,"hp_zero"end
    return h,p,r,m
end
local function context()
    local h,p,r,m=current(target);assert(h,"gameplay context changed");return h,p,r,m
end
local function probe()
    stage="discover"
    local list=FindAllOf("HUDMainUMG_BP_C")or{}
    if #list==0 then return nil end
    local engine=find(engine_ref)
    if not alive(engine)then
        engine=nil
        for _,e in ipairs(FindAllOf("GameEngine")or{})do
            if instance(e)then assert(not engine,"ambiguous GameEngine");engine=e end
        end
        if not engine then return nil end
        engine_ref=ref(engine)
    end
    local v=engine.GameViewport;local w=alive(v)and v.World
    if not alive(w)or not scene()then return nil end
    local found
    for _,h in ipairs(list)do
        if instance(h)and h:IsInViewport()then
            local p=h:GetOwningPlayerPawn();local pc=h:GetOwningPlayer()
            if instance(p)and cls(p)==HILDA and alive(pc)and same(pc:K2_GetPawn(),p)and same(p:GetWorld(),w)then
                local r,m=p:K2_GetRootComponent(),p.Mesh
                if instance(r)and instance(m)and same(m:GetOwner(),p)and health(p)then
                    if found then return nil end -- wait, never choose an ambiguous gameplay HUD
                    found={hud=ref(h),pawn=ref(p),controller=ref(pc),root=ref(r),mesh=ref(m),world=ref(w),viewport=ref(v)}
                end
            end
        end
    end
    return found
end
local function step(name,fn,...)
    stage=name;local result=table.pack(fn(...));return table.unpack(result,1,result.n)
end
UI.bind({valid=valid,alive=alive,path=path,cls=cls,same=same,ref=ref,find=find,static=static,context=context,step=step,
    projectionChecked=function(size,scale)log("PROJECTION_READY","viewport="..size.X.."x"..size.Y.." dpi="..scale)end})
closeEditor=function(reason)
    local had=UI.pending()
    if state then state.panel=false end
    if had then log("EDITOR_RELEASE_BEGIN",reason)end
    local ok,e=pcall(UI.cleanup)
    if had and ok then log("EDITOR","open=false")end
    if not ok then log("UI_CLEANUP_PENDING",e)end
    return ok
end
cleanup=function(reason)
    closeEditor(reason)
    local errors={}
    for i=1,3 do
        if owns[i]then
            local ok,e=pcall(function()
                local c=find(owns[i])
                if alive(c)then
                    assert(cls(c)==LIGHT and c:HasAnyFlags(EObjectFlags.RF_Transient),"own light identity lost")
                    c:SetVisibility(false,false);c:SetIntensity(0);c:K2_DestroyComponent(c)
                    assert(not alive(c),"native destruction incomplete")
                end
            end)
            if ok then owns[i]=nil else errors[#errors+1]=tostring(e)end
        end
    end
    if #errors>0 then error(table.concat(errors," | "))end
    target=nil;controller_ref=nil;marker_failed=false
    log("RELEASED","reason="..reason.." lights=0 generation="..generation)
end
fault=function(problem)
    if mode=="disabled"then return end
    local at=stage;mode="disabled" -- a late/reentrant callback cannot touch objects
    local ok,why=pcall(cleanup,"core_error")
    -- Cleanup native objects BEFORE cancellation; no subsequent UObject operation.
    local cancelled,active=false,false
    if handle then
        local h=handle;handle=nil
        local success=pcall(function()CancelDelayedAction(h);active=IsValidDelayedActionHandle(h)end)
        cancelled=success and not active
    end
    log("CORE_DISABLED","stage="..at.." error="..tostring(problem):sub(1,600).." cleanup="..tostring(ok).." cancelled="..tostring(cancelled).." restart_game=true")
    if not ok then log("CLEANUP_PENDING",why)end
    if directory then pcall(function()
        local f=assert(io.open(directory.."/HildaSoftLight-errors.log","ab"))
        f:write(os.date("!%Y-%m-%dT%H:%M:%SZ").." stage="..at.."\n"..tostring(problem):sub(1,6000).."\n");f:close()
    end)end
end
local function checked(i,p,r)
    local c=find(owns[i]);local l=state.lights[i]
    assert(alive(c)and cls(c)==LIGHT and same(c:GetOwner(),p)and same(c:GetOuter(),p)and same(c:GetAttachParent(),r),"light owner/parent lost")
    assert(c.Mobility==2 and c.IntensityUnits==0 and c.bUseInverseSquaredFalloff==false
        and math.abs(c.LightFalloffExponent-l.falloff)<0.002 and c.bUseTemperature==true and c.Temperature==l.kelvin
        and c.CastDynamicShadows==(i==1)and c.CastShadows==(i==1 and l.shadow)
        and c.bVisible==l.on and math.abs(c.Intensity-(l.on and l.intensity or 0))<0.002
        and c.AttenuationRadius==l.radius,"light setting readback")
    local a=c.LightingChannels;assert(a.bChannel0==(i==3)and a.bChannel1==(i~=3)and not a.bChannel2,"light channel readback")
    local v=c.RelativeLocation
    assert(math.abs(v.X-l.x)<0.02 and math.abs(v.Y-l.y)<0.02 and math.abs(v.Z-l.z)<0.02,"light offset readback")
end
local function apply(i)
    local _,p,r=context();local l=state.lights[i];local c=find(owns[i]);assert(alive(c),"own light unavailable")
    c:SetAttenuationRadius(l.radius);c:SetTemperature(l.kelvin);c:SetLightFalloffExponent(l.falloff)
    c:K2_SetRelativeLocation({X=l.x,Y=l.y,Z=l.z},false,{},true)
    c:SetCastShadows(i==1 and l.shadow);c:SetIntensity(l.on and l.intensity or 0);c:SetVisibility(l.on,false)
    checked(i,p,r)
end
local function shadows()
    for _,name in ipairs({"r.ShadowQuality","r.SupportPointLightWholeSceneShadows","r.AllowPointLightCubemapShadows"})do
        local n=static("KismetSystemLibrary","GetConsoleVariableIntValue",name)
        if not finite(n)or n<=0 then return false end
    end
    return true
end
local function bind(c)
    assert(not next(owns),"old light cleanup required")
    target=c;local _,p,r,m=context()
    assert(m.LightingChannels.bChannel1==true,"Hilda channel1 unavailable")
    assert(not state.lights[1].shadow or shadows(),"approved Front shadows unsupported by current engine settings")
    generation=generation+1;log("BIND_BEGIN","generation="..generation)
    local cl=StaticFindObject(LIGHT);assert(alive(cl)and cl:type()=="UClass","light class unavailable")
    for i,l in ipairs(state.lights)do
        stage="construct_"..i
        local light=StaticConstructObject(cl,p,FName("HSL_"..session.."_"..generation.."_"..i),EObjectFlags.RF_Transient)
        assert(alive(light)and cls(light)==LIGHT,"light construction");owns[i]=ref(light)
        assert(same(light:GetOwner(),p)and same(light:GetOuter(),p)and light.CreationMethod==0,"native light ownership")
        light:SetVisibility(false,false);light:SetIntensity(0);light:SetHiddenInGame(false,false);light:SetMobility(2)
        light.bUseInverseSquaredFalloff=false;light.CastDynamicShadows=i==1;light.CastStaticShadows=false
        light.bUseRayTracedDistanceFieldShadows=false
        light:SetCastShadows(false);light:SetCastVolumetricShadow(false);light:SetVolumetricScatteringIntensity(0);light:SetIndirectLightingIntensity(0)
        light:SetIntensityUnits(0);light:SetLightFalloffExponent(l.falloff);light:SetAttenuationRadius(l.radius)
        light:SetLightColor({R=1,G=1,B=1,A=1},true);light:SetUseTemperature(true);light:SetTemperature(l.kelvin)
        light:SetSourceRadius(0);light:SetSoftSourceRadius(0);light:SetSourceLength(0);light:SetLightingChannels(i==3,i~=3,false)
        assert(not light.bVisible and light.Intensity==0 and light.bAffectsWorld,"dark before registration")
        local transform=static("KismetMathLibrary","MakeTransform",{X=l.x,Y=l.y,Z=l.z},{Pitch=0,Yaw=0,Roll=0},{X=1,Y=1,Z=1})
        stage="register_"..i;p:FinishAddComponent(light,true,transform)
        assert(light:K2_AttachToComponent(r,FName("None"),0,0,0,false),"attach failed")
    end
    for i=1,3 do stage="apply_"..i;apply(i)end
    controller_ref=c.controller;mode="bound";log("BOUND","generation="..generation.." lights=3 auto=true ui=false")
    if resume_editor then resume_editor=false;openEditor()end
end
local function refresh()
    if not state.panel then return end
    local ok,e=pcall(UI.text,Profile.text(state))
    if not ok then closeEditor("text_error");log("UI_UNAVAILABLE",e)end
end
local keys={"MULTIPLY","DIVIDE","NUM_ZERO","NUM_ONE","NUM_TWO","NUM_THREE","NUM_FOUR","NUM_FIVE","NUM_SIX","NUM_SEVEN","NUM_EIGHT","NUM_NINE"}
local names={F10="F10",MULTIPLY="Multiply",DIVIDE="Divide",NUM_ZERO="NumPadZero",NUM_ONE="NumPadOne",NUM_TWO="NumPadTwo",
    NUM_THREE="NumPadThree",NUM_FOUR="NumPadFour",NUM_FIVE="NumPadFive",NUM_SIX="NumPadSix",NUM_SEVEN="NumPadSeven",NUM_EIGHT="NumPadEight",NUM_NINE="NumPadNine"}
local function audit()
    assert(type(IsKeyBindRegistered)=="function"and type(Key.F10)=="number","editor key API unavailable")
    assert(not IsKeyBindRegistered(Key.F10,{ModifierKey.CONTROL,ModifierKey.ALT}),"CtrlAltF10 conflict")
    local reserved={F10=true}
    for _,key in ipairs(keys)do assert(type(Key[key])=="number"and not IsKeyBindRegistered(Key[key]),"key conflict "..key);reserved[names[key]]=true end
    for _,id in ipairs(Bindings)do
        local key=game("GetKeyByVirtualKey",FName(id));assert(type(key)=="table"and key.KeyName~=nil,"key resolver shape")
        assert(not reserved[key.KeyName:ToString()],"game key conflict "..id)
    end
end
openEditor=function()
    if state.panel then closeEditor("user");return end
    local ok,e=pcall(function()
        assert(closeEditor("prepare"),"previous UI release incomplete");audit()
        local h=context();log("EDITOR_BEGIN","open=true");UI.create(h,Profile.text(state));state.panel=true;marker_failed=false;state.marker_unavailable=false;seed_keys=true
        Profile.resetPerf(state,static("GameplayStatics","GetRealTimeSeconds",h),true)
    end)
    if not ok then closeEditor("open_error");log("UI_UNAVAILABLE",e)
    else log("EDITOR","open=true")end
end
local function save()
    local ok,e=pcall(function()
        local f=assert(io.open(directory.."/settings-unitless-v2.ini","wb"))
        local wrote,why=f:write(Profile.serialize(state));local closed=f:close();assert(wrote and closed,why)
    end)
    state.note=ok and"Saved settings-unitless-v2.ini"or"SAVE FAILED"
    log(ok and"SAVED"or"SAVE_FAILED",ok and"explicit=true"or e)
end
local function action(key)
    if key=="F10"then
        if mode=="paused"then resume_editor=true;mode="waiting";log("RESUMED","automatic_lighting=true");return end
        if mode=="bound"then openEditor()end
        return
    end
    if mode~="bound"or not state.panel then return end
    local h=current(target)
    if not h then mode="waiting";cleanup("context");return end
    if key=="MULTIPLY"then mode="paused";cleanup("user_pause");log("PAUSED","resume=CtrlAltF10");return end
    if key=="NUM_ZERO"then closeEditor("user");return end
    if key=="NUM_SEVEN"then state.selected=state.selected%3+1
    elseif key=="NUM_TWO"then state.param=state.param%#Profile.fields+1
    elseif key=="NUM_EIGHT"then state.param=(state.param-2)%#Profile.fields+1
    elseif key=="NUM_FIVE"then state.coarse=not state.coarse
    elseif key=="NUM_FOUR"or key=="NUM_SIX"then Profile.adjust(state,key=="NUM_SIX"and 1 or -1);apply(state.selected)
    elseif key=="NUM_ONE"then local l=state.lights[state.selected];l.on=not l.on;apply(state.selected);state.note="Unsaved changes"
    elseif key=="NUM_THREE"then
        local l=state.lights[1]
        if l.shadow or shadows()then l.shadow=not l.shadow;apply(1);state.note="Unsaved changes"else state.note="Shadows unavailable"end
    elseif key=="DIVIDE"then
        if not marker_failed then state.markers=not state.markers;UI.hideMarkers()else state.note="Markers unavailable; reopen editor to retry"end
    elseif key=="NUM_NINE"then save()end
    Profile.resetPerf(state,static("GameplayStatics","GetRealTimeSeconds",h),key~="NUM_THREE");refresh()
end
local function poll()
    local pc=find(controller_ref);if not alive(pc)then return end
    local function down(key)local b=pc:IsInputKeyDown({KeyName=FName(key)});assert(type(b)=="boolean","key bool shape");return b end
    local ctrl=down("LeftControl")or down("RightControl");local alt=down("LeftAlt")or down("RightAlt")
    local f10=down("F10");local command
    if f10 and not held.F10 and ctrl and alt then command="F10"end
    held.F10=f10
    if state.panel then
        for _,key in ipairs(keys)do
            local d=down(names[key])
            if d and not seed_keys and not held[key]and not ctrl and not alt and not command then command=key end
            held[key]=d
        end
        seed_keys=false
    end
    if command and scene()then
        local was=state.panel;action(command)
        if not was and state.panel then for _,key in ipairs(keys)do held[key]=down(names[key])end;seed_keys=false end
    end
end
local function tick()
    if mode=="disabled"then return end
    local ok,e=xpcall(function()
        frame=frame+1
        if frame==1 then assert(type(handle)=="number"and IsValidDelayedActionHandle(handle),"own action handle unavailable")end
        if frame==1 or frame%15==0 or state.panel then
            stage="context_check"
            if mode=="bound"then
                local h,reason=current(target)
                if not h then mode="waiting";cleanup("context_"..reason)
                else
                    for i=1,3 do assert(alive(find(owns[i])),"own light disappeared")end
                    if state.panel and not scene()then closeEditor("menu")end
                end
            elseif frame==1 or frame%30==0 then
                local c=probe()
                if c then
                    controller_ref=c.controller
                    if mode=="waiting"then bind(c)end
                end
            end
        end
        stage="input";poll()
        if mode=="bound"and state.panel then
            local h=current(target)
            if h and Profile.sample(state,static("GameplayStatics","GetRealTimeSeconds",h))then refresh()end
            if state.markers and not marker_failed then
                local shown,why=pcall(function()
                    local points={}
                    for i=1,3 do local c=find(owns[i]);assert(alive(c),"marker light expired");local v=c:K2_GetComponentLocation();points[i]={X=v.X,Y=v.Y,Z=v.Z}end
                    UI.markers(find(controller_ref),points)
                end)
                if not shown then marker_failed=true;state.marker_unavailable=true;pcall(UI.hideMarkers);state.note="Markers unavailable; lighting continues";log("MARKERS_UNAVAILABLE",why);refresh()end
            end
        end
    end,function(err)return debug.traceback(tostring(err),2)end)
    if not ok then fault(e)end
end
local ok,e=pcall(function()
    for _,name in ipairs({"StaticFindObject","FindAllOf","StaticConstructObject","LoopInGameThreadAfterFrames","CancelDelayedAction","IsValidDelayedActionHandle"})do assert(type(_G[name])=="function","missing API "..name)end
    assert(EngineTickAvailable==true,"EngineTick unavailable")
    directory=assert(source:match("^@(.+)[/\\]Scripts[/\\]main%.lua$"),"own path unavailable")
    assert(directory:match("[/\\]HildaSoftLight$"),"unexpected mod directory")
    local f=assert(io.open(directory.."/DefaultProfile.ini","rb"));local text=f:read(4097);f:close();state=Profile.parse(text)
    local profile_source="approved_default"
    local custom=io.open(directory.."/settings-unitless-v2.ini","rb")
    if custom then
        local bytes=custom:read(4097);custom:close();local loaded,s=pcall(Profile.parse,bytes)
        if loaded then state=s;profile_source="saved"else log("SETTINGS_REJECTED",s)end
    end
    state.panel=false
    log("LOADED","profile="..profile_source.." auto=true editor=CtrlAltF10 pause=NumMultiply_in_editor resume=CtrlAltF10")
    handle=LoopInGameThreadAfterFrames(1,tick);assert(type(handle)=="number","invalid frame action handle")
end)
if not ok then fault(e)end
