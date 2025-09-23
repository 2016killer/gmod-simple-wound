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
    ellipsoid:SetTranslation(Vector(0, 10, 55))
    ellipsoid:SetScale(Vector(5, 10, 5))

	function ENT:Initialize()
		local materialname = string.format('simplewound_%d', self:EntIndex())
		local material = CreateMaterial(
			materialname, 
			'SimpWound'
		)

		material:SetTexture('$basetexture', 'models/breen/breen_sheet')
		material:SetTexture('$projectedtexture', 'models/flesh')
		material:SetTexture('$deformedtexture', 'models/flesh')
		material:SetMatrix('$woundtransform', ellipsoid)
		material:SetMatrix('$woundtransforminvert', ellipsoid:GetInverse())
		material:SetVector('$woundsize_blendmode', Vector(1, 0.5, 0))

		self:GetRagdoll():SetMaterial('!'..materialname)
	end

	function ENT:Draw()
		
	end
end