#include "BaseVSShader.h"

#include "shaders/inc/SimpWoundVertexLit_vs30.inc"
#include "shaders/inc/SimpWoundVertexLit_ps30.inc"

#include <istudiorender.h>
#include "commandbuilder.h"

BEGIN_VS_SHADER(SimpWoundVertexLit, "Help for SimpWoundVertexLit")

BEGIN_SHADER_PARAMS
	SHADER_PARAM(WOUNDTRANSFORM, SHADER_PARAM_TYPE_MATRIX, "[1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1]", "Wound transform based on pre-skinned space")
	SHADER_PARAM(WOUNDSIZE_BLENDMODE, SHADER_PARAM_TYPE_VEC3, "[1, 0.5, 0]", "Wound size, x: deformed range, y: project range, z: use projected texture alpha blend")

	SHADER_PARAM(DEFORMEDTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh", "Deformed part texture")
	SHADER_PARAM(PROJECTEDTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "sw/blood", "Projected texture")
END_SHADER_PARAMS


SHADER_INIT_PARAMS()
{
	SET_FLAGS2(MATERIAL_VAR2_SUPPORTS_HW_SKINNING);

	if (!params[WOUNDTRANSFORM]->IsDefined())
	{
		VMatrix mat;
		MatrixSetIdentity(mat);
		params[WOUNDTRANSFORM]->SetMatrixValue(mat);
	}

	if (!params[WOUNDSIZE_BLENDMODE]->IsDefined())
	{
		params[WOUNDSIZE_BLENDMODE]->SetVecValue(1.0f, 0.5f, 0.0f);
	}
}

SHADER_FALLBACK
{
	return 0;
}


SHADER_INIT
{
	LoadTexture(BASETEXTURE);

	if (params[DEFORMEDTEXTURE]->IsDefined())
	{
		LoadTexture(DEFORMEDTEXTURE);
	}

	if (params[PROJECTEDTEXTURE]->IsDefined())
	{
		LoadTexture(PROJECTEDTEXTURE);
	}

}

SHADER_DRAW
{
	SHADOW_STATE
	{
		pShaderShadow->EnableTexture(SHADER_SAMPLER0, true);
		pShaderShadow->EnableTexture(SHADER_SAMPLER1, true);
		pShaderShadow->EnableTexture(SHADER_SAMPLER2, true);
		pShaderShadow->EnableTexture(SHADER_SAMPLER3, true);

		int fmt = VERTEX_POSITION | VERTEX_FORMAT_COMPRESSED;
		pShaderShadow->VertexShaderVertexFormat(fmt, 1, 0, 0);

		DECLARE_STATIC_VERTEX_SHADER(SimpWoundVertexLit_vs30);
		SET_STATIC_VERTEX_SHADER(SimpWoundVertexLit_vs30);

		DECLARE_STATIC_PIXEL_SHADER(SimpWoundVertexLit_ps30);
		SET_STATIC_PIXEL_SHADER(SimpWoundVertexLit_ps30);

		DefaultFog();
	}
	DYNAMIC_STATE
	{

		{
			CCommandBufferBuilder< CFixedCommandStorageBuffer< 1000 > > DynamicCmdsOut;
			
		
			BindTexture(SHADER_SAMPLER0, BASETEXTURE);
			BindTexture(SHADER_SAMPLER1, DEFORMEDTEXTURE);
			BindTexture(SHADER_SAMPLER2, PROJECTEDTEXTURE);


			MaterialFogMode_t fogType = pShaderAPI->GetSceneFogMode();
			int fogIndex = (fogType == MATERIAL_FOG_LINEAR_BELOW_FOG_Z) ? 1 : 0;

			LightState_t lightState = { 0, false, false };
			pShaderAPI->GetDX9LightState(&lightState);
			

			DECLARE_DYNAMIC_VERTEX_SHADER(SimpWoundVertexLit_vs30);
			SET_DYNAMIC_VERTEX_SHADER_COMBO(DOWATERFOG, fogIndex);
			SET_DYNAMIC_VERTEX_SHADER_COMBO(SKINNING, pShaderAPI->GetCurrentNumBones() > 0);
			SET_DYNAMIC_VERTEX_SHADER_COMBO(COMPRESSED_VERTS, (int)vertexCompression);
			SET_DYNAMIC_VERTEX_SHADER_CMD(DynamicCmdsOut, SimpWoundVertexLit_vs30);

			DECLARE_DYNAMIC_PIXEL_SHADER(SimpWoundVertexLit_ps30);
			SET_DYNAMIC_PIXEL_SHADER_COMBO(NUM_LIGHTS, lightState.m_nNumLights);
			SET_DYNAMIC_PIXEL_SHADER_CMD(DynamicCmdsOut, SimpWoundVertexLit_ps30);
			
		
	
			const float diffuseModulation[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
			DynamicCmdsOut.SetPixelShaderConstant(4, diffuseModulation, 1);
			DynamicCmdsOut.SetPixelShaderFogParams(3);

			DynamicCmdsOut.BindStandardTexture(SHADER_SAMPLER3, TEXTURE_NORMALIZATION_CUBEMAP_SIGNED);
			DynamicCmdsOut.SetPixelShaderStateAmbientLightCube(5);
			DynamicCmdsOut.CommitPixelShaderLighting(11);


			bool bWriteDepthToAlpha = pShaderAPI->ShouldWriteDepthToDestAlpha();
			bool bWriteWaterFogToAlpha = (fogType == MATERIAL_FOG_LINEAR_BELOW_FOG_Z);
	
			AssertMsg(!(bWriteDepthToAlpha && bWriteWaterFogToAlpha), "Can't write two values to alpha at the same time.");
	

			float eyePos[4];
			pShaderAPI->GetWorldSpaceCameraPosition(eyePos);
			DynamicCmdsOut.SetPixelShaderConstant(1, eyePos);

			float fPixelFogType = pShaderAPI->GetPixelFogCombo() == 1 ? 1 : 0;
			float fWriteDepthToAlpha = bWriteDepthToAlpha && IsPC() ? 1 : 0;
			float fWriteWaterFogToDestAlpha = (pShaderAPI->GetPixelFogCombo() == 1 && bWriteWaterFogToAlpha) ? 1 : 0;
			float fVertexAlpha = 0;

			// Controls for lerp-style paths through shader code (bump and non-bump have use different register)
			float vShaderControls[4] = { fPixelFogType, fWriteDepthToAlpha, fWriteWaterFogToDestAlpha, fVertexAlpha };
			DynamicCmdsOut.SetPixelShaderConstant(2, vShaderControls, 1);



			VMatrix woundTransform = params[WOUNDTRANSFORM]->GetMatrixValue();
			VMatrix woundTransformInvert;
			const float* woundSize_blendMode = params[WOUNDSIZE_BLENDMODE]->GetVecValue();

			MatrixInverseGeneral(woundTransform, woundTransformInvert);

			DynamicCmdsOut.SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_0, woundTransform.m[0], 4);
			DynamicCmdsOut.SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_4, woundTransformInvert.m[0], 4);
			DynamicCmdsOut.SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_8, woundSize_blendMode, 1);
			DynamicCmdsOut.SetPixelShaderConstant(0, woundSize_blendMode, 1);



			DynamicCmdsOut.End();
			pShaderAPI->ExecuteCommandBuffer(DynamicCmdsOut.Base());
			
		}
	}
	Draw();
}
END_SHADER