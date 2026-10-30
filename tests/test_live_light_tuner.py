# SPDX-License-Identifier: MPL-2.0
"""Policy/orchestration tests. Engine mocks are not UMG/shadow/runtime proof."""
import os,pathlib,sys,tempfile,unittest
if os.environ.get('HSL_TEST_LIBRARIES'):sys.path.insert(0,os.environ['HSL_TEST_LIBRARIES'])
from lupa.lua54 import LuaRuntime
ROOT=pathlib.Path(__file__).resolve().parents[1]
SRC=ROOT/'research/live-light-tuner/Scripts'
if not SRC.exists():SRC=pathlib.Path(__file__).parent
sys.path.insert(0,os.environ.get('HSL_BASE_TESTS',str(ROOT/'tests')))
from test_pointlight_runtime import FIXTURE
MAIN=(SRC/'main.lua').read_text(encoding='utf-8');MODEL=(SRC/'TunerModel.lua').read_text(encoding='utf-8')
EXTRA=r'''
function add_native(module,lib,method,fn)
 local class='/Script/'..module..'.'..lib
 local c={IsValid=function()assert(S.game);return true end,GetFullName=function()return 'Class '..class end}
 local cdo={IsValid=c.IsValid,GetClass=function()return c end}
 REG[class]=c;REG['/Script/'..module..'.Default__'..lib]=cdo
 local p=class..':'..method
 local f={IsValid=c.IsValid,type=function()return'UFunction'end,GetFullName=function()return'Function '..p end}
 setmetatable(f,{__call=function(_,...)assert(S.game);return fn(...)end});REG[p]=f
end
S.clock=1000;S.current_queries=0
function LoadAsset()error('mock UI must not load real assets')end
local function frameobject(p,k,id)
 local c={GetFullName=function()return'Class '..k end}
 local o={p=p,live=true,IsValid=function()assert(S.game);return true end,GetFullName=function()return k..' '..p end,
  GetAddress=function()return id end,GetClass=function()return c end,HasAnyFlags=function()return false end}
 REG[p]=o;return o
end
S.world=frameobject('/World.Main','/Script/Engine.World',9010)
S.viewport=frameobject('/Engine.Viewport','/Script/Engine.GameViewportClient',9011);S.viewport.World=S.world
S.engine=frameobject('/Engine.Main','/Script/Engine.GameEngine',9012);S.engine.GameViewport=S.viewport
function S.pawn:GetWorld()assert(S.game);return S.world end
local base_find=FindAllOf
function FindAllOf(k)if k=='GameEngine'then return {S.engine}end;return base_find(k)end
add_native('Genesis','GameGlobal','GetInputMode',function()return S.menu and 1 or 0 end)
add_native('Genesis','GameGlobal','GetKeyByVirtualKey',function()
 S.current_queries=S.current_queries+1;return {KeyName={ToString=function()return S.mapping_collision or 'F'end}}
end)
add_native('Engine','GameplayStatics','GetRealTimeSeconds',function()return S.clock end)
add_native('Engine','KismetSystemLibrary','GetConsoleVariableIntValue',function(_,name)return S.shadow_block and 0 or 1 end)
S.mesh.CastShadow=true;S.mesh.bCastDynamicShadow=true
local base_construct=StaticConstructObject
function StaticConstructObject(...)
 local c=base_construct(...)
 function c:SetUseTemperature(v)assert(S.game);self.bUseTemperature=v end
 function c:SetTemperature(v)assert(S.game);self.Temperature=v end
 function c:K2_SetRelativeLocation(v,sweep,hit,teleport)assert(S.game and not sweep and teleport);self.RelativeLocation=v;self.offset=v end
 return c
end
local finish=S.pawn.FinishAddComponent
function S.pawn:FinishAddComponent(c,manual,t)
 if S.fail_second and S.created==2 then error('second register failure')end
 finish(self,c,manual,t);c.RelativeLocation=t.offset
end
local U={}
function U.bind(a)U.api=a end
function U.pending()return S.ui_exists or false end
function U.create(h,text)assert(S.game);S.ui_exists=true;S.ui_visible=true;S.ui_text=text;if S.ui_fail then error('UI failure')end end
function U.show(v)assert(S.game);S.ui_visible=v end
function U.text(v)assert(S.game);S.ui_text=v end
function U.cleanup()assert(S.game);S.ui_exists=false;S.ui_visible=false end
package.preload.TunerUI=function()return U end
Key={NUM_ZERO=100,NUM_ONE=101,NUM_TWO=102,NUM_THREE=103,NUM_FOUR=104,NUM_FIVE=105,
 NUM_SIX=106,NUM_SEVEN=107,NUM_EIGHT=108,NUM_NINE=109,MULTIPLY=110}
function frame()S.clock=S.clock+1/60;fire(S.monitor)end
'''
class ModelPolicy(unittest.TestCase):
    def setUp(self):
        self.l=LuaRuntime(unpack_returned_tuples=True);self.l.execute('M=assert(load(...))()',MODEL)
    def test_bounds_and_independent_steps(self):
        self.l.execute('s=M.new();M.adjust(s,1);assert(s.lights[1].lm==4.1 and s.lights[2].lm==2);'
                       's.coarse=true;M.adjust(s,-1);assert(s.lights[1].lm==3.1);'
                       'for i=1,100 do M.adjust(s,1)end;assert(s.lights[1].lm==30);'
                       'for i=1,100 do M.adjust(s,-1)end;assert(s.lights[1].lm==0)')
    def test_settings_roundtrip_and_corruption(self):
        self.l.execute('s=M.new();s.lights[2].on=true;s.lights[1].shadow=true;t=M.serialize(s);'
                       'r=M.parse(t);assert(r.lights[2].on and r.lights[1].shadow);'
                       'assert(not pcall(M.parse,t.."2.shadow=1\\n"));'
                       'assert(not pcall(M.parse,t:gsub("1.lm=4.00","1.lm=999")));'
                       'assert(not pcall(M.parse,"return os.execute(1)"))')
    def test_frame_measurement_settle_and_comparison(self):
        self.l.execute('s=M.new();M.resetPerf(s,0,true);for i=1,180 do M.sample(s,i/60)end;'
                       'assert(math.abs(s.results.OFF.ms-1000/60)<0.01);'
                       's.lights[1].shadow=true;M.resetPerf(s,3,false);'
                       'for i=1,120 do M.sample(s,3+i/30)end;assert(s.results.OFF and math.abs(s.results.ON.fps-30)<0.01);'
                       'M.resetPerf(s,8,true);assert(not s.results.ON and not s.results.OFF)')
