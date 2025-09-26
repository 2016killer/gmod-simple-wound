AddCSLuaFile()
-------------------------------UI-------------------------------
if CLIENT then
	TOOL.Category = language.GetPhrase('#tool.sw_tool.category')
	TOOL.Name = '#tool.sw_tool.name'

	TOOL.ClientConVar['shader'] = 'SimpWoundVertexLit'
	TOOL.ClientConVar['sx'] = '10.0'
	TOOL.ClientConVar['sy'] = '5'
	TOOL.ClientConVar['sz'] = '5'

	TOOL.ClientConVar['ws'] = '1.0'
	TOOL.ClientConVar['bs'] = '0.5'

	TOOL.ClientConVar['offset'] = 'auto'

	TOOL.ClientConVar['projtex'] = 'models/flesh'
	TOOL.ClientConVar['deformtex'] = 'models/flesh'
	TOOL.ClientConVar['depthtex'] = 'sw/conedepth'

	function TOOL.BuildCPanel(panel)
		local ctrl = vgui.Create('ControlPresets', panel)
		ctrl:SetPreset('sw_tool')
		local default =	{
			sw_tool_shader = 'SimpWoundVertexLit',
			sw_tool_sx = '10.0',
			sw_tool_sy = '5',
			sw_tool_sz = '5',
			sw_tool_ws = '1.0',
			sw_tool_bs = '0.5',
			sw_tool_offset = 'auto',
			sw_tool_projtex = 'models/flesh',
			sw_tool_deformtex = 'models/flesh',
			sw_tool_depthtex = 'sw/conedepth',
		}
		ctrl:AddOption('#preset.default', default)
		for k, v in pairs(default) do ctrl:AddConVar(k) end
		panel:AddPanel(ctrl)

		local shaderComboBox = panel:ComboBox('#tool.sw_tool.shader', 'sw_tool_shader')
		shaderComboBox:AddChoice('#sw.ellipclip', 'EllipClip')
		shaderComboBox:AddChoice('#sw.ellipclipvertexlit', 'EllipClipVertexLit')
		shaderComboBox:AddChoice('#sw.depthtexclip', 'DepthTexClip')
		shaderComboBox:AddChoice('#sw.depthtexclipvertexlit', 'DepthTexClipVertexLit')
		shaderComboBox:AddChoice('#sw.simpwound', 'SimpWound')
		shaderComboBox:AddChoice('#sw.simpwoundvertexlit', 'SimpWoundVertexLit')


		panel:NumSlider(
			'#tool.sw_tool.sx', 
			'sw_tool_sx', 
			1, 
			50, 
			3
		)

		panel:NumSlider(
			'#tool.sw_tool.sy', 
			'sw_tool_sy', 
			1, 
			50, 
			3
		)

		panel:NumSlider(
			'#tool.sw_tool.sz', 
			'sw_tool_sz', 
			1, 
			50, 
			3
		)

		panel:NumSlider(
			'#tool.sw_tool.ws', 
			'sw_tool_ws', 
			0, 
			2, 
			3
		)

		panel:NumSlider(
			'#tool.sw_tool.bs', 
			'sw_tool_bs', 
			0, 
			2, 
			3
		)

		local offsetComboBox = panel:ComboBox('#tool.sw_tool.offset', 'sw_tool_offset')
		if SimpWound then
			for k, v in pairs(SimpWound.Offset) do
				offsetComboBox:AddChoice(k, k)
			end
		end


		local items = {
			'models/flesh',
			'models/props_c17/paper01',
			'models/props_foliage/tree_deciduous_01a_trunk',
			'models/props_wasteland/wood_fence01a'
		}

		panel:Help('#tool.sw_tool.deformtex')
		local MatSelect2 = vgui.Create('MatSelect', panel)
		MatSelect2:Dock(TOP)
		Derma_Hook(MatSelect2.List, 'Paint', 'Paint', 'Panel')

		panel:AddItem(MatSelect2)
		MatSelect2:SetConVar('sw_tool_deformtex')

		MatSelect2:SetAutoHeight(true)
		MatSelect2:SetItemWidth(64)
		MatSelect2:SetItemHeight(64)

		for k, material in pairs(items) do
			MatSelect2:AddMaterial(material, material)
		end


		panel:Help('#tool.sw_tool.projtex')
		local MatSelect = vgui.Create('MatSelect', panel)
		MatSelect:Dock(TOP)
		Derma_Hook(MatSelect.List, 'Paint', 'Paint', 'Panel')

		panel:AddItem(MatSelect)
		MatSelect:SetConVar('sw_tool_projtex')

		MatSelect:SetAutoHeight(true)
		MatSelect:SetItemWidth(64)
		MatSelect:SetItemHeight(64)

		for k, material in pairs(items) do
			MatSelect:AddMaterial(material, material)
		end


		local items2 = {
			'sw/spheredepth',
			'sw/conedepth',
			'sw/squaredepth',
		}

		panel:Help('#tool.sw_tool.depthtex')
		local MatSelect3 = vgui.Create('MatSelect', panel)
		MatSelect3:Dock(TOP)
		Derma_Hook(MatSelect3.List, 'Paint', 'Paint', 'Panel')

		panel:AddItem(MatSelect3)
		MatSelect3:SetConVar('sw_tool_depthtex')

		MatSelect3:SetAutoHeight(true)
		MatSelect3:SetItemWidth(64)
		MatSelect3:SetItemHeight(64)

		for k, material in pairs(items2) do
			MatSelect3:AddMaterial(material, material)
		end


	end

	TOOL.Information = {
		{name = 'apply', icon = 'gui/lmb.png'},
		{name = 'bindpose', icon = 'gui/rmb.png'},
		{name = 'reset', icon = 'gui/r.png'},
	}

