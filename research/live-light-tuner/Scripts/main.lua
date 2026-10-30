-- SPDX-License-Identifier: MPL-2.0
-- Research-only three-light unitless/exponent tuner. R-018 native lights + R-017 independent text host.
local Model=require("TunerModel")
local UI=require("TunerUI")
local Bindings=require("KeyboardBindings")
local SOURCE=debug.getinfo(1,"S").source
local state=Model.new()
local HILDA="/Game/MainContent/Act/Character_BP/hilda_BP.hilda_BP_C"
local LIGHT="/Script/Engine.PointLightComponent"
local phase,stop_intent="armed",false
local owns={};local target;local loop_handle;local panel_note;local settings_file
local diagnostic_file,last_key,stage=nil,"none","startup"
local cleanup,begin_effects,check_chords
local markers_failed=false
local function ascii(s)
    return tostring(s):gsub("[^ -~]",function(c)return string.format("\\x%02X",c:byte())end)
end
local function log(e,s)print("HSL_TUNER event="..e.." "..ascii(s or "").."\n")end
local function valid(o)return o~=nil and o:IsValid()end
local function path(o)return assert(o:GetFullName():match("^[^ ]+ (.+)$"))end
local function cls(o)return path(o:GetClass())end
local function same(a,b)return valid(a)and valid(b)and a:GetAddress()==b:GetAddress()end
local function ref(o)return {path=path(o),class=cls(o),address=o:GetAddress()}end
local function find(r)
    if not r then return nil end
    local o=StaticFindObject(r.path)
    if not valid(o)then return nil end
    assert(path(o)==r.path and cls(o)==r.class and o:GetAddress()==r.address,"identity replaced")
    return o
end
local function native(module,lib,method,...)
    local p="/Script/"..module.."."..lib..":"..method
    local f=StaticFindObject(p);local cdo=StaticFindObject("/Script/"..module..".Default__"..lib)
    assert(valid(f)and f:type()=="UFunction"and f:GetFullName()=="Function "..p
        and valid(cdo)and cls(cdo)=="/Script/"..module.."."..lib,"missing exact API "..p)
    return f(cdo,...)
end
local function static(lib,method,...)return native((lib=="WidgetBlueprintLibrary"or lib=="WidgetLayoutLibrary")and"UMG"or"Engine",lib,method,...)end
local function game(method,...)return native("Genesis","GameGlobal",method,...)end
local function alive(o)return valid(o)and static("KismetSystemLibrary","IsValid",o)==true end
local function instance(o)return alive(o)and not o:HasAnyFlags(EObjectFlags.RF_ClassDefaultObject|EObjectFlags.RF_ArchetypeObject)end
local function step(name,fn,...)
    log("PHASE","name="..name.." edge=BEGIN")
    local v=table.pack(fn(...));log("PHASE","name="..name.." edge=END");return table.unpack(v,1,v.n)
end
local function xyz(v)return {X=v.X,Y=v.Y,Z=v.Z}end
local function channels(o)
    local c=o.LightingChannels
    assert(type(c.bChannel0)=="boolean"and type(c.bChannel1)=="boolean"and type(c.bChannel2)=="boolean","channel shape")
    return {c.bChannel0,c.bChannel1,c.bChannel2}
end
local function mask(c)return(c[1]and 1 or 0)+(c[2]and 2 or 0)+(c[3]and 4 or 0)end
local function context()
    stage="context"
    local h,p,r,m=find(target.hud),find(target.pawn),find(target.root),find(target.mesh)
    local world,viewport=find(target.world),find(target.viewport)
    assert(instance(h)and h:IsInViewport()and instance(p)and cls(p)==HILDA and instance(r)and instance(m)
        and same(h:GetOwningPlayerPawn(),p)and same(p:K2_GetRootComponent(),r)and same(p.Mesh,m),"gameplay pawn/root/viewport lost")
    assert(alive(world)and alive(viewport)and same(p:GetWorld(),world)and same(viewport.World,world),"current world changed")
    return h,p,r,m
