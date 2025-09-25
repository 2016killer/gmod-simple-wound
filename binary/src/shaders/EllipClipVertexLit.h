#include "BaseVSShader.h"

#include "shaders/inc/EllipClipVertexLit_vs30.inc"
#include "shaders/inc/EllipClipVertexLit_ps30.inc"

#include <istudiorender.h>
#include "commandbuilder.h"
// 不太懂c++，瞎几把乱写的，仅供参考
// 自定义逻辑部分用 SimpWound圈起，其他都是Ctrl C+V Value的源码。

BEGIN_VS_SHADER(EllipClipVertexLit, "Help for EllipClipVertexLit")

BEGIN_SHADER_PARAMS
	SHADER_PARAM(WOUNDTRANSFORMINVERT, SHADER_PARAM_TYPE_MATRIX, "[1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1]", "Wound transform invert based on pre-skinned space")
	SHADER_PARAM(WOUNDSIZE_BLENDMODE, SHADER_PARAM_TYPE_VEC3, "[1, 0.5, 0]", "Wound size, x: deformed range, y: project range, z: use projected texture alpha blend")

	SHADER_PARAM(PROJECTEDTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh", "Projected texture")
END_SHADER_PARAMS


SHADER_INIT_PARAMS()
{
	SET_FLAGS2(MATERIAL_VAR2_SUPPORTS_HW_SKINNING);
	SET_FLAGS2(MATERIAL_VAR2_LIGHTING_VERTEX_LIT);

	if (!params[WOUNDTRANSFORMINVERT]->IsDefined())
	{
		VMatrix mat;
		MatrixSetIdentity(mat);
		params[WOUNDTRANSFORMINVERT]->SetMatrixValue(mat);
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

	if (params[PROJECTEDTEXTURE]->IsDefined())
	{
		LoadTexture(PROJECTEDTEXTURE);
	}

}

SHADER_DRAW
{
	SHADOW_STATE
	{
		bool bHasFlashlight = UsingFlashlight(params);

		if (bHasFlashlight)
		{
			pShaderShadow->EnableTexture(SHADER_SAMPLER4, true);	// Depth texture
			pShaderShadow->SetShadowDepthFiltering(SHADER_SAMPLER4);
			pShaderShadow->EnableTexture(SHADER_SAMPLER5, true);	// Noise map
			pShaderShadow->EnableTexture(SHADER_SAMPLER3, true);	// Flashlight cookie
			pShaderShadow->EnableSRGBRead(SHADER_SAMPLER3, true);
		}

		pShaderShadow->EnableTexture(SHADER_SAMPLER0, true);
		pShaderShadow->EnableTexture(SHADER_SAMPLER2, true);


		int fmt = VERTEX_POSITION | VERTEX_FORMAT_COMPRESSED;
		
		pShaderShadow->VertexShaderVertexFormat(fmt, 1, NULL, 0);


		DECLARE_STATIC_VERTEX_SHADER(EllipClipVertexLit_vs30);
		SET_STATIC_VERTEX_SHADER_COMBO(FLASHLIGHT, bHasFlashlight);
		SET_STATIC_VERTEX_SHADER(EllipClipVertexLit_vs30);

		DECLARE_STATIC_PIXEL_SHADER(EllipClipVertexLit_ps30);
		SET_STATIC_PIXEL_SHADER_COMBO(FLASHLIGHT, bHasFlashlight);
		SET_STATIC_PIXEL_SHADER(EllipClipVertexLit_ps30);

		
		if (bHasFlashlight && !IsX360())
		{
			FogToBlack();
		}
		else
		{
			DefaultFog();
		}
	}
	DYNAMIC_STATE
	{
		CCommandBufferBuilder< CFixedCommandStorageBuffer< 1000 > > DynamicCmdsOut;

		BindTexture(SHADER_SAMPLER0, BASETEXTURE);
		BindTexture(SHADER_SAMPLER2, PROJECTEDTEXTURE);


		MaterialFogMode_t fogType = pShaderAPI->GetSceneFogMode();
		int fogIndex = (fogType == MATERIAL_FOG_LINEAR_BELOW_FOG_Z) ? 1 : 0;


		DECLARE_DYNAMIC_VERTEX_SHADER(EllipClipVertexLit_vs30);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(DOWATERFOG, fogIndex);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(SKINNING, pShaderAPI->GetCurrentNumBones() > 0);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(COMPRESSED_VERTS, (int)vertexCompression);
		SET_DYNAMIC_VERTEX_SHADER_CMD(DynamicCmdsOut, EllipClipVertexLit_vs30);
			
		
		DynamicCmdsOut.SetPixelShaderFogParams(3);

		bool bHasFlashlight = UsingFlashlight(params);

		if (bHasFlashlight)
		{
			// Tweaks associated with a given flashlight
			VMatrix worldToTexture;
			const FlashlightState_t& flashlightState = pShaderAPI->GetFlashlightState(worldToTexture);
			float tweaks[4];
			tweaks[0] = flashlightState.m_flShadowFilterSize / flashlightState.m_flShadowMapResolution;
			tweaks[1] = ShadowAttenFromState(flashlightState);
			HashShadow2DJitter(flashlightState.m_flShadowJitterSeed, &tweaks[2], &tweaks[3]);
			pShaderAPI->SetPixelShaderConstant(4, tweaks, 1);

			//Dimensions of screen, used for screen-space noise map sampling
			float vScreenScale[4] = { 1280.0f / 32.0f, 720.0f / 32.0f, 0, 0 };
			int nWidth, nHeight;
			pShaderAPI->GetBackBufferDimensions(nWidth, nHeight);
			vScreenScale[0] = (float)nWidth / 32.0f;
			vScreenScale[1] = (float)nHeight / 32.0f;
			pShaderAPI->SetPixelShaderConstant(31, vScreenScale, 1);
		}

		bool bFlashlightNoLambert = false;

		if (bHasFlashlight)
		{
			VMatrix worldToTexture;
			ITexture* pFlashlightDepthTexture;
			FlashlightState_t state = pShaderAPI->GetFlashlightStateEx(worldToTexture, &pFlashlightDepthTexture);

			if (pFlashlightDepthTexture && g_pConfig->ShadowDepthTexture() && state.m_bEnableShadows)
			{
				BindTexture(SHADER_SAMPLER4, pFlashlightDepthTexture, 0);
				DynamicCmdsOut.BindStandardTexture(SHADER_SAMPLER5, TEXTURE_SHADOW_NOISE_2D);
			}

			SetFlashLightColorFromState(state, pShaderAPI, 11, bFlashlightNoLambert);

			//Assert(info.m_nFlashlightTexture >= 0 && info.m_nFlashlightTextureFrame >= 0);
			BindTexture(SHADER_SAMPLER3, state.m_pSpotlightTexture, state.m_nSpotlightTextureFrame);
		}
		
		if (bHasFlashlight)
		{
			VMatrix worldToTexture;
			const FlashlightState_t& flashlightState = pShaderAPI->GetFlashlightState(worldToTexture);
			SetFlashLightColorFromState(flashlightState, pShaderAPI, 11, bFlashlightNoLambert);

			//pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_9, worldToTexture.Base(), 4);

			BindTexture(SHADER_SAMPLER3, flashlightState.m_pSpotlightTexture, flashlightState.m_nSpotlightTextureFrame);

			float atten_pos[8];
			atten_pos[0] = flashlightState.m_fConstantAtten;			// Set the flashlight attenuation factors
			atten_pos[1] = flashlightState.m_fLinearAtten;
			atten_pos[2] = flashlightState.m_fQuadraticAtten;
			atten_pos[3] = flashlightState.m_FarZ;
			atten_pos[4] = flashlightState.m_vecLightOrigin[0];			// Set the flashlight origin
			atten_pos[5] = flashlightState.m_vecLightOrigin[1];
			atten_pos[6] = flashlightState.m_vecLightOrigin[2];
			atten_pos[7] = 1.0f;
			DynamicCmdsOut.SetPixelShaderConstant(5, atten_pos, 2);

			DynamicCmdsOut.SetPixelShaderConstant(7, worldToTexture.Base(), 4);
		}


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



		// ------SimpWound
		
		//VMatrix woundTransform = params[WOUNDTRANSFORM]->GetMatrixValue();
		//VMatrix woundTransformInvert;
		//MatrixInverseGeneral(woundTransform, woundTransformInvert);
		VMatrix woundTransformInvert = params[WOUNDTRANSFORMINVERT]->GetMatrixValue(); 

		const float* woundSize_blendMode = params[WOUNDSIZE_BLENDMODE]->GetVecValue();

		

	/*	DynamicCmdsOut.SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_0, woundTransform.m[0], 4);*/
		DynamicCmdsOut.SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_0, woundTransformInvert.m[0], 4);
		DynamicCmdsOut.SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_4, woundSize_blendMode, 1);
		DynamicCmdsOut.SetPixelShaderConstant(0, woundSize_blendMode, 1);
		// ------SimpWound


		DynamicCmdsOut.End();
		pShaderAPI->ExecuteCommandBuffer(DynamicCmdsOut.Base());
	}
	Draw();
}
END_SHADER