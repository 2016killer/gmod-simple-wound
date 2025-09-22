#include "BaseVSShader.h"

#include "shaders/inc/SimpWoundVertexLit_vs30.inc"
#include "shaders/inc/SimpWoundVertexLit_ps30.inc"

#include <istudiorender.h>

BEGIN_VS_SHADER(SimpWoundVertexLit, "Help for SimpWoundVertexLit")
	SHADER_PARAM(WOUNDTRANSFORM, SHADER_PARAM_TYPE_MATRIX, "[1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1]", "Wound transform based on pre-skinned space")
	SHADER_PARAM(WOUNDTRANSFORMINVERT, SHADER_PARAM_TYPE_MATRIX, "[1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1]", "Wound transform invert based on pre-skinned space")
	SHADER_PARAM(WOUNDSIZE, SHADER_PARAM_TYPE_VEC3, "[1, 0.5, 2]", "Wound size, x: deformed radius, y: Additive splash radius, z: Projected color multiplier")

	SHADER_PARAM(DEFORMEDTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh", "Deformed part texture")
	SHADER_PARAM(PROJECTEDTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "sw/blood", "Projected texture")
	
BEGIN_SHADER_PARAMS

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

	if (!params[WOUNDTRANSFORMINVERT]->IsDefined())
	{
		VMatrix mat;
		MatrixSetIdentity(mat);
		params[WOUNDTRANSFORMINVERT]->SetMatrixValue(mat);
	}

	if (!params[WOUNDSIZE]->IsDefined())
	{
		params[WOUNDSIZE]->SetVecValue(1, 0.5, 2);
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
		VMatrix woundTransformInvert = params[WOUNDTRANSFORMINVERT]->GetMatrixValue();
		const float* woundSize = params[WOUNDSIZE]->GetVecValue();

		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_0, woundTransform.m[0], 4);
		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_4, woundTransformInvert.m[0], 4);
		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_8, woundSize, 1);

		
		pShaderAPI->SetPixelShaderConstant(0, woundSize);

		DECLARE_DYNAMIC_VERTEX_SHADER(SimpWound_vs30);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(SKINNING, pShaderAPI->GetCurrentNumBones() > 0);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(COMPRESSED_VERTS, (int)vertexCompression);
		SET_DYNAMIC_VERTEX_SHADER(SimpWound_vs30);
	}	
	Draw();
}
END_SHADER