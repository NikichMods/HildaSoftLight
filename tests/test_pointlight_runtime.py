# SPDX-License-Identifier: MPL-2.0
"""Probe containment tests under Lua 5.4. Mocks do not prove Unreal lighting."""
import os, pathlib, sys, unittest
if os.environ.get('HSL_TEST_LIBRARIES'):
    sys.path.insert(0, os.environ['HSL_TEST_LIBRARIES'])
from lupa.lua54 import LuaRuntime
SOURCE=(pathlib.Path(__file__).resolve().parents[1]/'research/pointlight-runtime/Scripts/main.lua').read_text(encoding='utf-8')
FIXTURE=r'''
S={game=false,created=0,destroyed=0,logs={},queue={},actions={},next=0,keys={},foreign_writes=0}
function print(s)table.insert(S.logs,s)end
local registry={};local nextaddr=100
local function api()assert(S.game,'engine access outside EngineTick')end
local function object(p,kind)
 nextaddr=nextaddr+1;local o={p=p,kind=kind,addr=nextaddr,live=true,flags=0}
 function o:IsValid()api();return true end -- Lua-valid may survive native PendingKill.
 function o:GetAddress()api();return self.addr end
 function o:GetFullName()api();return self.kind..' '..self.p end
 function o:GetClass()api();return registry[self.kind]end
 function o:GetOwner()api();return self.owner end
 function o:GetOuter()api();return self.owner end
 function o:GetSuperStruct()api();return self.super end
 function o:HasAnyFlags(f)api();return self.flags&f~=0 end
 function o:type()api();return self.kind=='Class'and'UClass'or(self.kind=='Function'and'UFunction'or'UObject')end
 registry[p]=o;return o
end
local function class(p,super)local c=object(p,'Class');c.super=super;return c end
class('Class');class('Function');class('/Script/Engine.Actor');class('/Script/Engine.SceneComponent')
local primitive=class('/Script/Engine.PrimitiveComponent')
class('/Script/Engine.StaticMeshComponent',primitive);class('/Script/Engine.SkeletalMeshComponent',primitive)
local genesis=class('/Script/Genesis.GenesisCharacter')
local HILDA='/Game/MainContent/Act/Character_BP/hilda_BP.hilda_BP_C'
class(HILDA,genesis);class('/Script/Engine.PointLightComponent');class('/Game/HUD')
local function static(lib,method,fn)
 local k='/Script/Engine.'..lib
 if not registry[k]then class(k);object('/Script/Engine.Default__'..lib,k)end
 local f=object(k..':'..method,'Function');setmetatable(f,{__call=function(_,...)api();return fn(...)end})
end
S.pawn=object('/World.Hilda',HILDA);S.root=object('/World.Hilda.Root','/Script/Engine.SceneComponent')
S.mesh=object('/World.Hilda.Mesh','/Script/Engine.SkeletalMeshComponent');S.mesh.owner=S.pawn
S.mesh.LightingChannels={bChannel0=false,bChannel1=false,bChannel2=true}
S.hud=object('/World.HUD','/Game/HUD');S.pawn.Mesh=S.mesh
S.floor=object('/World.Floor','/Script/Engine.StaticMeshComponent');S.floor.owner=object('/World.FloorActor','/Script/Engine.Actor')
S.floor.LightingChannels={bChannel0=true,bChannel1=false,bChannel2=false}
S.position={X=1000,Y=2000,Z=100}
function S.hud:IsInViewport()api();return true end
function S.hud:GetOwningPlayerPawn()api();if not S.ui then return S.pawn end end
function S.pawn:K2_GetRootComponent()api();return S.root end
function S.root:K2_GetComponentLocation()api();return S.position end
function S.root:K2_GetComponentToWorld()api();return {position=S.position}end
static('KismetSystemLibrary','IsValid',function(_,o)return o~=nil and o.live end)
static('KismetSystemLibrary','LineTraceSingle',function(_,p,a,b,q,complex,ignore,debug,hit)
 assert(q==0 and complex==false and ignore[1]==S.pawn and debug==0)
 hit.bBlockingHit=true;hit.Component={type=function()return'FWeakObjectPtr'end,Get=function()return S.floor end}
 return not S.no_floor
end)
static('KismetMathLibrary','MakeTransform',function(_,pos,rot,scale)return {offset=pos,rotation=rot,scale=scale}end)
static('KismetMathLibrary','TransformLocation',function(_,t,off)
 return {X=t.position.X+off.X,Y=t.position.Y+off.Y,Z=t.position.Z+off.Z}
end)
function StaticFindObject(p)api();return registry[p]end
function FindAllOf(k)api();assert(k=='HUDMainUMG_BP_C');return {S.hud}end
EObjectFlags={RF_Transient=64,RF_ClassDefaultObject=16,RF_ArchetypeObject=32}
FName=setmetatable({},{__call=function(_,s)return s end})
function StaticConstructObject(cl,p,name,flags)
 api();S.created=S.created+1
 local c=object(p.p..'.'..name,'/Script/Engine.PointLightComponent');S.comp=c
 c.owner=p;c.flags=flags;c.CreationMethod=0;c.Intensity=5000;c.bVisible=true;c.bAffectsWorld=true
 local setters={SetVisibility='bVisible',SetIntensity='Intensity',SetHiddenInGame='bHiddenInGame',SetMobility='Mobility',
 SetIntensityUnits='IntensityUnits',SetAttenuationRadius='AttenuationRadius',SetCastShadows='CastShadows',
 SetCastVolumetricShadow='bCastVolumetricShadow',SetVolumetricScatteringIntensity='VolumetricScatteringIntensity',
 SetIndirectLightingIntensity='IndirectLightingIntensity',SetSourceRadius='SourceRadius',SetSoftSourceRadius='SoftSourceRadius',SetSourceLength='SourceLength'}
 for method,field in pairs(setters)do c[method]=function(self,v)api();assert(self==S.comp);self[field]=v end end
 function c:SetLightColor(color,srgb)api();assert(srgb==true);self.color=color end
 function c:GetLightColor()api();return self.color end
 function c:SetLightingChannels(a,b,d)api();self.LightingChannels={bChannel0=a,bChannel1=b,bChannel2=d}end
 function c:K2_AttachToComponent(r,s,a,b,d,w)api();assert(a==0 and b==0 and d==0 and not w);self.parent=r;return not S.attach_fail end
 function c:GetAttachParent()api();return self.parent end
 function c:K2_GetComponentLocation()api();return {X=S.position.X+self.offset.X,Y=S.position.Y+self.offset.Y,Z=S.position.Z+self.offset.Z}end
 function c:K2_DestroyComponent(caller)api();assert(caller==self);self.live=false;S.destroyed=S.destroyed+1 end
 return c
end
function S.pawn:FinishAddComponent(c,manual,t)
 api();assert(manual and not c.bVisible and c.Intensity==0 and c.Mobility==2 and not c.CastShadows)
 assert(c.IntensityUnits==2 and c.AttenuationRadius==350)
 if S.finish_fail then error('injected finish failure')end
 c.offset=t.offset;S.registered=true
end
EGameThreadMethod={EngineTick=1};EngineTickAvailable=true;Key={F8=8,F7=7};ModifierKey={CONTROL=1,ALT=2}
function IsKeyBindRegistered()return S.collision or false end
function RegisterKeyBind(k,mods,fn)S.keys[k]=fn end
function ExecuteInGameThread(fn,m)assert(m==1);table.insert(S.queue,fn)end
local function action(fn)S.next=S.next+1;S.actions[S.next]={fn=fn,active=true};return S.next end
function ExecuteInGameThreadWithDelay(ms,fn)api();assert(ms==90000);S.timer=action(fn);return S.timer end
function LoopInGameThreadAfterFrames(n,fn)api();assert(n==30);S.monitor=action(fn);return S.monitor end
function CancelDelayedAction(h)api();local a=S.actions[h];if a and a.active then a.active=false;return true end;return false end
function IsValidDelayedActionHandle(h)api();return S.actions[h]and S.actions[h].active or false end
function flush()while #S.queue>0 do local f=table.remove(S.queue,1);S.game=true;f();S.game=false end end
function press(k)S.keys[k]();flush()end
function fire(h)S.game=true;S.actions[h].fn();S.game=false;flush()end
function contains(s)for _,line in ipairs(S.logs)do if line:find(s,1,true)then return true end end;return false end
'''
class ProbePolicy(unittest.TestCase):
    def case(self,code,setup=''):
        lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(FIXTURE+setup);lua.execute(SOURCE)
        try:lua.execute(code)
        except Exception:
            print(list(lua.globals().S.logs.values()));raise
    def test_dark_start_toggle_follow_and_native_death(self):
        self.case('press(8);assert(S.registered and S.created==1 and not S.comp.bVisible);press(8);assert(S.comp.Intensity==60);'
                  'S.position.X=S.position.X+75;press(8);assert(contains("root_moved_cm=75.000"));press(7);'
                  'assert(S.destroyed==1 and contains("native_valid=false") and contains("action_handles=0"));'
                  'press(8);fire(S.monitor);assert(S.created==1 and S.destroyed==1)')
    def test_timeout_stops_and_stale_callbacks_stay_inert(self):
        self.case('press(8);press(8);fire(S.timer);assert(S.destroyed==1 and contains("reason=timeout"));'
                  'fire(S.monitor);press(8);assert(S.created==1)')
    def test_pending_start_cancel_has_no_allocation(self):
        self.case('S.keys[8]();S.keys[7]();flush();assert(S.created==0 and contains("CLEANED"))')
    def test_skip_ui_and_retry_only_before_attempt(self):
        self.case('press(8);assert(S.created==0);S.ui=false;press(8);assert(S.created==1)', 'S.ui=true')
    def test_channel_union_affects_only_own_light(self):
        self.case('press(8);assert(S.comp.LightingChannels.bChannel0 and S.comp.LightingChannels.bChannel2);'
                  'assert(not S.mesh.LightingChannels.bChannel0 and not S.floor.LightingChannels.bChannel2);press(7)')
    def test_no_floor_means_no_allocation_or_retry(self):
        self.case('press(8);assert(S.created==0 and contains("FAILED"));S.no_floor=false;press(8);assert(S.created==0)', 'S.no_floor=true')
    def test_registration_failure_destroys_partial_component(self):
        self.case('press(8);assert(S.created==1 and S.destroyed==1 and contains("reason=failure"));press(8);assert(S.created==1)', 'S.finish_fail=true')
    def test_attachment_failure_destroys_registered_component(self):
        self.case('press(8);assert(S.registered and S.destroyed==1 and contains("CLEANED"))', 'S.attach_fail=true')
    def test_external_state_write_fails_closed(self):
        self.case('press(8);S.comp.Intensity=999;fire(S.monitor);assert(S.destroyed==1 and contains("FAILED"))')
    def test_key_conflict_never_arms(self):
        self.case('assert(contains("UNAVAILABLE") and S.created==0 and not S.keys[8])', 'S.collision=true')
if __name__=='__main__':unittest.main()
