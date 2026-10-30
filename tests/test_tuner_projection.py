# SPDX-License-Identifier: MPL-2.0
"""Numeric adapter checks; not proof of native UMG/UE4SS execution."""
import os,pathlib,sys,unittest
if os.environ.get('HSL_TEST_LIBRARIES'):sys.path.insert(0,os.environ['HSL_TEST_LIBRARIES'])
from lupa.lua54 import LuaRuntime
ROOT=pathlib.Path(__file__).resolve().parents[1]
SOURCE=(ROOT/'research/live-light-tuner/Scripts/TunerProjection.lua').read_text(encoding='utf-8')
FIXTURE=r'''
S={scale=1.5,size={X=1920,Y=1080},checks=0,raw_calls=0}
controller={ProjectWorldLocationToScreen=function(self,w,out,relative)
 assert(self==controller and relative==false);S.raw_calls=S.raw_calls+1;out.X=w.X;out.Y=w.Y;return true
end}
P.bind({static=function(lib,method,c,w,out,relative)
 assert(lib=='WidgetLayoutLibrary'and c==controller)
 if method=='GetViewportSize'then return S.size end
 if method=='GetViewportScale'then return S.scale end
 assert(method=='ProjectWorldLocationToWidgetPosition'and type(out)=='table'and relative==false)
 if S.bad_bool then return 1 end
 if S.bad_out then out.X='bad';return true end
 out.X=w.X/S.scale+(S.mismatch and 10 or 0);out.Y=w.Y/S.scale
 return w.Z>=0
end,projectionChecked=function(size,scale,raw,out)S.checks=S.checks+1;S.last=out end})
'''
class ProjectionContract(unittest.TestCase):
    def case(self,code):
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute('P=assert(load(...))()',SOURCE);lua.execute(FIXTURE);lua.execute(code)
    def test_all_payload_lua_parses_without_execution(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        for path in (ROOT/'research/live-light-tuner/Scripts').glob('*.lua'):
            with self.subTest(path=path.name):lua.execute('assert(load(...))',path.read_text(encoding='utf-8'))
    def test_dpi_once_numeric_out_and_resize_validation(self):
        self.case('p,d=P.project(controller,{{X=960,Y=540,Z=1}});assert(d.X==1280 and d.Y==720 and p[1].X==640 and p[1].Y==360);'
                  'P.project(controller,{{X=960,Y=540,Z=1}});assert(S.checks==1 and S.raw_calls==1);'
                  'S.scale=2;p,d=P.project(controller,{{X=960,Y=540,Z=1}});assert(p[1].X==480 and d.X==960 and S.checks==2)')
    def test_behind_offscreen_and_minimized_hide(self):
        self.case('p,d=P.project(controller,{{X=960,Y=540,Z=-1},{X=3000,Y=540,Z=1}});assert(not p[1]and not p[2]);'
                  'S.size={X=0,Y=0};p,d=P.project(controller,{{X=960,Y=540,Z=1}});assert(not next(p)and d==nil)')
    def test_bad_api_shapes_and_scaling_are_rejected(self):
        for setup in ['S.bad_bool=true','S.bad_out=true','S.scale=0','S.mismatch=true','S.scale=0/0']:
            with self.subTest(setup=setup):
                self.case(setup+';assert(not pcall(P.project,controller,{{X=960,Y=540,Z=1}}))')
if __name__=='__main__':unittest.main()
