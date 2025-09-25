#include "BaseVSShader.h"

#include "shaders/inc/EllipClip_vs30.inc"
#include "shaders/inc/EllipClip_ps30.inc"

#include <istudiorender.h>
// 不太懂c++，瞎几把乱写的，仅供参考

BEGIN_VS_SHADER(EllipClip, "Help for EllipClip")

BEGIN_SHADER_PARAMS
	SHADER_PARAM(WOUNDTRANSFORMINVERT, SHADER_PARAM_TYPE_MATRIX, "[1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1]", "Wound transform invert based on pre-skinned space")
	SHADER_PARAM(WOUNDSIZE_BLENDMODE, SHADER_PARAM_TYPE_VEC3, "[1, 0.5, 0]", "Wound size, x: clip range, y: project range, z: use projected texture alpha blend")

	SHADER_PARAM(PROJECTEDTEXTURE, SHADER_PARAM_TYPE_TEXTURE, "sw/blood", "Projected texture")
END_SHADER_PARAMS


SHADER_INIT_PARAMS()
{
	SET_FLAGS2(MATERIAL_VAR2_SUPPORTS_HW_SKINNING);

	if (!params[WOUNDTRANSFORMINVERT]->IsDefined())
	{
		VMatrix mat;
		MatrixSetIdentity(mat);
		params[WOUNDTRANSFORMINVERT]->SetMatrixValue(mat);
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

		int fmt = VERTEX_POSITION | VERTEX_FORMAT_COMPRESSED;
		pShaderShadow->VertexShaderVertexFormat(fmt, 1, 0, 4);

		DECLARE_STATIC_VERTEX_SHADER(EllipClip_vs30);
		SET_STATIC_VERTEX_SHADER(EllipClip_vs30);

		DECLARE_STATIC_PIXEL_SHADER(EllipClip_ps30);
		SET_STATIC_PIXEL_SHADER(EllipClip_ps30);

		DefaultFog();
	}
	DYNAMIC_STATE
	{
		BindTexture(SHADER_SAMPLER0, BASETEXTURE, FRAME);
		BindTexture(SHADER_SAMPLER1, PROJECTEDTEXTURE);

		VMatrix woundTransformInvert = params[WOUNDTRANSFORMINVERT]->GetMatrixValue();
		const float* woundSize_blendMode = params[WOUNDSIZE_BLENDMODE]->GetVecValue();
		

		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_0, woundTransformInvert.m[0], 4);
		pShaderAPI->SetVertexShaderConstant(VERTEX_SHADER_SHADER_SPECIFIC_CONST_4, woundSize_blendMode, 1);
		pShaderAPI->SetPixelShaderConstant(0, woundSize_blendMode);

		DECLARE_DYNAMIC_VERTEX_SHADER(EllipClip_vs30);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(SKINNING, pShaderAPI->GetCurrentNumBones() > 0);
		SET_DYNAMIC_VERTEX_SHADER_COMBO(COMPRESSED_VERTS, (int)vertexCompression);
		SET_DYNAMIC_VERTEX_SHADER(EllipClip_vs30);
	}	
	Draw();
}
END_SHADER