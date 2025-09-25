// ALL SKIP STATEMENTS THAT AFFECT THIS SHADER!!!
// defined $LIGHTING_PREVIEW && defined $FASTPATH && $LIGHTING_PREVIEW && $FASTPATH

#pragma once
#include "shaderlib/cshader.h"
class EllipClip_vs30_Static_Index
{
public:
	EllipClip_vs30_Static_Index(  )
	{
	}

	int GetIndex() const
	{
		return 0;
	}
};

#define shaderStaticTest_EllipClip_vs30 1


class EllipClip_vs30_Dynamic_Index
{
	unsigned int m_nSKINNING : 2;
	unsigned int m_nCOMPRESSED_VERTS : 2;
#ifdef _DEBUG
	bool m_bSKINNING : 1;
	bool m_bCOMPRESSED_VERTS : 1;
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

	EllipClip_vs30_Dynamic_Index(  )
	{
		m_nSKINNING = 0;
		m_nCOMPRESSED_VERTS = 0;
#ifdef _DEBUG
		m_bSKINNING = false;
		m_bCOMPRESSED_VERTS = false;
#endif	// _DEBUG
	}

	int GetIndex() const
	{
		Assert( m_bSKINNING && m_bCOMPRESSED_VERTS );
		return ( 1 * m_nSKINNING ) + ( 2 * m_nCOMPRESSED_VERTS ) + 0;
	}
};

#define shaderDynamicTest_EllipClip_vs30 vsh_forgot_to_set_dynamic_SKINNING + vsh_forgot_to_set_dynamic_COMPRESSED_VERTS

