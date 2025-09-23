// ALL SKIP STATEMENTS THAT AFFECT THIS SHADER!!!
// defined $LIGHTING_PREVIEW && defined $FASTPATH && $LIGHTING_PREVIEW && $FASTPATH

#pragma once
#include "shaderlib/cshader.h"
class SimpWoundVertexLit_vs30_Static_Index
{
public:
	SimpWoundVertexLit_vs30_Static_Index( IShaderShadow* pShaderShadow, IMaterialVar** params )
	{
	}

	int GetIndex() const
	{
		return 0;
	}
};

#define shaderStaticTest_SimpWoundVertexLit_vs30 1


class SimpWoundVertexLit_vs30_Dynamic_Index
{
	unsigned int m_nSKINNING : 2;
	unsigned int m_nCOMPRESSED_VERTS : 2;
	unsigned int m_nDOWATERFOG : 2;
#ifdef _DEBUG
	bool m_bSKINNING : 1;
	bool m_bCOMPRESSED_VERTS : 1;
	bool m_bDOWATERFOG : 1;
#endif	// _DEBUG
public:
	void SetSKINNING( int i )
	{
		Assert( i >= 0 && i <= 1 );
		m_nSKINNING = i;
#ifdef _DEBUG
		m_bSKINNING = true;
#endif	// _DEBUG
	}

	void SetCOMPRESSED_VERTS( int i )
	{
		Assert( i >= 0 && i <= 1 );
		m_nCOMPRESSED_VERTS = i;
#ifdef _DEBUG
		m_bCOMPRESSED_VERTS = true;
#endif	// _DEBUG
	}

	void SetDOWATERFOG( int i )
	{
		Assert( i >= 0 && i <= 1 );
		m_nDOWATERFOG = i;
#ifdef _DEBUG
		m_bDOWATERFOG = true;
#endif	// _DEBUG
	}

	SimpWoundVertexLit_vs30_Dynamic_Index( IShaderDynamicAPI* pShaderAPI )
	{
		m_nSKINNING = 0;
		m_nCOMPRESSED_VERTS = 0;
		m_nDOWATERFOG = 0;
#ifdef _DEBUG
		m_bSKINNING = false;
		m_bCOMPRESSED_VERTS = false;
		m_bDOWATERFOG = false;
#endif	// _DEBUG
	}

	int GetIndex() const
	{
		Assert( m_bSKINNING && m_bCOMPRESSED_VERTS && m_bDOWATERFOG );
		return ( 1 * m_nSKINNING ) + ( 2 * m_nCOMPRESSED_VERTS ) + ( 4 * m_nDOWATERFOG ) + 0;
	}
};

#define shaderDynamicTest_SimpWoundVertexLit_vs30 vsh_forgot_to_set_dynamic_SKINNING + vsh_forgot_to_set_dynamic_COMPRESSED_VERTS + vsh_forgot_to_set_dynamic_DOWATERFOG

