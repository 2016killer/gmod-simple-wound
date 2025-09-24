--
-- for lyt 2025 04 08, 心急强吃热豆腐
if SERVER then
    SimpWound = {}
end


if CLIENT then
    local modulename = 'simpwound'
    local version = '1.0.0'

    if not util.IsBinaryModuleInstalled(modulename) then
        ErrorNoHalt(string.format('[SimpWound]: %s\n', language.GetPhrase('sw.missmodule')))
        return
    end

    local success, err = pcall(function() require(modulename) end)
    if not success then
        ErrorNoHalt(string.format('[SimpWound]: %s\n', err))
        return
    end

    SimpWound = {}
    print('[SimpWound]: LUA VERSION ' .. version)

    SimpWound.MaterialsCache = SimpWound.MaterialsCache or {}

    local zerovec = Vector()
    local unitx = Vector(1, 0, 0)
    local unity = Vector(0, 1, 0)
    local unitz = Vector(0, 0, 1)

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


	SimpWound.SWShaders = {
		['SimpWound'] = {},
		['SimpWoundVertexLit'] = {},
		['EllipClip'] = {},
		['EllipClipVertexLit'] = {},
		['DepthTexClip'] = {},
		['DepthTexClipVertexLit'] = {},
	}

    SimpWound.PrintSWParams = function(ent)
		-- 打印实体的伤口材质参数
        print(ent:GetModel())
        PrintTable(ent.sw_params)
    end

    net.Receive('sw_query_params', function()
        local ent = net.ReadEntity()
        SimpWound.PrintSWParams(ent)
    end)

	local WoundRender = function(self)
		local materials = self.sw_materials
		local params = self.sw_params

		for j, matvar in pairs(materials) do
			matvar:SetMatrix('$woundtransform', params.woundtransform)
			matvar:SetVector('$woundsize_blendmode', params.woundsize_blendmode)
			render.MaterialOverrideByIndex(j - 1, matvar)
		end
			self:DrawModel()
		for j, _ in pairs(materials) do
			render.MaterialOverrideByIndex(j - 1)
		end
	end

	local AvailableShaders = SimpWound.SWShaders
	SimpWound.ApplySimpWound = function(ent, params)
		-- 应用伤口着色器
		local shader = params.shader
		
		if not AvailableShaders[shader] then
			ErrorNoHalt(string.format('[SimpWound]: 未知着色器 "%s"\n', shader))
			return
		end

        ent.sw_params = params
		ent.sw_materials = {}
		for i, matpath in pairs(ent:GetMaterials()) do
			local filename = string.GetFileFromFilename(matpath)
			
			if string.find(filename, 'eye') ~= nil or string.find(filename, 'teeth') ~= nil or string.find(filename, 'mouth') ~= nil then
				-- 跳过眼球和牙齿的材质
				continue
			end

			-- matpathUsed将会以服务器端的数据为基准
			local idx = i - 1
			local matpathUsed = ent:GetSubMaterial(idx) == '' and matpath or ent:GetSubMaterial(idx)
		
			local deformedtexture, projectedtexture = params.deformedtexture or 'models/flesh', params.projectedtexture or 'models/flesh'
			local matname = string.format('%s_%s_%s_%s', matpathUsed, shader, deformedtexture, projectedtexture)

			-- 缓存材质
			local matcache = SimpWound.MaterialsCache[matname]
			if matcache then
				ent.sw_materials[i] = matcache
			else
				local temp = Material(matpathUsed)

				local matvar = CreateMaterial(
					matname,
					shader,
					{
						['$deformedtexture'] = deformedtexture,
						['$projectedtexture'] = projectedtexture,
					}
				)

				matvar:SetTexture('$basetexture', temp:GetTexture('$basetexture'))
				SimpWound.MaterialsCache[matname] = matvar

				ent.sw_materials[i] = matvar	
			end

		end

		-- 队列方案没找到高效的管理法，就用RenderOverride了，可能会对gpu归并造成一点影响？
		ent.RenderOverride = WoundRender
    end

	net.Receive('sw_apply', function()
		local params = net.ReadTable()
        local ent = net.ReadEntity()
        SimpWound.ApplySimpWound(ent, params)
    end)

	concommand.Add('sw_breentest', function(ply, cmd, args)
		local entities = ents.FindInSphere(ply:GetPos(), 2000)

		for _, ent in pairs(entities) do
			if ent:GetModel() ~= 'models/breen.mdl' then
				continue
			end

			local ellipsoid = Matrix()
			ellipsoid:SetTranslation(Vector(0, -12, 50 + math.random(-10, 10)))
			ellipsoid:SetScale(Vector(math.random(5, 10), 15, math.random(5, 10)))

			SimpWound.ApplySimpWound(ent, {
				shader = 'SimpWoundVertexLit',
				woundtransform = ellipsoid,
				woundsize_blendmode = Vector(1, 0.5, 0),
			})
		end
	end)
end


if SERVER then
    util.AddNetworkString('sw_query_params')
	util.AddNetworkString('sw_apply')

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

    SimpWound.PrintSWParams = function(ent)
		net.Start('sw_query_params')
			net.WriteEntity(ent)
		net.Broadcast()
    end

	SimpWound.ApplySimpWound = function(ent, params)
		net.Start('sw_apply')
			net.WriteTable(params)
			net.WriteEntity(ent)
		net.Broadcast()
    end

	concommand.Add('sw_breentest_sv', function(ply, cmd, args)
		local entities = ents.FindInSphere(ply:GetPos(), 2000)

		for _, ent in pairs(entities) do
			if ent:GetModel() ~= 'models/breen.mdl' then
				continue
			end

			local ellipsoid = Matrix()
			ellipsoid:SetTranslation(Vector(0, -12, 50 + math.random(-10, 10)))
			ellipsoid:SetScale(Vector(math.random(5, 10), 15, math.random(5, 10)))

			SimpWound.ApplySimpWound(ent, {
				shader = 'SimpWoundVertexLit',
				woundtransform = ellipsoid,
				woundsize_blendmode = Vector(1, 0.5, 0),
			})
		end
	end)

end