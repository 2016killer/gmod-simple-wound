#include "cdll_client_int.h"

#include "GarrysMod/Lua/LuaShared.h"
#include "GarrysMod/Lua/Interface.h"

#include "shader_inject.h"

using namespace GarrysMod::Lua;

GMOD_MODULE_OPEN() {
	Msg("=====================================\n");
	Msg("[SimpWound]: Injecting shaders\n");
	if (!inject_shaders())
		LUA->ThrowError("[SimpWound Internal Error]: C++ Shadersystem failed to load!");
	Msg("[SimpWound]: VERSION 1.0.1\n");
	Msg("=====================================\n");
	return 0;
}


GMOD_MODULE_CLOSE() {

	// Defined in 'shader_inject.h'
	eject_shaders();

	return 0;
}