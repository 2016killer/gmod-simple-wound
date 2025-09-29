//	DYNAMIC: "SKINNING"					"0..1"
//  DYNAMIC: "COMPRESSED_VERTS"			"0..1"

#include "common_vs_fxc.h"

// 不太懂hlsl，瞎几把乱写的，仅供参考

static const bool g_bSkinning		= SKINNING ? true : false;

const float4x4 mWoundTransform			:  register( SHADER_SPECIFIC_CONST_0 );
const float4x4 mWoundTransformInvert	:  register( SHADER_SPECIFIC_CONST_4 );
const float3 vWoundSize_blendMode		:  register( SHADER_SPECIFIC_CONST_8 );

struct VS_INPUT
{
	float4 vPos						: POSITION;
	float2 vBaseTexCoord			: TEXCOORD0;
	float4 vBoneWeights				: BLENDWEIGHT;
	float4 vBoneIndices				: BLENDINDICES;
};

struct VS_OUTPUT
{
    float4 vProjPos					: POSITION;	
	float2 vBaseTexCoord			: TEXCOORD0;
	float3 vWoundData 				: TEXCOORD1; 
};


VS_OUTPUT main( const VS_INPUT v )
{
	VS_OUTPUT o = ( VS_OUTPUT )0;

	// 计算相对坐标与距离, yz作为投影纹理坐标(x轴作为投影轴)
	float4 vLocalPos = mul( v.vPos, mWoundTransformInvert );
	float fDist = length( vLocalPos.xyz );
	o.vWoundData = float3(vLocalPos.yz, fDist);

	// 顶点变形(球面投影), 方向为x轴负方向
	vLocalPos.x = -abs(vLocalPos.x);
	float4 vPosWound = mul( 
		float4(vLocalPos.xyz / max(fDist, 1e-6), 1), 
		mWoundTransform 
	);
	vPosWound.w = 1;
	
	// vWoundSize_blendMode.x决定变形的范围
	float4 vPosition = lerp(
		v.vPos, 
		vPosWound, 
		step(fDist, vWoundSize_blendMode.x)
	);

	// 蒙皮一条龙
	float3 worldPos;
	SkinPosition( 
		g_bSkinning, 
		vPosition,
		v.vBoneWeights, v.vBoneIndices,
		worldPos );

	float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	o.vProjPos = vProjPos;

	o.vBaseTexCoord = v.vBaseTexCoord;

	return o;
}