#include "BaseVSShader.h"

#include "shaders/inc/SimpWound_vs30.inc"
#include "shaders/inc/SimpWound_ps30.inc"

#include <istudiorender.h>

BEGIN_VS_SHADER(SimpWound, "Help for SimpWound")

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
		params[WOUNDSIZE_BLENDMODE]->SetVecValue(1, 0.5, 0);
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

		int fmt = VERTEX_POSITION | VERTEX_FORMAT_COMPRESSED;
		pShaderShadow->VertexShaderVertexFormat(fmt, 1, 0, 4);

		DECLARE_STATIC_VERTEX_SHADER(SimpWound_vs30);
		SET_STATIC_VERTEX_SHADER(SimpWound_vs30);

		DECLARE_STATIC_PIXEL_SHADER(SimpWound_ps30);
		SET_STATIC_PIXEL_SHADER(SimpWound_ps30);

		DefaultFog();
	}
	DYNAMIC_STATE
	{
		BindTexture(SHADER_SAMPLER0, BASETEXTURE, FRAME);
		BindTexture(SHADER_SAMPLER1, DEFORMEDTEXTURE);
		BindTexture(SHADER_SAMPLER2, PROJECTEDTEXTURE);

		VMatrix woundTransform = params[WOUNDTRANSFORM]->GetMatrixValue();
		VMatrix woundTransformInvert;
		const float* woundSize_blendMode = params[WOUNDSIZE_BLENDMODE]->GetVecValue();
		
		MatrixInverseGeneral(woundTransform, woundTransformInvert);


		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_0, woundTransform.m[0], 4);
		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_4, woundTransformInvert.m[0], 4);
		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_8, woundSize_blendMode, 1);
		pShaderAPI->SetPixelShaderConstant(0, woundSize_blendMode);

		DECLARE_DYNAMIC_VERTEX_SHADER(SimpWound_vs30);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(SKINNING, pShaderAPI->GetCurrentNumBones() > 0);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(COMPRESSED_VERTS, (int)vertexCompression);
		SET_DYNAMIC_VERTEX_SHADER(SimpWound_vs30);
	}	
	Draw();
}
END_SHADER