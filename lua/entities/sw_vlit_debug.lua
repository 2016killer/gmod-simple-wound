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

	concommand.Add('sw_vlit_debug', function(ply)
		local ent = ply:GetEyeTrace().Entity
		if IsValid(ent) then
			local ragdoll = ents.Create('prop_ragdoll')
			ragdoll:SetModel(ent:GetModel())
			ragdoll:SetPos(ent:GetPos())
			ragdoll:SetAngles(ent:GetAngles())
			ragdoll:Spawn()

			local ent2 = ents.Create('sw_vlit_debug')
			ent2:SetRagdoll(ragdoll)
			ent2:Spawn()

	
			undo.Create('sw_vlit_debug')
				undo.AddEntity(ent2)
				undo.SetPlayer(ply)
			undo.Finish()
		end
	end)

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
			material:SetTexture('$projectedtexture', 'models/flesh')
			material:SetTexture('$deformedtexture', 'models/flesh')
			material:SetMatrix('$woundtransform', ellipsoid)
			material:SetVector('$woundsize_blendmode', Vector(1, 0.3, 0))

			ragdoll:SetSubMaterial(idx, '!'..materialname)

			print(idx, mat)
		end
	end

	function ENT:Draw()
		
	end
end