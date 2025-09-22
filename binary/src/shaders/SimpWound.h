#include "BaseVSShader.h"

#include "shaders/inc/SimpWound_vs30.inc"
#include "shaders/inc/SimpWound_ps30.inc"

#include <istudiorender.h>

BEGIN_VS_SHADER(SimpWound, " ")
	SHADER_PARAM(WOUNDTRANSFORM, SHADER_PARAM_TYPE_MATRIX, "[1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1]", "Wound transform based on pre-skinned space")
	SHADER_PARAM(WOUNDTRANSFORMINVERT, SHADER_PARAM_TYPE_MATRIX, "[1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1]", "Wound transform invert based on pre-skinned space")

	SHADER_PARAM(WOUNDTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh", "Wound basetexture")
	SHADER_PARAM(PROJECTEDTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "sw/blood", "Projectedtexture")
	SHADER_PARAM(WOUNDNORMALTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "models/flesh_nrm", "Wound normaltexture")
BEGIN_SHADER_PARAMS

END_SHADER_PARAMS

// Set up anything that is necessary to make decisions in SHADER_FALLBACK.
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
}

SHADER_FALLBACK
{
	return 0;
}


SHADER_INIT
{
	LoadTexture(BASETEXTURE);

	if (params[WOUNDTEXTURE]->IsDefined())
	{
		LoadTexture(WOUNDTEXTURE);
	}

	if (params[PROJECTEDTEXTURE]->IsDefined())
	{
		LoadTexture(PROJECTEDTEXTURE);
	}

	if (params[WOUNDNORMALTEXTURE]->IsDefined())
	{
		LoadTexture(WOUNDNORMALTEXTURE);
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
		BindTexture(SHADER_SAMPLER1, WOUNDTEXTURE);
		BindTexture(SHADER_SAMPLER2, PROJECTEDTEXTURE);
		BindTexture(SHADER_SAMPLER3, WOUNDNORMALTEXTURE);

		VMatrix woundTransform = params[WOUNDTRANSFORM]->GetMatrixValue();
		VMatrix woundTransformInvert = params[WOUNDTRANSFORMINVERT]->GetMatrixValue();
		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_0, woundTransform.m[0], 4);
		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_4, woundTransformInvert.m[0], 4);

		DECLARE_DYNAMIC_VERTEX_SHADER(SimpWound_vs30);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(SKINNING, pShaderAPI->GetCurrentNumBones() > 0);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(COMPRESSED_VERTS, (int)vertexCompression);
		SET_DYNAMIC_VERTEX_SHADER(SimpWound_vs30);
	}	
	Draw();
}
END_SHADER