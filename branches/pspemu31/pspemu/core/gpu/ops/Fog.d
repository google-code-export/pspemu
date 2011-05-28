module pspemu.core.gpu.ops.Fog;

template Gpu_Fog() {
	/**
	 * Set current Fog
	 *
	 * @param near  - 
	 * @param far   - 
	 * @param color - 0x00RRGGBB
	 **/
	// void sceGuFog(float near, float far, unsigned int color); // OP_FCOL + OP_FFAR + OP_FDIST

	// Fog enable (GU_FOG)
	auto OP_FGE() { gpu.state.fog.enabled = command.bool1; /* fogMode = GL_LINEAR; fogHint = GL_DONT_CARE; fogDensity = 0.1; */ }

	// Fog COLor
	auto OP_FCOL() {
		gpu.state.fog.color.rgb[] = command.float3[];
		gpu.state.fog.color.a = 1.0;
	}

	// Fog FAR
	auto OP_FFAR() {
		gpu.state.fog.end = command.float1;
	}

	// Fog DISTance
	auto OP_FDIST() {
		gpu.state.fog.dist = command.float1;
	}
}