end
--------------------------------------------------------------


function TOOL:RightClick(tr)
	local ent = tr.Entity
	if not IsValid(ent) then
		return
	end

	if SERVER then
		if istable(ent.physdata) then
			SimpWound.PlayPhys(ent, 'origin', ent.physdata)
			ent.physdata = nil
		else
			ent.physdata = SimpWound.RecordPhys(ent, 'origin')
			SimpWound.BindPose(ent)
		end
	end

	return true
end

function TOOL:LeftClick(tr)
	local ent = tr.Entity
	if not IsValid(ent) then
		return
	end

	tr.HitPos = tr.HitPos - tr.Normal * 5
	if SERVER then
		local woundWorldTransform = Matrix()
		woundWorldTransform:SetTranslation(tr.HitPos)
		woundWorldTransform:SetAngles(tr.HitNormal:Angle())
		woundWorldTransform:SetScale(
			Vector(
				self:GetClientNumber('sx'), 
				self:GetClientNumber('sy'), 
				self:GetClientNumber('sz')
			)
		)

		if IsValid(ent) then
			SimpWound.ApplySimpWoundEasy(
				ent, 
				self:GetClientInfo('shader'),
				woundWorldTransform,
				Vector(
					self:GetClientNumber('ws'), 
					self:GetClientNumber('bs'),
					0
				), 
				self:GetClientInfo('deformtex'), self:GetClientInfo('projtex'), self:GetClientInfo('depthtex'),
				ent:TranslatePhysBoneToBone(tr.PhysicsBone), self:GetClientInfo('offset')
			)
		end
	end

	return true
end

function TOOL:Reload(tr)
	local ent = tr.Entity
	if not IsValid(ent) then
		return
	end

	// if SERVER then
	// 	if istable(ent.physdata) then
	// 		SimpWound.PlayPhys(ent, 'origin', ent.physdata)
	// 		ent.physdata = nil
	// 	else
	// 		ent.physdata = SimpWound.RecordPhys(ent, 'origin')
	// 		SimpWound.BindPose(ent)
	// 	end
	// end

	SimpWound.Reset(ent)
	SimpWound.PrintSWParams(ent)

	return true
end


