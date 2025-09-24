-------------------------------UI-------------------------------
if CLIENT then
	TOOL.Category = language.GetPhrase('#tool.sw_sphericaldeform_tool.category')
	TOOL.Name = '#tool.sw_sphericaldeform_tool.name'

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
			0, 
			2, 
			3
		)

		panel:NumSlider(
			'#tool.sw_sphericaldeform_tool.bs', 
			'sw_sphericaldeform_tool_bs', 
			0, 
			2, 
			3
		)

	end

	TOOL.Information = {
		{name = 'apply', icon = 'gui/lmb.png'},
		{name = 'bindpose', icon = 'gui/rmb.png'},
		{name = 'print', icon = 'gui/r.png'},
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
	if not IsValid(self.target) then
		return
	end

	return true
end

function TOOL:Reload(tr)
	if !game.SinglePlayer() and SERVER then
		return
	end

	local ent = tr.Entity
	if not IsValid(ent) then
		return
	end

	SimpWound.PrintMainParams(ent)

	return true
end


if CLIENT then
	local wireframe = Material('models/wireframe')
	local vol_light001 = Material('models/effects/vol_light001')

	function TOOL:DrawHUD()
		-- 标记作用范围
		local tr = LocalPlayer():GetEyeTrace()
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
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				if IsValid(tr.Entity) then
					tr.Entity:DrawModel()
				end


				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_INCR)

				render.SetMaterial(vol_light001)
				SimpWound.DrawEllipsoid(woundEllip, 8)

				render.SetStencilReferenceValue(1)
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				render.ClearBuffersObeyStencil(0, 255, 255, 255, false)


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

				render.ClearBuffersObeyStencil(255, 0, 0, 255, false)

			render.SetStencilEnable(false)

			SimpWound.DrawCoordinate(woundEllip, 8)

			render.SetMaterial(wireframe)
			SimpWound.DrawEllipsoid(woundEllip, 8)
		
		cam.End3D()
	end

	local errmsg = language.GetPhrase('#sw.missmodule')
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
		end
	end
end 


