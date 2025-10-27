import { defineConfig } from 'vitest/config';
import { loadEnv } from 'vite';
import { sveltekit } from '@sveltejs/kit/vite';

export default defineConfig(({ mode }) => {
	// Load env file from parent directory
	const env = loadEnv(mode, '../', '');
	
	// Allow custom API URL for development, otherwise use local Docker
	const API_URL = env.VITE_API_URL || `http://localhost:${env.HOST_HTTP_PORT || '8000'}`;

	return {
		plugins: [sveltekit()],
		server: {
			proxy: {
				'/api': {
					target: API_URL,
					changeOrigin: true,
					ws: true  // Enable WebSocket proxying
				}
			}
		},
		test: {
		expect: { requireAssertions: true },
		projects: [
			{
				extends: './vite.config.ts',
				test: {
					name: 'client',
					environment: 'browser',
					browser: {
						enabled: true,
						provider: 'playwright',
						instances: [{ browser: 'chromium' }]
					},
					include: ['src/**/*.svelte.{test,spec}.{js,ts}'],
					exclude: ['src/lib/server/**'],
					setupFiles: ['./vitest-setup-client.ts']
				}
			},
			{
				extends: './vite.config.ts',
				test: {
					name: 'server',
					environment: 'node',
					include: ['src/**/*.{test,spec}.{js,ts}'],
					exclude: ['src/**/*.svelte.{test,spec}.{js,ts}']
				}
			}
		]
	}
	};
});
