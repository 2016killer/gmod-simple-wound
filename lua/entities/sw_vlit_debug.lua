AddCSLuaFile()

ENT.Type = 'anim'
ENT.Base = 'base_anim'

ENT.Category = 'SimpleWound'
ENT.Spawnable = true
ENT.Author = 'Zack'


-----------------------------------------------实体逻辑
function ENT:SetupDataTables()
	self:NetworkVar('Entity', 0, 'Ragdoll')
end

if SERVER then
	function ENT:Initialize()
		local Ragdoll = ents.Create('prop_ragdoll')
		Ragdoll:SetModel('models/breen.mdl')
		Ragdoll:SetPos(self:GetPos())
		Ragdoll:SetAngles(self:GetAngles())
		Ragdoll:Spawn()

		self:SetRagdoll(Ragdoll)
		self:DrawShadow(false)
	end

	function ENT:OnRemove()
		if IsValid(self:GetRagdoll()) then
			self:GetRagdoll():Remove()
		end
	end

end


if CLIENT then
    local ellipsoid = Matrix()
    ellipsoid:SetTranslation(Vector(0, -12, 50))
    ellipsoid:SetScale(Vector(10, 15, 10))

	function ENT:Initialize()
		local ragdoll = self:GetRagdoll()
		for i, mat in pairs(ragdoll:GetMaterials()) do
			local idx = i - 1

			local materialname = string.format('simplewoundvlit_%d_%d', self:EntIndex(), idx)
			local material = CreateMaterial(
				materialname, 
				'SimpWoundVertexLit'
			)

			material:SetTexture('$basetexture', mat)
			material:SetTexture('$projectedtexture', 'models/props_c17/paper01')
			material:SetTexture('$deformedtexture', 'models/props_c17/paper01')
			material:SetMatrix('$woundtransform', ellipsoid)
			material:SetMatrix('$woundtransforminvert', ellipsoid:GetInverse())
			material:SetVector('$woundsize_blendmode', Vector(1, 0.3, 0))

			ragdoll:SetSubMaterial(idx, '!'..materialname)
		end
	end

	function ENT:Draw()
		
	end

	hook.Add('SetupWorldFog', 'fogtest', function()
		render.FogMode(1)
		render.FogColor(0, 0, 0)
		render.FogMaxDensity(1)
		render.FogStart(0)
		render.FogEnd(500)
		return true
	end)
end