end
local function scene()return game("GetInputMode",true,false)==0 and game("GetInputMode",false,true)==0 end
local function guarded(fn)
    local ok,e=xpcall(fn,function(problem)
        return "phase="..phase.." stage="..stage.." last_key="..last_key
            .." selected="..state.selected.." param="..state.param.."\n"
            ..Model.serialize(state)..debug.traceback(tostring(problem),2)
    end)
    if not ok then
        -- Standard Lua file I/O preserves the actual error even if the native print path drops it.
        local recorded=false
        if diagnostic_file then
            local written=pcall(function()
                local f=assert(io.open(diagnostic_file,"ab"))
                local result,why=f:write("HSL_TUNER_FAILURE "..os.date("!%Y-%m-%dT%H:%M:%SZ").."\n"..tostring(e):sub(1,12000).."\n\n")
                local closed=f:close();assert(result and closed,why)
            end)
            recorded=written
        end
        local detail=ascii(e):sub(1,2200)
        local clean,why=pcall(cleanup,"failure")
        -- Emit after cleanup as a second independent native-log opportunity. Guards stay unchanged.
        log("FAILED","recorded="..tostring(recorded).." detail="..detail)
        if not clean then log("CLEANUP_PENDING",tostring(why):sub(1,180))end
    end
end
cleanup=function(reason)
    if phase=="stopped"and not loop_handle and not next(owns)and not UI.pending()then return end
    stop_intent=true;phase="stopping"
    local errors={}
    local function attempt(fn)local ok,e=pcall(fn);if not ok then errors[#errors+1]=tostring(e):sub(1,150)end;return ok end
    if loop_handle and attempt(function()
        local removed=CancelDelayedAction(loop_handle)
        local active=IsValidDelayedActionHandle(loop_handle)
        log("CANCEL","handle="..loop_handle.." removed="..tostring(removed).." active="..tostring(active))
        assert(not active,"own frame action remains active")
    end)then loop_handle=nil end
    for i=1,#state.lights do
        if owns[i]and attempt(function()
            local c=find(owns[i])
            if alive(c)then
                assert(cls(c)==LIGHT and c:HasAnyFlags(EObjectFlags.RF_Transient),"foreign light cleanup refused")
                pcall(function()c:SetVisibility(false,false);c:SetIntensity(0)end)
                step("destroy_"..i,function()c:K2_DestroyComponent(c)end)
                assert(not alive(c),"native light destruction not confirmed")
            end
            log("DESTROYED","light="..i.." native_alive=false gc_not_forced=true")
        end)then owns[i]=nil end
    end
    attempt(UI.cleanup)
    if #errors>0 then log("CLEANUP_PENDING",table.concat(errors," | "));return end
    target=nil;phase="stopped"
    log("CLEANED","reason="..reason.." own_lights=0 own_viewport=0 action_handles=0 native_key_polling=stopped no_timeout=true")
end
UI.bind({projectionChecked=function(size,scale,raw,out)log("MARKER_PROJECTION","size="..size.X.."x"..size.Y.." dpi="..scale.." raw="..raw.X..","..raw.Y.." widget="..out.X..","..out.Y.." out_table=true scaling_check=true visual=UNTESTED")end,valid=valid,alive=alive,path=path,cls=cls,same=same,ref=ref,find=find,static=static,step=step,context=context})
local function now(p)
    local t=static("GameplayStatics","GetRealTimeSeconds",p)
    assert(type(t)=="number"and t==t and t>=0 and t<math.huge,"real-time clock unavailable")
    return t
end
local function checkedLight(i,p,r)
    stage="light_check_"..i
    local c=find(owns[i]);local l=state.lights[i]
    assert(alive(c)and cls(c)==LIGHT and c:HasAnyFlags(EObjectFlags.RF_Transient)
        and same(c:GetOwner(),p)and same(c:GetOuter(),p)and same(c:GetAttachParent(),r),"own light owner/parent changed")
    assert(c.Mobility==2 and c.bUseInverseSquaredFalloff==false and c.IntensityUnits==0
        and math.abs(c.LightFalloffExponent-l.falloff)<0.002
        and c.bUseTemperature==true and c.Temperature==l.kelvin
        and c.CastDynamicShadows==(i==1)and c.CastShadows==(i==1 and l.shadow)
        and c.bVisible==l.on and math.abs(c.Intensity-(l.on and l.intensity or 0))<0.002
        and c.AttenuationRadius==l.radius,"own light settings changed")
    assert(mask(channels(c))==Model.channelMask(i),"own channels changed")
    local rel=c.RelativeLocation
    assert(math.abs(rel.X-l.x)<0.02 and math.abs(rel.Y-l.y)<0.02 and math.abs(rel.Z-l.z)<0.02,"relative offset changed")
    return c
end
local function apply(i)
    stage="apply_"..i
    local _,p,r=context();local l=state.lights[i];local c=find(owns[i])
    assert(alive(c)and same(c:GetOwner(),p)and same(c:GetAttachParent(),r),"own light unavailable")
    c:SetAttenuationRadius(l.radius);c:SetTemperature(l.kelvin);c:SetLightFalloffExponent(l.falloff)
    c:K2_SetRelativeLocation({X=l.x,Y=l.y,Z=l.z},false,{},true)
    c:SetCastShadows(i==1 and l.shadow)
    c:SetIntensity(l.on and l.intensity or 0);c:SetVisibility(l.on,false)
    checkedLight(i,p,r)
end
local function refresh()
    if state.panel then
        context();stage="panel_format";local text=Model.text(state,panel_note)
        stage="panel_text";UI.text(text)
    end
end
local function shadow_allowed()
    local _,_,_,m=context()
    local q=static("KismetSystemLibrary","GetConsoleVariableIntValue","r.ShadowQuality")
    local support=static("KismetSystemLibrary","GetConsoleVariableIntValue","r.SupportPointLightWholeSceneShadows")
    local cube=static("KismetSystemLibrary","GetConsoleVariableIntValue","r.AllowPointLightCubemapShadows")
    log("SHADOW_CAPS","quality="..q.." project_support="..support.." cube="..cube
        .." hilda_CastShadow="..tostring(m.CastShadow).." hilda_dynamic="..tostring(m.bCastDynamicShadow))
    if q<=0 or support<=0 or cube<=0 then panel_note="Shadow blocked by engine settings (unchanged)";return false end
    panel_note=(m.CastShadow and m.bCastDynamicShadow)and"Shadow render: verify visually"or"Hilda caster disabled; scene shadows only"
    return true
end
local function makeLight(i,p,r)
    local l=state.lights[i];local cl=StaticFindObject(LIGHT)
    assert(alive(cl)and cl:type()=="UClass","PointLightComponent class unavailable")
    local c=step("create_"..i,StaticConstructObject,cl,p,FName("HSL_Tuner_"..i.."_"..os.time()),EObjectFlags.RF_Transient)
    assert(valid(c)and cls(c)==LIGHT,"bad light construction");owns[i]=ref(c)
    assert(instance(c)and same(c:GetOwner(),p)and same(c:GetOuter(),p)and c.CreationMethod==0,"native light ownership")
    c:SetVisibility(false,false);c:SetIntensity(0);c:SetHiddenInGame(false,false);c:SetMobility(2)
    c.bUseInverseSquaredFalloff=false;c.CastDynamicShadows=i==1;c.CastStaticShadows=false
    c.bUseRayTracedDistanceFieldShadows=false
    c:SetCastShadows(false);c:SetCastVolumetricShadow(false)
    c:SetVolumetricScatteringIntensity(0);c:SetIndirectLightingIntensity(0)
    c:SetIntensityUnits(0);c:SetLightFalloffExponent(l.falloff);c:SetAttenuationRadius(l.radius)
    c:SetLightColor({R=1,G=1,B=1,A=1},true);c:SetUseTemperature(true);c:SetTemperature(l.kelvin)
    c:SetSourceRadius(0);c:SetSoftSourceRadius(0);c:SetSourceLength(0)
    c:SetLightingChannels(i==3,i~=3,false)
    assert(not c.bVisible and c.Intensity==0 and c.bAffectsWorld,"pre-registration dark guard")
    local tr=static("KismetMathLibrary","MakeTransform",{X=l.x,Y=l.y,Z=l.z},{Pitch=0,Yaw=0,Roll=0},{X=1,Y=1,Z=1})
    step("register_"..i,function()p:FinishAddComponent(c,true,tr)end)
    assert(step("attach_"..i,function()return c:K2_AttachToComponent(r,FName("None"),0,0,0,false)end),"attachment failed")
end
local function save()
    local f,e=io.open(settings_file,"wb")
    if not f then state.note="SAVE FAILED: "..tostring(e):sub(1,70);log("SAVE_FAILED",state.note);return end
    local ok,why=pcall(function()assert(f:write(Model.serialize(state)));assert(f:flush())end)
    local closed,close_error=f:close();ok=ok and closed~=nil
    state.note=ok and "Saved tuner-unitless-v2.ini"or"SAVE FAILED"
    log(ok and "SAVED"or"SAVE_FAILED",ok and "file=own_mod/tuner-unitless-v2.ini explicit=true"or tostring(why or close_error):sub(1,120))
end
begin_effects=function()
    if stop_intent or phase~="checking"then return end
    local h,p,r,m=context();assert(scene(),"game input context changed during preparation")
    local start=xyz(r:K2_GetComponentLocation());local hit={};local clear={R=0,G=0,B=0,A=0}
    assert(step("floor_trace",static,"KismetSystemLibrary","LineTraceSingle",p,start,
        {X=start.X,Y=start.Y,Z=start.Z-250},0,false,{p},0,hit,true,clear,clear,0)==true and hit.bBlockingHit,"no floor hit")
    assert(hit.Component and hit.Component:type()=="FWeakObjectPtr","hit shape")
    local surface=hit.Component:Get();assert(instance(surface)and not same(surface:GetOwner(),p),"wrong floor target")
    local a,b=channels(m),channels(surface)
    assert(a[2]and b[1],"required model channel1 / floor channel0 unavailable")
    log("CHANNELS","model="..mask(a).." floor="..mask(b).." character=2 environment=1 environment_can_affect_model="..tostring(a[1])
        .." floor_CastShadow="..tostring(surface.CastShadow).." floor_dynamic="..tostring(surface.bCastDynamicShadow))
    local f=io.open(settings_file,"rb")
    if f then local text=f:read(4097);f:close();local ok,loaded=pcall(Model.parse,text)
        if ok then state=loaded else state.note="Saved file rejected; diagnostic defaults";log("SETTINGS_REJECTED",tostring(loaded):sub(1,150))end
    end
    phase="preparing";step("ui_prepare",UI.create,h,Model.text(state,panel_note));h,p,r,m=context()
    if stop_intent then cleanup("user");return end
    for i=1,#state.lights do
        makeLight(i,p,r)
        if stop_intent then cleanup("user");return end
    end
    if state.lights[1].shadow and not shadow_allowed()then state.lights[1].shadow=false;state.note="Saved shadows disabled by engine gate"end
    for i=1,#state.lights do apply(i)end;phase="ready";Model.resetPerf(state,now(p),true)
    refresh();log("READY","own_lights=3 independent_viewport=true units=Unitless falloff=exponent schema=2 no_timeout=true handle="..loop_handle)
end
local reserved={NumPadZero=true,NumPadOne=true,NumPadTwo=true,NumPadThree=true,NumPadFour=true,
    NumPadFive=true,NumPadSix=true,NumPadSeven=true,NumPadEight=true,NumPadNine=true,Multiply=true,Divide=true,F10=true}
local function audit_bindings()
    check_chords()
    context();assert(scene(),"input context changed during key preflight")
    for i=1,#Bindings do
        local key=game("GetKeyByVirtualKey",FName(Bindings[i]))
        assert(type(key)=="table"and key.KeyName~=nil,"current key resolver shape")
        local name=key.KeyName:ToString()
        assert(not reserved[name],"game key collision: "..Bindings[i].."="..name)
    end
    log("INPUT_CLEAR","keyboard_virtual_rows="..#Bindings.." native_key_polling=true")
end
local function start()
    local h,p
    for _,candidate in ipairs(FindAllOf("HUDMainUMG_BP_C")or{})do
        if instance(candidate)and candidate:IsInViewport()then
            local pawn=candidate:GetOwningPlayerPawn()
            if instance(pawn)and cls(pawn)==HILDA then assert(not h,"ambiguous gameplay HUD");h,p=candidate,pawn end
        end
    end
    if not p or not scene()then log("WAIT_GAMEPLAY","press_CtrlAltF10_after_loading=true");return end
    local r,m=p:K2_GetRootComponent(),p.Mesh
    assert(instance(r)and instance(m)and same(m:GetOwner(),p),"root/mesh unavailable")
    local engine
    for _,e in ipairs(FindAllOf("GameEngine")or{})do if instance(e)then assert(not engine,"ambiguous GameEngine");engine=e end end
    local viewport=engine and engine.GameViewport
    local world=p:GetWorld()
    assert(alive(viewport)and alive(world)and same(viewport.World,world),"current viewport/world unavailable")
    target={hud=ref(h),pawn=ref(p),root=ref(r),mesh=ref(m),world=ref(world),viewport=ref(viewport)}
    phase="checking";audit_bindings();begin_effects()
end
local function action(key)
    last_key=key;stage="control"
    if stop_intent or phase=="stopped"or phase=="stopping"then return end
    if phase=="armed"then if key=="F10"then start()end;return end
    if phase~="ready"then return end
    local _,p=context()
    if not scene()then if state.panel then state.panel=false;UI.show(false)end;return end
    if key=="F10"then
        if not state.panel then audit_bindings()end
        state.panel=not state.panel;UI.show(state.panel)
        if state.panel then Model.resetPerf(state,now(p),true)end
        log("EDIT_MODE","active="..tostring(state.panel));refresh();return
    end
    if not state.panel then return end
    if key=="NUM_ZERO"then state.panel=false;UI.show(false);log("EDIT_MODE","active=false");return
    elseif key=="NUM_SEVEN"then state.selected=state.selected%#state.lights+1
    elseif key=="NUM_EIGHT"then state.param=(state.param-2)%#Model.fields+1
    elseif key=="NUM_TWO"then state.param=state.param%#Model.fields+1
    elseif key=="NUM_FIVE"then state.coarse=not state.coarse
    elseif key=="NUM_FOUR"or key=="NUM_SIX"then Model.adjust(state,key=="NUM_SIX"and 1 or -1);apply(state.selected);Model.resetPerf(state,now(p),true)
    elseif key=="NUM_ONE"then local l=state.lights[state.selected];l.on=not l.on;state.note="Unsaved changes";apply(state.selected);Model.resetPerf(state,now(p),true)
    elseif key=="NUM_THREE"then
        local l=state.lights[1]
        if l.shadow or shadow_allowed()then l.shadow=not l.shadow;state.note="Unsaved changes";step("shadow_toggle",apply,1);Model.resetPerf(state,now(p),false);log("SHADOW","front="..tostring(l.shadow).." native_CastShadows_readback=true visual_result=UNTESTED")end
    elseif key=="DIVIDE"then
        if markers_failed then state.note="Markers unavailable this session; see log"
        else state.markers=not state.markers;UI.hideMarkers();log("MARKERS","enabled="..tostring(state.markers));Model.resetPerf(state,now(p),true)end
    elseif key=="NUM_NINE"then save()
    end
    log("CONTROL","key="..key.." light="..state.selected.." parameter="..Model.fields[state.param]
        .." value="..state.lights[state.selected][Model.fields[state.param]].." panel="..tostring(state.panel))
    refresh()
end
-- All native reads, controls and light/UI mutations share this single EngineTick callback.
-- No input-thread Lua callbacks and no ExecuteInGameThread handoff while it is running.
local poll_controller,ticks,last_held=nil,0,{}
local key_names={NUM_ZERO="NumPadZero",NUM_ONE="NumPadOne",NUM_TWO="NumPadTwo",
    NUM_THREE="NumPadThree",NUM_FOUR="NumPadFour",NUM_FIVE="NumPadFive",NUM_SIX="NumPadSix",
    NUM_SEVEN="NumPadSeven",NUM_EIGHT="NumPadEight",NUM_NINE="NumPadNine",MULTIPLY="Multiply",DIVIDE="Divide",F10="F10"}
local keys={"F10","MULTIPLY","DIVIDE","NUM_ZERO","NUM_ONE","NUM_TWO","NUM_THREE","NUM_FOUR","NUM_FIVE",
    "NUM_SIX","NUM_SEVEN","NUM_EIGHT","NUM_NINE"}
check_chords=function()
    local mods={ModifierKey.CONTROL,ModifierKey.ALT}
    assert(type(Key.F10)=="number"and not IsKeyBindRegistered(Key.F10,mods),"UE4SS chord collision/missing key F10")
    for _,key in ipairs(keys)do
        if key~="F10"then assert(type(Key[key])=="number"and not IsKeyBindRegistered(Key[key]),"UE4SS bare keypad collision/missing key "..key)end
    end
end
local function poll_keys()
    if phase=="armed"and(ticks==1 or ticks%30==0)then
        poll_controller=nil
        for _,h in ipairs(FindAllOf("HUDMainUMG_BP_C")or{})do
            if instance(h)and h:IsInViewport()then
                local p=h:GetOwningPlayerPawn()
                if instance(p)and cls(p)==HILDA then
                    local c=h:GetOwningPlayer()
                    if instance(c)and same(c:K2_GetPawn(),p)then
                        assert(not poll_controller,"ambiguous input controller")
                        poll_controller=ref(c)
                    end
                end
            end
        end
    end
    local c=find(poll_controller)
    if not instance(c)then
        assert(phase=="armed","input controller lost")
        poll_controller=nil;last_held={};return
    end
    if phase=="ready"then assert(same(c:K2_GetPawn(),find(target.pawn)),"input pawn changed")end
    local function down(name)
        local result=c:IsInputKeyDown({KeyName=FName(name)})
        assert(type(result)=="boolean","native key result shape")
        return result
    end
    local control=down("LeftControl")or down("RightControl")
    local alt=down("LeftAlt")or down("RightAlt")
    local command
    -- Sample every key even with a hidden panel: held keys cannot fire on reopening.
    for _,key in ipairs(keys)do
        local held=down(key_names[key])
        local eligible=key=="F10"and control and alt or key~="F10"and not control and not alt
        if held and eligible and not last_held[key]and not command then command=key end
        last_held[key]=held
    end
    if command=="MULTIPLY"and phase=="ready"and state.panel then last_key=command;cleanup("user")
    elseif command and scene()then action(command)end
end
local function tick()
    if stop_intent or phase=="stopped"or phase=="stopping"then return end
    guarded(function()
        ticks=ticks+1
        if phase=="ready"then
            stage="frame_context"
            local current=find(target.pawn);assert(instance(current),"pawn expired")
            local viewport,world=find(target.viewport),find(target.world)
            assert(alive(viewport)and alive(world)and same(viewport.World,world),"current viewport world changed")
            if ticks%30==0 then
                local _,cp,cr=context();for i=1,#state.lights do checkedLight(i,cp,cr)end
                if not scene()then
                    if state.panel then state.panel=false;UI.show(false)end
                    Model.resetPerf(state,now(cp),true)
                end
            end
            if Model.sample(state,now(current))then refresh()end
        end
        stage="native_key_poll";poll_keys()
        if phase=="ready"and not stop_intent and state.panel and state.markers and not markers_failed then
            local ok,why=pcall(function()
                stage="markers"
                local points={}
                for i=1,#state.lights do
                    local c=find(owns[i]);assert(alive(c),"own marker light lost")
                    points[i]=xyz(c:K2_GetComponentLocation())
                end
                UI.markers(find(poll_controller),points)
            end)
            if not ok then
                markers_failed=true;state.markers=false;pcall(UI.hideMarkers)
                state.note="Markers unavailable; light tuning continues"
                log("MARKERS_DISABLED",tostring(why):sub(1,220));refresh()
            end
        end
    end)
end
local ok,err=pcall(function()
    for _,name in ipairs({"StaticFindObject","FindAllOf","LoadAsset","StaticConstructObject","IsKeyBindRegistered",
        "LoopInGameThreadAfterFrames","CancelDelayedAction","IsValidDelayedActionHandle"})do assert(type(_G[name])=="function","missing API "..name)end
    assert(EngineTickAvailable==true and type(EGameThreadMethod.EngineTick)=="number","EngineTick unavailable")
    local directory=SOURCE:match("^@(.+)[/\\]Scripts[/\\]main%.lua$")
    assert(directory and directory:match("[/\\]HildaSoftLightLiveTuner$"),"unexpected own script path; refuse file writes")
    settings_file=directory.."/tuner-unitless-v2.ini"
    diagnostic_file=directory.."/tuner-diagnostic.log"
    check_chords()
    loop_handle=LoopInGameThreadAfterFrames(1,tick)
    assert(type(loop_handle)=="number","frame handle unavailable")
end)
if ok then log("ARMED","edit=CtrlAltF10 stop=NumMultiply_while_editing numlock=ON native_key_polling=true no_automatic_start=true")
else stop_intent=true;phase="stopped";log("UNAVAILABLE",tostring(err):sub(1,200))end
