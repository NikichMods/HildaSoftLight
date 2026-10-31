-- SPDX-License-Identifier: MPL-2.0
-- Numeric native out tables only; no opaque FGeometry round-trip through Lua.
local P={};local A;local checked
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
local function vector(v)return type(v)=="table"and finite(v.X)and finite(v.Y)end
function P.bind(api)A=api;checked=nil end
function P.project(controller,points)
    local size=A.static("WidgetLayoutLibrary","GetViewportSize",controller)
    local scale=A.static("WidgetLayoutLibrary","GetViewportScale",controller)
    assert(vector(size)and finite(scale)and scale>0,"marker viewport/DPI shape")
    if size.X<=0 or size.Y<=0 then return {},nil end -- minimized/unavailable viewport
    local dims={X=size.X/scale,Y=size.Y/scale}
    local signature=table.concat({size.X,size.Y,scale},"/")
    local result={}
    for i,world in ipairs(points)do
        assert(vector(world)and finite(world.Z),"marker world transform shape")
        local out={}
        local projected=A.static("WidgetLayoutLibrary","ProjectWorldLocationToWidgetPosition",controller,world,out,false)
        assert(type(projected)=="boolean","marker projection bool shape")
        if projected then
            assert(vector(out),"marker FVector2D out shape")
            if checked~=signature then
                local raw={};assert(controller:ProjectWorldLocationToScreen(world,raw,false)==true and vector(raw),"marker raw projection mismatch")
                assert(math.abs(out.X-math.floor(raw.X+0.5)/scale)<2 and math.abs(out.Y-math.floor(raw.Y+0.5)/scale)<2,"marker DPI/viewport coordinates mismatch")
                checked=signature
                A.projectionChecked(size,scale,raw,out)
            end
            if out.X>=0 and out.Y>=0 and out.X<=dims.X and out.Y<=dims.Y then result[i]={X=out.X,Y=out.Y}end
        end -- false: behind camera / unavailable view; ignore any out values
    end
    return result,dims
end
return P
