--
-- for lyt 2025 04 08
if SERVER then
    SimpWound = {}
end


if CLIENT then
    local modulename = 'simpwound'

    if not util.IsBinaryModuleInstalled(modulename) then
        ErrorNoHalt(        
            string.format(
                '[SimpWound]: %s\n', 
                language.GetPhrase('sw.missmodule')
            )
        )

        return
    end

    local success, err = pcall(function() require(modulename) end)
    if not success then
        ErrorNoHalt(
            string.format(
                '[SimpWound]: %s\n', 
                err
            )    
        )
        return
    end

    SimpWound = {}

    local zerovec = Vector()
    local unitx = Vector(30, 0, 0)
    local unity = Vector(0, 30, 0)
    local unitz = Vector(0, 0, 30)

    SimpWound.DrawEllipsoid = function(transform, step)
        cam.PushModelMatrix(transform)
            render.DrawSphere(zerovec, 1, step, step)    
        cam.PopModelMatrix()
    end

    SimpWound.DrawCoordinate = function(transform)
        cam.PushModelMatrix(transform)
            render.DrawLine(zerovec, unitx, Color(255, 0, 0, 255), false)
            render.DrawLine(zerovec, unity, Color(0, 255, 0, 255), false)
            render.DrawLine(zerovec, unitz, Color(0, 0, 255, 255), false)   
        cam.PopModelMatrix()
    end

    local ellipsoid = Matrix()
    ellipsoid:SetTranslation(Vector(0, 10, 55))
    ellipsoid:SetScale(Vector(15, 10, 15))
    
    local wireframe = Material('models/wireframe')
    hook.Add('PostDrawOpaqueRenderables', 'test', function()
        render.SetMaterial(wireframe)
        SimpWound.DrawEllipsoid(ellipsoid, 16)
    end)

    
    local testmaterial = CreateMaterial(
        'simplewound_test', 
        'SimpWound'
    )
    testmaterial:SetTexture('$basetexture', 'models/breen/breen_sheet')
    testmaterial:SetTexture('$projectedtexture', 'models/flesh')
    testmaterial:SetTexture('$deformedtexture', 'models/flesh')
    testmaterial:SetMatrix('$woundtransform', ellipsoid)
    testmaterial:SetMatrix('$woundtransforminvert', ellipsoid:GetInverse())
    testmaterial:SetVector('$woundsize', Vector(1, 0.5, 1))

    testent = testent or ClientsideModel('models/Combine_Helicopter/helicopter_bomb01.mdl')
    testent:SetMaterial('!simplewound_test')

    concommand.Add('test', function(ply)
        local ent = ply:GetEyeTrace().Entity
        ent:SetMaterial('!simplewound_test')

        PrintTable(ent:GetMaterials())
    end)
end