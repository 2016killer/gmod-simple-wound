--
-- for lyt 2025 04 08, 心急强吃热豆腐
local function GetBoneMatrix(ent, boneid)
	if boneid == -1 then
		return ent:GetWorldTransformMatrix()
	else
		-- 修成屎了都
		if CLIENT then 
			ent:SetupBones()
		end

		local bonematrix = ent:GetBoneMatrix(boneid)

		if bonematrix then
			return bonematrix
		else
			local modelname = isfunction(ent.GetModel) and ent:GetModel() or 'unknown model'
			local bonename = isfunction(ent.GetBoneName) and ent:GetBoneName(boneid) or 'unknown bone'

			print(
				string.format(
					'%s: %s, %s, %s',
					language.GetPhrase('sw.err.unknowboneid'),
					boneid,
					modelname,
					bonename
				)
			)

			return ent:GetWorldTransformMatrix()
		end
	end
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
    SimpWound.Version = version
    print('[SimpWound]: LUA VERSION ' .. version)

    SimpWound.MaterialsCache = SimpWound.MaterialsCache or {}

    local zerovec = Vector()
	local zeroang = Angle()
    local unitx = Vector(1, 0, 0)
    local unity = Vector(0, 1, 0)
    local unitz = Vector(0, 0, 1)

    SimpWound.DrawEllipsoid = function(transform, step)
        cam.PushModelMatrix(transform)
            render.DrawSphere(zerovec, 1, step, step)    
        cam.PopModelMatrix()
    end

    SimpWound.DrawCoordinate = function(transform, size)
		size = size or 1
        cam.PushModelMatrix(transform)
            render.DrawLine(zerovec, unitx * size, Color(255, 0, 0, 255), false)
            render.DrawLine(zerovec, unity * size, Color(0, 255, 0, 255), false)
            render.DrawLine(zerovec, unitz * size, Color(0, 0, 255, 255), false)   
        cam.PopModelMatrix()
    end

    SimpWound.DrawBox = function(transform, size)
		size = size or 1
        cam.PushModelMatrix(transform)
			render.DrawBox(zerovec, zeroang, Vector(-size, -size, -size), Vector(size, size, size))
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
		if istable(ent.sw_params) then
        	PrintTable(ent.sw_params)
        end
    end

    net.Receive('sw_query_params', function()
        local ent = net.ReadEntity()
		if IsValid(ent) then
        	SimpWound.PrintSWParams(ent)
        end
    end)

	local WoundRender = function(self)
		local materials = self.sw_materials
		local params = self.sw_params

		for j, matvar in pairs(materials) do
			matvar:SetMatrix('$woundtransform', params.woundtransform)
			matvar:SetMatrix('$woundtransforminvert', params.woundtransforminvert)
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
		-- params.woundtransform 必要
		-- params.woundsize_blendmode 必要
		-- params.deformedtexture 必要
		-- params.projectedtexture 必要

		local shader = params.shader
		
		if not AvailableShaders[shader] then
			ErrorNoHalt(string.format('[SimpWound]: 未知着色器 "%s"\n', shader))
			return
		end

		params.woundtransforminvert = params.woundtransform:GetInverse()

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
		
			local deformedtexture = params.deformedtexture or 'models/flesh'
			local projectedtexture = params.projectedtexture or 'models/flesh'
			local depthtexture = params.depthtexture or ''
			local matname = string.format('%s_%s_%s_%s_%s', matpathUsed, shader, deformedtexture, projectedtexture, depthtexture)

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
						['$basetexture'] = temp:GetTexture('$basetexture'):GetName(),
						['$deformedtexture'] = deformedtexture,
						['$projectedtexture'] = projectedtexture,
						['$depthtexture'] = depthtexture,
					}
				)

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
		if IsValid(ent) then
			SimpWound.ApplySimpWound(ent, params)
		end
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

	SimpWound.ClientModels = {}

	local ClientModels = SimpWound.ClientModels
	SimpWound.ApplySimpWoundEasy = function(ent, 
		shader,
		woundLocalTransform,
		woundsize_blendmode, deformedtexture, projectedtexture, depthtexture,
		boneid, offset
	)
		-- 这方法有点傻逼, 但是很有效
		local model = ent:GetModel()
		local modelent = ClientModels[model]
		if not IsValid(modelent) then
			modelent = ClientsideModel(model)
			modelent:SetNoDraw(true)
			ClientModels[model] = modelent
		end

		local params = {}

		params.woundtransform = SimpWound.GetOffset(modelent, offset):GetInverse() * GetBoneMatrix(modelent, boneid) * woundLocalTransform
		params.woundsize_blendmode = woundsize_blendmode or Vector(1, 0.5, 0)
		params.shader = shader or 'SimpWoundVertexLit'
		params.deformedtexture = deformedtexture or 'models/flesh'
		params.projectedtexture = projectedtexture or 'models/flesh'
		params.depthtexture = depthtexture or ''
	
		SimpWound.ApplySimpWound(ent, params)
	end


	net.Receive('sw_apply_easy', function()
		local ent = net.ReadEntity()
		local shader = net.ReadString()
		local woundLocalTransform = net.ReadMatrix()
		local woundsize_blendmode = net.ReadVector()
		local deformedtexture = net.ReadString()
		local projectedtexture = net.ReadString()
		local depthtexture = net.ReadString()
		local boneid = net.ReadInt(32)
		local offset = net.ReadString()

		if IsValid(ent) then
			SimpWound.ApplySimpWoundEasy(ent, 
				shader, 
				woundLocalTransform, 
				woundsize_blendmode, deformedtexture, projectedtexture, depthtexture,
				boneid, offset
			)
		end
    end)

	SimpWound.Reset = function(ent)
		ent.RenderOverride = nil
		ent.sw_params = nil
		ent.sw_materials = nil
	end

	net.Receive('sw_reset', function()
		local ent = net.ReadEntity()
		if IsValid(ent) then
			SimpWound.Reset(ent)
		end
	end)


	local function draw_spheredepth(transform, matvar)
		render.SetMaterial(matvar)
		SimpWound.DrawEllipsoid(transform, 8)
	end


	local conemodel
	local conemodeloffset = Matrix()
	conemodeloffset:SetTranslation(Vector(0.5, 0, 0))
	conemodeloffset:SetAngles(Angle(-90, 0, 0))
	conemodeloffset:SetScale(Vector(1 / 23.5, 1 / 23.5, 1 / 23.5))
	
	local function draw_conedepth(transform, matvar)
		if IsValid(conemodel) then
			transform = transform * conemodeloffset
			conemodel:EnableMatrix('RenderMultiply', transform)

			render.MaterialOverride(matvar)
				conemodel:DrawModel()
			render.MaterialOverride()
		else
			conemodel = ClientsideModel('models/hunter/misc/cone1x05.mdl')
			conemodel:SetPos(zerovec)
			conemodel:SetAngles(zeroang)
			conemodel:SetNoDraw(true)
		end
	end

	local startpos
	concommand.Add('mesure', function(ply)
		if startpos then
			local endpos = ply:GetEyeTrace().HitPos
			local dist = (endpos - startpos):Length()
			print('距离: ' .. dist)

			debugoverlay.Line(endpos, startpos, 1, nil, true)

			startpos = nil
		else
			startpos = ply:GetEyeTrace().HitPos
		end
	end) 


	local function draw_squaredepth(transform, matvar)
		render.SetMaterial(matvar)
		SimpWound.DrawBox(transform)
	end

	-- 自己注册吧
	SimpWound.DepthtexModelPainter = {
		['sw/spheredepth' ] = draw_spheredepth,
		['sw/conedepth'] = draw_conedepth,
		['sw/squaredepth'] = draw_squaredepth
	}

