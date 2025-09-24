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
		if not IsValid(self:GetRagdoll()) then
			local Ragdoll = ents.Create('prop_ragdoll')
			Ragdoll:SetModel('models/breen.mdl')
			Ragdoll:SetPos(self:GetPos())
			Ragdoll:SetAngles(self:GetAngles())
			Ragdoll:Spawn()

			self:SetRagdoll(Ragdoll)
		end
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
			if string.find(mat, 'eye') ~= nil or string.find(mat, 'teeth') ~= nil or string.find(mat, 'mouth') ~= nil then
				print('skip', mat)
				continue
			end

			local idx = i - 1

			local materialname = string.format('simplewoundvlit_debug_%d', idx)
			local material = CreateMaterial(
				materialname, 
				'SimpWoundVertexLit'
			)
			
			material:SetTexture('$basetexture', mat)
			material:SetTexture('$projectedtexture', 'models/flesh')
			material:SetTexture('$deformedtexture', 'models/flesh')
			material:SetMatrix('$woundtransform', ellipsoid)
			material:SetMatrix('$woundtransforminvert', ellipsoid:GetInverse())
			material:SetVector('$woundsize_blendmode', Vector(1, 0.3, 0))

			ragdoll:SetSubMaterial(idx, '!'..materialname)
		end
	end

	function ENT:Draw()
		
	end
end