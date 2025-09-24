TOOL.Category = 'SimpWound'
TOOL.Name = '#tool.sw_sphericaldeform_tool.name'


-------------------------------UI-------------------------------
if CLIENT then
	TOOL.ClientConVar['sx'] = '10.0'
	TOOL.ClientConVar['sy'] = '10.0'
	TOOL.ClientConVar['sz'] = '10.0'

	TOOL.ClientConVar['ws'] = '1.0'
	TOOL.ClientConVar['bs'] = '0.5'

	function TOOL.BuildCPanel(panel)
		panel:Clear()

		local ctrl = vgui.Create('ControlPresets', panel)
		ctrl:SetPreset('sw_sphericaldeform_tool')
		local default =	{
			sw_sphericaldeform_tool_sx = '10.0',
			sw_sphericaldeform_tool_sy = '10.0',
			sw_sphericaldeform_tool_sz = '10.0',
			sw_sphericaldeform_tool_ws = '1.0',
			sw_sphericaldeform_tool_bs = '0.5',
		}
		ctrl:AddOption('#preset.default', default)
		for k, v in pairs(default) do ctrl:AddConVar(k) end
		panel:AddPanel(ctrl)

		panel:NumSlider(
			'#tool.sw_sphericaldeform_tool.sx', 
			'sw_sphericaldeform_tool_sx', 
			1, 
			50, 
			3
		)

		panel:NumSlider(
			'#tool.sw_sphericaldeform_tool.sy', 
			'sw_sphericaldeform_tool_sy', 
			1, 
			50, 
			3
		)

		panel:NumSlider(
			'#tool.sw_sphericaldeform_tool.sz', 
			'sw_sphericaldeform_tool_sz', 
			1, 
			50, 
			3
		)

		panel:NumSlider(
			'#tool.sw_sphericaldeform_tool.ws', 
			'sw_sphericaldeform_tool_ws', 
			1, 
			50, 
			3
		)

		panel:NumSlider(
			'#tool.sw_sphericaldeform_tool.bs', 
			'sw_sphericaldeform_tool_bs', 
			1, 
			50, 
			3
		)

	end

	TOOL.Information = {
		{name = 'add', op = 1, icon = 'gui/lmb.png'},

		{name = 'edit', op = 0, icon = 'gui/rmb.png'},
		{name = 'quit', op = 1, icon = 'gui/rmb.png'},
		
		{name = 'reset', icon = 'gui/r.png'},
	}

end
--------------------------------------------------------------
if SERVER then 
	util.AddNetworkString('sw_sphericaldeform_tool_preview')
	
	local function SendPreview(ent, ply)
		net.Start('sw_sphericaldeform_tool_preview')
			net.WriteEntity(ent)
		net.Send(ply)
	end

	function TOOL:SetTarget(ent)
		if IsValid(self.target) then
			self:PlayPhys('origin')
		end

		if not IsValid(ent) then
			self.target = nil
			SendPreview(NULL, self:GetOwner())
		else	
			self:RecordPhys(ent, 'origin')
			self:BindPose(ent)
			self:RecordPhys(ent, 'bindpose')
			self.target = ent

			local v3dm_ent = self.target.v3dm_ent
			if IsValid(v3dm_ent) then
				v3dm_ent:Init(self.target)
			else
				v3dm_ent = ents.Create('v3dm_ent')
				v3dm_ent:Init(self.target)
				v3dm_ent.MaskType = 'ELLIPSOID'
				v3dm_ent:Spawn()
				self.target.v3dm_ent = v3dm_ent
			end

			SendPreview(v3dm_ent, self:GetOwner())
		end
	end


	function TOOL:RightClick(tr)
		local ent = tr.Entity
		if not IsValid(ent) then
			return
		end

		if ent == self.target then
			self:SetTarget(nil)
			return true
		else
			self:SetTarget(ent)
			return true
		end
	end

	function TOOL:LeftClick(tr)
		if not IsValid(self.target) then
			return
		end

		local ellipsoidWorldTransform = Matrix()
		ellipsoidWorldTransform:SetTranslation(tr.HitPos)
		ellipsoidWorldTransform:SetAngles(tr.HitNormal:Angle())
		ellipsoidWorldTransform:SetScale(Vector(self:GetClientNumber('sx'), self:GetClientNumber('sy'), self:GetClientNumber('sz')))

		local v3dm_ent = self.target.v3dm_ent
		v3dm_ent.MaskTransform = v3dm_ent:GetWorldTransformMatrix():GetInverse() * ellipsoidWorldTransform
		v3dm_ent.MaskType = 'ELLIPSOID'
		v3dm_ent:UpdateMaterialParams()
		
		return true
	end

	function TOOL:Deploy()
		if IsValid(self.target) then
			self:PlayPhys('bindpose')
		end
	end

	function TOOL:Holster()
		if not self:GetOwner():Alive() then
			self:SetTarget(nil)
		end
	end

	function TOOL:Think()
		if IsValid(self.target) then
			self:SetOperation(1)
		else
			self:SetOperation(0)
		end
	end
end



if CLIENT then
	local preview = nil
	net.Receive('sw_sphericaldeform_tool_preview', function(len, ply)
		preview = net.ReadEntity()
    end)

	local wireframe = Material('models/wireframe')
	local vol_light001 = Material('models/effects/vol_light001')

	function TOOL:DrawHUD()
		if not IsValid(preview) or not V3dm then
			preview = nil
			return
		end

		local tr = LocalPlayer():GetEyeTrace()
		local ellipsoidWorldTransform = Matrix()
		ellipsoidWorldTransform:SetTranslation(tr.HitPos)
		ellipsoidWorldTransform:SetAngles(tr.HitNormal:Angle())
		ellipsoidWorldTransform:SetScale(Vector(self:GetClientNumber('sx'), self:GetClientNumber('sy'), self:GetClientNumber('sz')))

		local maskTransform = preview:GetWorldTransformMatrix() * V3dm.GetMaskTransform(preview.materials[0])

		cam.Start3D(EyePos(), EyeAngles())
			render.ClearStencil()
			render.SetStencilEnable(true)
				render.SetStencilWriteMask(1)
				render.SetStencilTestMask(1)
				render.SetStencilReferenceValue(0)
				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_REPLACE)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				render.OverrideColorWriteEnable(true, false)
				render.OverrideDepthEnable(true, true)
					render.CullMode(MATERIAL_CULLMODE_CW)
					preview:DrawModel()
    				render.CullMode(MATERIAL_CULLMODE_CCW)
					preview:DrawModel()
				render.OverrideDepthEnable(false)
				render.OverrideColorWriteEnable(false, false)


				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_INCR)

				render.SetMaterial(vol_light001)
				V3dm.DrawEllipsoid(ellipsoidWorldTransform, 8)

				render.SetStencilReferenceValue(1)
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				render.ClearBuffersObeyStencil(255, 255, 0, 255, false)

			render.SetStencilEnable(false)


			V3dm.DrawCoordinate(preview:GetWorldTransformMatrix())

			render.SetMaterial(wireframe)
			V3dm.DrawEllipsoid(ellipsoidWorldTransform, 8)
			V3dm.DrawEllipsoid(maskTransform, 8)	
		
		cam.End3D()
	end

	function TOOL:DrawToolScreen(width, height)
		if not V3dm then
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, width, height)

			draw.SimpleText(
				language.GetPhrase('tool.sw_sphericaldeform_tool.missmodule'), 
				'DermaLarge', 
				0, 
				0, 
				Color(255, 0, 0, 255), 
				TEXT_ALIGN_LEFT, 
				TEXT_ALIGN_TOP 
			)
		end
	end
end 