end


if SERVER then
    util.AddNetworkString('sw_query_params')
	util.AddNetworkString('sw_apply_easy')
	util.AddNetworkString('sw_apply')
	util.AddNetworkString('sw_reset')

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


	SimpWound.ApplySimpWound = function(ent, params)
		net.Start('sw_apply')
			net.WriteTable(params)
			net.WriteEntity(ent)
		net.Broadcast()
    end

	SimpWound.ApplySimpWoundEasy = function(ent, 
		shader,
		woundWorldTransform,
		woundsize_blendmode, deformedtexture, projectedtexture, depthtexture,
		boneid, offset
	)
		local woundLocalTransform = GetBoneMatrix(ent, boneid):GetInverse() * woundWorldTransform

		net.Start('sw_apply_easy')
			net.WriteEntity(ent)
			net.WriteString(shader)
			net.WriteMatrix(woundLocalTransform)
			net.WriteVector(woundsize_blendmode)
			net.WriteString(deformedtexture)
			net.WriteString(projectedtexture)
			net.WriteString(depthtexture)
			net.WriteInt(boneid, 32)
			net.WriteString(offset)
		net.Broadcast()
	end


	concommand.Add('sw_breentest_sv', function(ply)
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

	SimpWound.Reset = function(ent)
		net.Start('sw_reset')
			net.WriteEntity(ent)
		net.Broadcast()
	end

end



local function auto(ent) 
	return ent:GetBoneCount() > 1 and SimpWound.Offset.z90 or SimpWound.Offset.none
end

SimpWound.Offset = {
	none = Matrix(),
	z90 = Matrix(),
	auto = auto,
}

SimpWound.Offset.z90:SetAngles(Angle(0, 90, 0))

SimpWound.GetOffset = function(ent, key)
	-- 获取渲染坐标系与世界坐标系的偏移
	-- 下下策
	local offset = SimpWound.Offset[key]
	if isfunction(offset) then
		return offset(ent)
	else
		return offset or SimpWound.Offset.none
	end
end