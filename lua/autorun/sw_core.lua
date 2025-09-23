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
end