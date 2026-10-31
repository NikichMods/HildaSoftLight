# SPDX-License-Identifier: MPL-2.0
"""State/lifecycle containment under Lua5.4, not native runtime acceptance."""
import os,pathlib,sys,tempfile,unittest
if os.environ.get('HSL_TEST_LIBRARIES'):sys.path.insert(0,os.environ['HSL_TEST_LIBRARIES'])
from lupa.lua54 import LuaRuntime
from test_pointlight_runtime import FIXTURE
from test_live_light_tuner import EXTRA
ROOT=pathlib.Path(__file__).resolve().parents[1]
MAIN=(ROOT/'Scripts/main.lua').read_text(encoding='utf-8')
PROFILE=(ROOT/'Scripts/Profile.lua').read_text(encoding='utf-8')
DEFAULT=(ROOT/'DefaultProfile.ini').read_text(encoding='utf-8')
PRODUCTION_EXTRA=r'''
S.hp=100;S.ui_creates=0;S.cancel_count=0
add_native('Genesis','GameGlobal','GetHP',function(_,p)assert(p==S.pawn);return S.hp end)
local previous_find=FindAllOf
function FindAllOf(k)if k=='HUDMainUMG_BP_C'and S.no_hud then return{}end;return previous_find(k)end
local previous_cancel=CancelDelayedAction
function CancelDelayedAction(h)
 S.cancel_count=S.cancel_count+1
 if S.check_cancel_order then assert(S.destroyed==S.created,'cleanup must precede cancellation')end
 return previous_cancel(h)
end
function advance(n)for i=1,n do frame()end end
function replace_pawn()
 local old=S.pawn
 S.pawn=fixture_object('/World.NextHilda','/Game/MainContent/Act/Character_BP/hilda_BP.hilda_BP_C')
 S.root=fixture_object('/World.NextHilda.Root','/Script/Engine.SceneComponent')
 S.mesh=fixture_object('/World.NextHilda.Mesh','/Script/Engine.SkeletalMeshComponent');S.mesh.owner=S.pawn
 S.mesh.LightingChannels={bChannel0=true,bChannel1=true,bChannel2=false};S.pawn.Mesh=S.mesh
 S.mesh.CastShadow=true;S.mesh.bCastDynamicShadow=true
 function S.pawn:GetWorld()return S.world end
 function S.pawn:K2_GetRootComponent()return S.root end
 function S.root:K2_GetComponentLocation()return S.position end
 S.pawn.FinishAddComponent=old.FinishAddComponent
end
'''
class ProductionLifecycle(unittest.TestCase):
    def case(self,code,setup='',files=None):
        temp_root=ROOT/'.local/production/test-temp';temp_root.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(dir=temp_root)as folder:
            assert pathlib.Path(folder).resolve().is_relative_to(temp_root.resolve())
            d=pathlib.Path(folder)/'HildaSoftLight';(d/'Scripts').mkdir(parents=True)
            (d/'DefaultProfile.ini').write_bytes(DEFAULT.encode('utf-8'))
            for name,value in(files or{}).items():(d/name).write_bytes(value.encode('utf-8'))
            lua=LuaRuntime(unpack_returned_tuples=True)
            base=FIXTURE.replace('local registry={}','REG={};local registry=REG').replace('assert(self==S.comp);','')
            base=base.replace('object(','fixture_object(').replace('local function fixture_object','function fixture_object')
            base=base.replace('c.IntensityUnits==2','c.IntensityUnits==0').replace('c.AttenuationRadius==350','c.AttenuationRadius>0')
            extra=EXTRA.replace('package.preload.TunerUI','package.preload.EditorView')
            extra=extra.replace('function U.create(h,text)assert(S.game);','function U.create(h,text)assert(S.game);S.ui_creates=S.ui_creates+1;')
            extra=extra.replace('function U.cleanup()assert(S.game);','function U.cleanup()if S.ui_exists then assert(S.game)end;')
            lua.execute(base+extra+PRODUCTION_EXTRA)
            lua.execute('local src=...;package.preload.Profile=function()return assert(load(src))()end',PROFILE)
            lua.execute('local src=...;package.preload.KeyboardBindings=function()return assert(load(src))()end',(ROOT/'Scripts/KeyboardBindings.lua').read_text())
            lua.execute(setup)
            lua.execute('local s,p=...;assert(load(s,p))()',MAIN,'@'+str(d/'Scripts/main.lua'))
            try:lua.execute(code)
            except Exception:
                print(list(lua.globals().S.logs.values()));raise
            return (d/'settings-unitless-v2.ini').read_text()if(d/'settings-unitless-v2.ini').exists()else None
    def test_payload_syntax_and_approved_profile_identity(self):
        import hashlib
        lua=LuaRuntime(unpack_returned_tuples=True)
        for path in (ROOT/'Scripts').glob('*.lua'):lua.execute('assert(load(...))',path.read_text(encoding='utf-8'))
        assert hashlib.sha256((ROOT/'DefaultProfile.ini').read_bytes()).hexdigest()=='70bd93107584767a3993524bb003d4d7b28cd92867b54364c855bfda109420ea'
        lua.execute('local text,code=...;local p=assert(load(code))();assert(p.serialize(p.parse(text))==text)',DEFAULT,PROFILE)
    def test_automatic_approved_profile_without_ui_or_key_audit(self):
        result=self.case('frame();assert(S.created==3 and S.ui_creates==0 and S.current_queries==0);'
                         'assert(S.components[1].Intensity==0.15 and S.components[1].CastShadows);'
                         'assert(S.components[2].Intensity==0.10 and S.components[3].Intensity==0.15);'
                         'advance(180);assert(S.created==3 and S.ui_creates==0 and S.cancel_count==0)')
        self.assertIsNone(result)
    def test_absent_menu_dead_root_world_wait_then_bind(self):
        for setup,release in [('S.no_hud=true','S.no_hud=false'),('S.menu=true','S.menu=false'),('S.hp=0','S.hp=100'),('S.root.live=false','S.root.live=true'),('S.viewport.World=nil','S.viewport.World=S.world')]:
            with self.subTest(setup=setup):
                self.case('advance(60);assert(S.created==0);'+release+';advance(30);assert(S.created==3 and S.ui_creates==0)',setup)
    def test_load_rebind_without_extra_handles_or_duplicate_names(self):
        self.case('frame();S.viewport.World=nil;advance(15);assert(S.destroyed==3 and not S.ui_exists);'
                  'S.viewport.World=S.world;advance(30);assert(S.created==6 and S.next==1 and S.cancel_count==0);'
                  'assert(S.components[1].p~=S.components[4].p);advance(120);assert(S.created==6)')
    def test_health_zero_then_same_pawn_and_replacement(self):
        self.case('frame();S.hp=0;advance(15);assert(S.destroyed==3);advance(60);assert(S.created==3);'
                  'S.hp=100;advance(30);assert(S.created==6);replace_pawn();advance(45);'
                  'assert(S.destroyed==6 and S.created==9 and S.next==1)')
    def test_editor_lazy_open_close_live_no_duplicate_lights(self):
        self.case('frame();press(111);assert(S.ui_exists and S.ui_creates==1 and S.current_queries==50);'
                  'press(106);assert(S.components[1].Intensity==0.2);press(111);assert(not S.ui_exists and S.destroyed==0);'
                  'press(106);assert(S.components[1].Intensity==0.2);press(111);assert(S.ui_creates==2 and S.created==3)')
    def test_editor_failure_conflict_and_marker_failure_preserve_lights(self):
        for setup in ['S.ui_fail=true','S.collision=true','S.mapping_collision="Divide"']:
            with self.subTest(setup=setup):
                self.case('frame();press(111);advance(60);assert(S.created==3 and S.destroyed==0 and not S.ui_exists and contains("UI_UNAVAILABLE"))',setup)
        self.case('frame();press(111);assert(contains("MARKERS_UNAVAILABLE") and S.destroyed==0);advance(60);assert(S.created==3)','S.marker_fail=true')
    def test_pause_does_not_autorestart_f10_restores(self):
        self.case('frame();press(111);press(110);assert(S.destroyed==3 and not S.ui_exists);'
                  'advance(120);assert(S.created==3 and S.next==1);press(111);advance(30);'
                  'assert(S.created==6 and S.ui_exists and S.next==1 and S.cancel_count==0)')
    def test_save_restart_profile_and_invalid_profile_preserved(self):
        saved=self.case('frame();press(111);press(106);press(109);assert(contains("event=SAVED"))')
        self.assertIn('1.intensity=0.20',saved)
        self.case('frame();assert(S.components[1].Intensity==0.2)',files={'settings-unitless-v2.ini':saved})
        invalid='# HildaSoftLightLiveTuner settings schema=1\n1.lm=60\n'
        result=self.case('frame();assert(S.components[1].Intensity==0.15 and contains("SETTINGS_REJECTED"))',files={'settings-unitless-v2.ini':invalid})
        self.assertEqual(result,invalid)
    def test_partial_third_failure_cleans_then_cancels_late_callbacks_inert(self):
        self.case('frame();assert(S.created==3 and S.destroyed==3 and S.cancel_count==1);'
                  'advance(90);press(111);assert(S.created==3 and S.cancel_count==1 and contains("CORE_DISABLED"))','S.fail_third=true;S.check_cancel_order=true')
    def test_failed_native_cleanup_never_rebinds(self):
        self.case('frame();S.components[1].K2_DestroyComponent=function(self)error("cannot destroy")end;'
                  'S.hp=0;advance(15);local n=S.created;advance(120);assert(S.created==n and contains("CLEANUP_PENDING"))')
    def test_no_stale_world_ui_and_scene_menu_no_edits(self):
        self.case('frame();press(111);S.menu=true;advance(15);assert(not S.ui_exists and S.destroyed==0);'
                  'S.menu=false;press(111);S.world.live=false;frame();assert(not S.ui_exists and S.destroyed==3);'
                  'advance(120);assert(S.created==3)')
    def test_held_key_across_editor_entry_and_resume_is_not_deferred(self):
        self.case('frame();S.held={NumPadSix=true};frame();'
                  'S.held={LeftControl=true,LeftAlt=true,F10=true,NumPadSix=true};frame();'
                  'S.held={NumPadSix=true};frame();assert(S.components[1].Intensity==0.15);'
                  'S.held={};frame();press(110);advance(30);'
                  'S.held={LeftControl=true,LeftAlt=true,F10=true,NumPadSix=true};frame();'
                  'S.held={NumPadSix=true};advance(30);assert(S.components[4].Intensity==0.15);'
                  'S.held={};frame();press(106);assert(S.components[4].Intensity==0.2)')
    def test_failed_cancel_is_inert_and_missing_api_fails_before_effects(self):
        self.case('frame();assert(S.actions[S.monitor].active and S.cancel_count==1);advance(60);'
                  'assert(S.created==3 and S.destroyed==3)',
                  'S.fail_third=true;function CancelDelayedAction(h)S.cancel_count=S.cancel_count+1;return false end')
        self.case('assert(not S.monitor and S.created==0 and contains("CORE_DISABLED"))','LoopInGameThreadAfterFrames=nil')
    def test_shadow_comparison_preserves_other_window(self):
        self.case('frame();press(111);advance(180);press(103);advance(180);'
                  'assert(not S.ui_text:find("collecting engine frames",1,true) and S.created==3)')
if __name__=='__main__':unittest.main()