if CLIENT then
	local wireframe = Material('models/wireframe')
	local vol_light001 = Material('models/effects/vol_light001')

	local ghostent = ClientsideModel('models/hunter/blocks/cube025x025x025.mdl')
	ghostent:SetNoDraw(true)

	function TOOL:Think()
		local tr = LocalPlayer():GetEyeTrace()
		local ent = tr.Entity

		if not IsValid(ghostent) then
			ghostent = ClientsideModel()
			ghostent:SetNoDraw(true)
		end

		if IsValid(ent) then
			if ghostent:GetModel() ~= ent:GetModel() or ghostent:GetParent() ~= ent then
				ghostent:SetModel(ent:GetModel())
				if ent:IsRagdoll() then
					ghostent:SetPos(ent:GetPos())
					ghostent:SetAngles(ent:GetAngles())
					ghostent:SetParent(ent)
					ghostent:AddEffects(EF_BONEMERGE)
				end
				ghostent:SetupBones()
			end
			
			if not ent:IsRagdoll() then
				ghostent:SetPos(ent:GetPos())
				ghostent:SetAngles(ent:GetAngles())
			end
		end

		self.DrawMarkFlag = !input.IsKeyDown(KEY_E)
	end

	function TOOL:DrawMarkModel(transform, matvar)
		local shader = self:GetClientInfo('shader')
		if shader == 'DepthTexClip' or shader == 'DepthTexClipVertexLit' then
			local depthtex = self:GetClientInfo('depthtex')
			local painter = SimpWound.DepthtexModelPainter[depthtex]
			if isfunction(painter) then
				painter(transform, matvar)
			end
		else
			render.SetMaterial(matvar)
			SimpWound.DrawEllipsoid(transform, 8)
		end
	end


	function TOOL:DrawMark()
		-- 标记作用范围
		local tr = LocalPlayer():GetEyeTrace()

		tr.HitPos = tr.HitPos - tr.Normal * 5

		local woundEllip = Matrix()
		woundEllip:SetTranslation(tr.HitPos)
		woundEllip:SetAngles(tr.HitNormal:Angle())

		local bloodTexEllip = Matrix() 
		bloodTexEllip:SetTranslation(tr.HitPos)
		bloodTexEllip:SetAngles(tr.HitNormal:Angle())

		woundEllip:SetScale(
			Vector(
				self:GetClientNumber('sx'), 
				self:GetClientNumber('sy'), 
				self:GetClientNumber('sz')
			) * self:GetClientNumber('ws')
		)

		bloodTexEllip:SetScale(
			Vector(
				self:GetClientNumber('sx'), 
				self:GetClientNumber('sy'), 
				self:GetClientNumber('sz')
			) * (self:GetClientNumber('ws') + self:GetClientNumber('bs'))
		)

		cam.Start3D(EyePos(), EyeAngles())
			render.ClearStencil()
			render.SetStencilEnable(true)
				render.SetStencilWriteMask(1)
				render.SetStencilTestMask(1)
				render.SetStencilReferenceValue(0)
				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_REPLACE)
				render.SetStencilFailOperation(STENCIL_REPLACE)
				render.SetStencilZFailOperation(STENCIL_REPLACE)

				if IsValid(ghostent) then
					render.OverrideColorWriteEnable(true, false)
					render.OverrideDepthEnable(true, true)
						ghostent:DrawModel()
					render.OverrideDepthEnable(false)
					render.OverrideColorWriteEnable(false)
				end


				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_INCR)

				self:DrawMarkModel(woundEllip, vol_light001)
	
				

				render.SetStencilReferenceValue(1)
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				cam.Start2D()
					surface.SetDrawColor(0, 255, 255, 50)
					surface.DrawRect(0, 0, ScrW(), ScrH())
				cam.End2D()


				if IsValid(ghostent) then
					render.MaterialOverride(wireframe)
						ghostent:DrawModel()
					render.MaterialOverride()
				end

				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_INCR)

				render.SetMaterial(vol_light001)
				SimpWound.DrawEllipsoid(bloodTexEllip, 8)

				render.SetStencilReferenceValue(1)
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				cam.Start2D()
					surface.SetDrawColor(255, 0, 255, 50)
					surface.DrawRect(0, 0, ScrW(), ScrH())
				cam.End2D()

			render.SetStencilEnable(false)

			
			SimpWound.DrawCoordinate(woundEllip)
			self:DrawMarkModel(woundEllip, wireframe)

			if IsValid(ghostent) then
				SimpWound.DrawCoordinate(
					ghostent:GetWorldTransformMatrix() * SimpWound.GetOffset(self:GetClientInfo('offset')), 
					30
				)
			end
		cam.End3D()
	end

	function TOOL:DrawHUD()
		if self.DrawMarkFlag and SimpWound then
			-- 安全调用
			local success, err = pcall(self.DrawMark, self)
			if not success then
				ErrorNoHalt(string.format('[SimpWound]: %s\n', err))
				render.OverrideColorWriteEnable(false)
				render.OverrideDepthEnable(false)
				return
			end
		end
	end


	local errmsg = language.GetPhrase('#sw.missmodule')
	local msg = language.GetPhrase('#sw.versionhint') .. (SimpWound and SimpWound.Version or '?')
	function TOOL:DrawToolScreen(width, height)
		-- 错误提示
		if not SimpWound then
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, width, height)

			draw.SimpleText(
				errmsg, 
				'DermaLarge', 
				0, 
				0, 
				Color(255, 0, 0, 255), 
				TEXT_ALIGN_LEFT, 
				TEXT_ALIGN_TOP 
			)
		else
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, width, height)

			draw.SimpleText(
				msg, 
				'DermaLarge', 
				0, 
				0, 
				Color(0, 255, 0, 255), 
				TEXT_ALIGN_LEFT, 
				TEXT_ALIGN_TOP 
			)
		end
	end
end 


