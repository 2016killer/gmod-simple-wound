#pragma once
#include "shaders/SimpWound.h"
#include "shaders/SimpWoundVertexLit.h"
#include "shaders/EllipClip.h"
#include "shaders/EllipClipVertexLit.h"
#include "shaders/VertexLitInvert.h"
#include "shaders/DepthTexClip.h"
#include "shaders/DepthTexClipVertexLit.h"
// This file is intentionally overcommented because of how undocumented source shaders are
// Note that this is *my* understanding of how this works. I very well could be butchering what this actually is doing

#include "shadersystem.h"	// A conglomeration of valve structs shoved into a file.
// ^ This file gives us access to CShaderSystem..
// CShaderSystem has privated variables (which we edit and make public) to get access to the internal shader DLLs (directories)
// With these 'DLLs' made public, we can add our own shaders into the materialsystem without having to go through valves fucked up API

// these externals MUST be defined (NOT NULL) BEFORE inserting shaders into the materialsystem or you WILL crash!
extern IMaterialSystemHardwareConfig* g_pHardwareConfig = NULL;
extern const MaterialSystem_Config_t* g_pConfig = NULL;
IShaderSystem* g_pSLShaderSystem; // I literally have no idea where this is defined in the source sdk. Fails to compile without it

CShaderSystem::ShaderDLLInfo_t* shaderlibdll = NULL;	// our shader "directory"
//int m_ShaderDLLs_index;

#ifndef _LINUX
#define INTERFACE_MATERIALSYSTEM "materialsystem"
#else
#define INTERFACE_MATERIALSYSTEM "linux64/materialsystem_client"
#endif

// returns true if successful, false otherwise
bool inject_shaders() {
	// Load source interfaces for personal use
	if (!Sys_LoadInterface(INTERFACE_MATERIALSYSTEM, MATERIALSYSTEM_HARDWARECONFIG_INTERFACE_VERSION, NULL, (void**)&g_pHardwareConfig)) return false;
	if (!Sys_LoadInterface(INTERFACE_MATERIALSYSTEM, MATERIALSYSTEM_CONFIG_VERSION, NULL, (void**)&g_pConfig)) return false;
	if (!Sys_LoadInterface(INTERFACE_MATERIALSYSTEM, SHADERSYSTEM_INTERFACE_VERSION, NULL, (void**)&g_pSLShaderSystem)) return false;

	// imagine not being able to run dx9
	if (g_pHardwareConfig->GetDXSupportLevel() < 90) return false;
	// ^this check isnt technically required, but I only compiled my shaders for dx9 and above

	// this will cast the memory given by the valve interfaces to an edited CShaderSystem class which allows us to use privated variables which otherwise would be hidden
	CShaderSystem* s_ShaderSystem = (CShaderSystem*)g_pSLShaderSystem;

	// Create new shader directory (dll)
	//m_ShaderDLLs_index = s_ShaderSystem->m_ShaderDLLs.AddToTail();	// adding more than 8 TOTAL shader dlls crashes the game!!!
	//shaderlibdll = &s_ShaderSystem->m_ShaderDLLs[m_ShaderDLLs_index];

	// if the above code is uncommented, m_ShaderDLLs_index ends up being equal to 7 (I think the maximum allowed number of shader directories)
	// im not sure what indexes 0-6 actually mean in terms of the gmod source code but ive found injecting into 0 tends to be the most stable
	// in theory you could have an unlimited amount of shaders on this index, you just need to make sure to remove them on module unload
	shaderlibdll = &s_ShaderSystem->m_ShaderDLLs[0];

	//shaderlibdll->m_pFileName = strdup("gwater_shaders.dll");	// name likely doesnt matter
	//shaderlibdll->m_bModShaderDLL = true;	
	
	// Insert our shaders into the shader directory
	// you need the COMPILED .vcs shaders in GarrysMod/garrysmod/shaders/fxc for the shaders to appear ingame!
	shaderlibdll->m_ShaderDict.Insert(SimpWound::s_Name, &SimpWound::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(SimpWoundVertexLit::s_Name, &SimpWoundVertexLit::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(EllipClip::s_Name, &EllipClip::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(EllipClipVertexLit::s_Name, &EllipClipVertexLit::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(VertexLitInvert::s_Name, &VertexLitInvert::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(DepthTexClip::s_Name, &DepthTexClip::s_ShaderInstance);
	shaderlibdll->m_ShaderDict.Insert(DepthTexClipVertexLit::s_Name, &DepthTexClipVertexLit::s_ShaderInstance);
	
	return true;
}

bool eject_shaders() {
	// Dont forget to free shaders or you crash on reload!
	if (shaderlibdll) {
		// Remove inserted shader(s)
		shaderlibdll->m_ShaderDict.Remove(SimpWound::s_Name);
		shaderlibdll->m_ShaderDict.Remove(SimpWoundVertexLit::s_Name);
		shaderlibdll->m_ShaderDict.Remove(EllipClip::s_Name);
		shaderlibdll->m_ShaderDict.Remove(EllipClipVertexLit::s_Name);
		shaderlibdll->m_ShaderDict.Remove(VertexLitInvert::s_Name);
		shaderlibdll->m_ShaderDict.Remove(DepthTexClip::s_Name);
		shaderlibdll->m_ShaderDict.Remove(DepthTexClipVertexLit::s_Name);
		
		//shaderlibdll->m_ShaderDict.PurgeAndDeleteElements();

		// Remove our added shader directory (dll?) in material system
		//s_ShaderSystem->m_ShaderDLLs.Remove(m_ShaderDLLs_index);

		return true;
	}

	return false;
}