class Orchestration(unittest.TestCase):
    def case(self,code,setup=''):
        temp_root=ROOT/'.local/live-light-tuner/test-temp';temp_root.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(dir=temp_root)as temp:
            d=pathlib.Path(temp)/'HildaSoftLightLiveTuner';(d/'Scripts').mkdir(parents=True)
            assert pathlib.Path(temp).resolve().is_relative_to(temp_root.resolve())
            l=LuaRuntime(unpack_returned_tuples=True)
            base=FIXTURE.replace('local registry={}','REG={};local registry=REG').replace('assert(self==S.comp);','')
            base=base.replace('c.AttenuationRadius==350','(c.AttenuationRadius==200 or c.AttenuationRadius==150)').replace('n==30','n==1')
            l.execute(base+EXTRA)
            l.execute('local src=...;package.preload.TunerModel=function()return assert(load(src))()end',MODEL)
            l.execute('local src=...;package.preload.KeyboardBindings=function()return assert(load(src))()end',(SRC/'KeyboardBindings.lua').read_text())
            l.execute(setup)
            l.execute('local s,n=...;assert(load(s,n))()',MAIN,'@'+str(d/'Scripts/main.lua'))
            try:l.execute(code)
            except Exception:
                print(list(l.globals().S.logs.values()));raise
            return d.joinpath('tuner-settings.ini').read_text()if(d/'tuner-settings.ini').exists()else None
    def test_two_lights_start_independence_close_and_stop(self):
        self.case('press(100);assert(S.created==2 and S.ui_visible and S.current_queries==50);'
                  'press(107);press(101);assert(S.comp.bVisible and S.comp.Intensity==2);'
                  'press(106);assert(S.comp.Intensity==2.1 and S.created==2);'
                  'press(100);local before=S.comp.Intensity;press(106);assert(S.comp.Intensity==before and not S.ui_visible);'
                  'press(110);assert(S.destroyed==2 and not S.ui_exists and contains("action_handles=0"));'
                  'press(100);fire(S.monitor);assert(S.created==2)')
    def test_explicit_save_only(self):
        self.assertIsNone(self.case('press(100);press(110)'))
        saved=self.case('press(100);press(109);assert(contains("SAVED"));press(110)')
        self.assertIn('schema=1',saved)
    def test_second_registration_failure_cleans_both_and_ui(self):
        self.case('press(100);assert(S.created==2 and S.destroyed==2 and not S.ui_exists and contains("CLEANED"))','S.fail_second=true')
    def test_ui_failure_before_lights_releases_host(self):
        self.case('press(100);assert(S.created==0 and not S.ui_exists and contains("CLEANED"))','S.ui_fail=true')
    def test_current_binding_conflict_prevents_any_effect(self):
        self.case('press(100);assert(S.created==0 and not S.ui_exists and contains("game key collision"))','S.mapping_collision="NumPadSix"')
    def test_ue4ss_conflict_disarms(self):
        self.case('assert(contains("UNAVAILABLE") and not S.keys[100])','S.collision=true')
    def test_shadow_gate_does_not_change_game_setting(self):
        self.case('press(100);press(103);assert(contains("SHADOW_CAPS") and not contains("event=SHADOW "));press(110)','S.shadow_block=true')
    def test_shadow_toggle_and_timing_no_reallocation(self):
        self.case('press(100);for i=1,180 do frame()end;assert(S.ui_text:find("engine fps"));'
                  'press(103);assert(contains("event=SHADOW front=true"));for i=1,120 do frame()end;'
                  'assert(S.created==2);press(110)')
    def test_pending_start_cancel_and_pawn_loss(self):
        self.case('S.keys[100]();S.keys[110]();flush();assert(S.created==0)')
        self.case('press(100);S.pawn.live=false;frame();assert(S.destroyed==2 and not S.ui_exists)')
    def test_viewport_world_change_stops_without_rebind(self):
        self.case('press(100);S.viewport.World=nil;frame();assert(S.destroyed==2 and not S.ui_exists);press(100);assert(S.created==2)')
if __name__=='__main__':unittest.main()
