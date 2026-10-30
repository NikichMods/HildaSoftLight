-- SPDX-License-Identifier: MPL-2.0
-- Independent R-017 viewport host plus one owned label. No gameplay HUD writes.
local Projection=require("TunerProjection")
local U={};local A;local host,tree,root,label
local markers={};local viewport_size
local CLASS="/Game/MainContent/Template/UMG/Debug/PostionItemUMG_BP.PostionItemUMG_BP_C"
function U.bind(api)A=api;Projection.bind(api)end
function U.pending()return host~=nil end
function U.create(h,text)
    assert(not host,"one UI allocation only")
    local c=StaticFindObject(CLASS)
    if not A.alive(c)then
        local loaded,found,did=A.step("ui_load",LoadAsset,CLASS)
        assert(found==true and did==true and A.alive(loaded),"UI exact load failed")
        c=StaticFindObject(CLASS);assert(A.same(c,loaded),"UI class load identity changed")
    end
    assert(c:type()=="UClass"and A.path(c)==CLASS and A.path(c:GetSuperStruct())=="/Script/UMG.UserWidget","unexpected UI class")
    h=A.context() -- Exact target revalidation after any synchronous class loading.
    local w=A.step("ui_create",A.static,"WidgetBlueprintLibrary","Create",h,c,nil)
    assert(A.alive(w)and A.cls(w)==CLASS and not A.same(w,h)
        and not w:HasAnyFlags(EObjectFlags.RF_ClassDefaultObject|EObjectFlags.RF_ArchetypeObject),"non-new UI host")
    host=A.ref(w)
    local t=w.WidgetTree;local r=t.RootWidget
    assert(A.alive(t)and A.cls(t)=="/Script/UMG.WidgetTree"and A.same(t:GetOuter(),w)
        and A.alive(r)and A.cls(r)=="/Script/UMG.CanvasPanel"and A.same(r:GetOuter(),t)
        and not A.valid(r:GetParent())and r:GetChildrenCount()==1,"private UI root mismatch")
    tree,root=A.ref(t),A.ref(r)
    local main=r:GetChildAt(0);local value,image=w.Value_Text,w.Bg_Image
    assert(A.alive(main)and A.cls(main)=="/Script/UMG.CanvasPanel"and main:GetChildrenCount()==2
        and A.same(main:GetOuter(),t)and A.same(main:GetParent(),r),"private placeholder mismatch")
    assert(A.alive(value)and A.cls(value)=="/Script/UMG.TextBlock"and A.alive(image)
        and A.cls(image)=="/Script/UMG.Image","private leaves missing")
    for _,o in ipairs({value,image})do
        assert(A.same(o:GetOuter(),t)and A.same(o:GetParent(),main)
            and A.same(o.Slot.Parent,main)and A.same(o.Slot.Content,o),"private UI leaf ownership")
    end
    assert(t:GetAddress()~=h.WidgetTree:GetAddress()and r:GetAddress()~=h.WidgetTree.RootWidget:GetAddress(),"game HUD alias")
    main:SetVisibility(1)
    local tc=StaticFindObject("/Script/UMG.TextBlock")
    assert(A.alive(tc)and tc:type()=="UClass","TextBlock class missing")
    local l=A.step("ui_label",StaticConstructObject,tc,t,FName("HSL_TunerLabel_"..os.time()),EObjectFlags.RF_Transient)
    assert(A.alive(l)and A.cls(l)=="/Script/UMG.TextBlock"and A.same(l:GetOuter(),t),"own label allocation failed")
    label=A.ref(l)
    l:SetVisibility(3);l:SetFont(value.Font)
    assert(l.Font:GetStructAddress()~=value.Font:GetStructAddress(),"private font-info alias")
    l.Font.Size=18;l:SetFont(l.Font);l:SetJustification(0);l:SetText(FText(text))
    local slot=r:AddChildToCanvas(l)
    assert(A.same(slot.Parent,r)and A.same(slot.Content,l),"own label slot mismatch")
    slot:SetAutoSize(false);slot:SetAnchors({Minimum={X=0,Y=0},Maximum={X=0,Y=0}})
    slot:SetAlignment({X=0,Y=0});slot:SetPosition({X=24,Y=120});slot:SetSize({X=560,Y=500})
    w:SetDesiredSizeInViewport({X=600,Y=640});w:SetAnchorsInViewport({Minimum={X=0,Y=0},Maximum={X=0,Y=0}})
    w:SetAlignmentInViewport({X=0,Y=0});w:SetPositionInViewport({X=0,Y=0},false)
    A.step("ui_viewport",function()w:AddToViewport(100)end)
    assert(w:IsInViewport()and w.Visibility==2,"expected first Construct Hidden")
    w:SetVisibility(3)
    assert(w.Visibility==3 and l.Text:ToString()==text,"UI show/text mismatch")
