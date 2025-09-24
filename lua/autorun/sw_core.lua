--
-- for lyt 2025 04 08
if SERVER then
    SimpWound = {}
end


if CLIENT then
    local modulename = 'simpwound'
    local version = '1.0.0'

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
    print('[SimpWound]: LUA VERSION ' .. version)

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


if SERVER then
    SimpWound = {}

    SimpWound.BindPose = function(ent)
        -- 改变布娃娃的动作为出厂状态
		if ent:IsRagdoll() then
			local temp = ents.Create('prop_ragdoll')
			temp:SetModel(ent:GetModel())
			temp:SetPos(ent:GetPos())
			temp:Spawn()
			
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local tempPhys = temp:GetPhysicsObjectNum(i)
				local phys = ent:GetPhysicsObjectNum(i)
				if IsValid(phys) then
					phys:EnableMotion(false)
					phys:SetPos(tempPhys:GetPos())
					phys:SetAngles(tempPhys:GetAngles())
					phys:Wake()
				end
			end

			temp:Remove()
		else
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
				phys:SetAngles(Angle())
				phys:Wake()
			end
		end
	end

	SimpWound.RecordPhys = function(ent, key, tbl)
        -- 逐骨骼记录位置
		local physdata = tbl or {}
		physdata[key] = {}

		if ent:IsRagdoll() then
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local phys = ent:GetPhysicsObjectNum(i)
				if IsValid(phys) then
					table.insert(
						physdata[key], 
						{
							phys = phys,
							pos = phys:GetPos(),
							ang = phys:GetAngles(),
							moveable = phys:IsMoveable(),
						}
					)
				end
			end
		else
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				table.insert(
					physdata[key], 
					{
						phys = phys,
						pos = phys:GetPos(),
						ang = phys:GetAngles(),
						moveable = phys:IsMoveable(),
					}
				)
			end
		end

		return physdata
	end

    SimpWound.PlayPhys = function(ent, key, tbl)
        -- 逐骨骼设置位置
		local physdata = tbl or {}

		if not istable(physdata[key]) then 
			return
		end
		
		for _, v in pairs(physdata[key]) do
			local phys = v.phys
			phys:SetPos(v.pos)
			phys:SetAngles(v.ang)
			phys:EnableMotion(v.moveable)
			phys:Wake()
		end
	end


end