end
function U.show(on)
    local w=A.find(host);assert(A.alive(w)and w:IsInViewport(),"own viewport host lost")
    w:SetVisibility(on and 3 or 1)
    U.hideMarkers()
end
function U.text(text)
    local w,l=A.find(host),A.find(label)
    assert(A.alive(w)and w:IsInViewport()and A.alive(l)and A.same(l:GetOuter(),A.find(tree)),"own UI identity lost")
    l:SetText(FText(text));assert(l.Text:ToString()==text,"UI text readback")
end
local colors={{R=1,G=0.25,B=0.2,A=1},{R=0.1,G=0.8,B=1,A=1},{R=1,G=0.85,B=0.15,A=1}}
local names={"F","B","E"}
function U.hideMarkers()
    for _,entry in pairs(markers)do local l=A.find(entry.widget);if A.alive(l)then l:SetVisibility(1)end end
end
function U.markers(controller,points)
    local projected,dims=Projection.project(controller,points)
    if not dims then U.hideMarkers();return end
    local w,t,r=A.find(host),A.find(tree),A.find(root)
    assert(A.alive(w)and w:IsInViewport()and A.alive(t)and A.alive(r),"own marker UI lost")
    if not viewport_size or viewport_size.X~=dims.X or viewport_size.Y~=dims.Y then
        w:SetDesiredSizeInViewport(dims);viewport_size=dims
    end
    for i=1,3 do
        if not markers[i]then
            local c=StaticFindObject("/Script/UMG.TextBlock");assert(A.alive(c)and c:type()=="UClass","marker class lost")
            local l=StaticConstructObject(c,t,FName("HSL_Marker_"..i.."_"..os.time()),EObjectFlags.RF_Transient)
            assert(A.alive(l)and A.cls(l)=="/Script/UMG.TextBlock"and A.same(l:GetOuter(),t),"own marker allocation failed")
            markers[i]={widget=A.ref(l)};l:SetVisibility(1)
            local donor=A.find(label);l:SetFont(donor.Font);l:SetJustification(1);l:SetText(FText(names[i]))
            l:SetColorAndOpacity({SpecifiedColor=colors[i],ColorUseRule=0})
            local slot=r:AddChildToCanvas(l);markers[i].slot=A.ref(slot)
            assert(A.same(slot.Parent,r)and A.same(slot.Content,l),"own marker slot mismatch")
            slot:SetAutoSize(false);slot:SetAnchors({Minimum={X=0,Y=0},Maximum={X=0,Y=0}})
            slot:SetAlignment({X=0.5,Y=0.5});slot:SetSize({X=24,Y=24});slot:SetZOrder(1)
        end
        local l,slot=A.find(markers[i].widget),A.find(markers[i].slot)
        assert(A.alive(l)and A.alive(slot)and A.same(l:GetOuter(),t)and A.same(l:GetParent(),r)
            and A.same(slot.Content,l)and A.same(slot.Parent,r),"own marker identity changed")
        if projected[i]then
            slot:SetPosition(projected[i]);l:SetVisibility(3)
            local actual=slot:GetPosition()
            assert(math.abs(actual.X-projected[i].X)<0.02 and math.abs(actual.Y-projected[i].Y)<0.02,"marker slot position mismatch")
        else l:SetVisibility(1)end
    end
end
function U.cleanup()
    local w=A.find(host)
    if A.alive(w)then
        w:SetVisibility(1)
        for _,entry in pairs(markers)do
            local mark=A.find(entry.widget)
            if A.alive(mark)then
                mark:SetVisibility(1);local p=mark:GetParent()
                if A.valid(p)then assert(A.same(p,A.find(root)),"own marker reparented");assert(p:RemoveChild(mark),"marker detach")end
            end
        end
        local l=A.find(label)
        if A.alive(l)then local p=l:GetParent()
            if A.valid(p)then assert(A.same(p,A.find(root)),"own label reparented");assert(p:RemoveChild(l),"label detach")end
        end
        A.step("ui_release",function()w:RemoveFromParent()end)
        assert(not w:IsInViewport()and not A.valid(w:GetParent()),"UI release pending")
    end
    host,tree,root,label=nil,nil,nil,nil;markers={};viewport_size=nil
end
return U
