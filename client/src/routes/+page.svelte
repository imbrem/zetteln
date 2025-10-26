<script lang="ts">
	import { onMount } from 'svelte';

	let version = $state<string | null>(null);
	let database = $state<string | null>(null);
	let loading = $state(true);
	let error = $state<string | null>(null);

	onMount(async () => {
		try {
			const response = await fetch('/api/version');
			if (!response.ok) {
				throw new Error(`HTTP error! status: ${response.status}`);
			}
			const data = await response.json();
			version = data.version;
			database = data.database;
		} catch (e) {
			error = e instanceof Error ? e.message : 'Unknown error';
			console.error('Failed to fetch version:', e);
		} finally {
			loading = false;
		}
	});
</script>

<main>
	<h1>🗂️ Zetteln</h1>
	<p class="subtitle">Your personal zettelkasten system</p>

	<div class="card">
		<h2>System Information</h2>
		
		{#if loading}
			<p class="loading">Loading version information...</p>
		{:else if error}
			<p class="error">Error: {error}</p>
		{:else}
			<div class="info">
				<div class="info-item">
					<strong>API Version:</strong>
					<span class="version">{version}</span>
				</div>
				<div class="info-item">
					<strong>Database:</strong>
					<span class="database">{database}</span>
				</div>
			</div>
		{/if}
	</div>

	<div class="card">
		<h2>Welcome!</h2>
		<p>
			This is your zettelkasten application powered by:
		</p>
		<ul>
			<li><strong>Dolt</strong> - Version-controlled database</li>
			<li><strong>Rust</strong> - High-performance API</li>
			<li><strong>SvelteKit</strong> - Modern frontend</li>
		</ul>
	</div>
</main>

<style>
	:global(body) {
		margin: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		min-height: 100vh;
	}

	main {
		padding: 2rem;
		display: flex;
		flex-direction: column;
		align-items: center;
		min-height: 100vh;
		max-width: 800px;
		margin: 0 auto;
	}

	h1 {
		color: white;
		font-size: 3rem;
		margin: 0 0 0.5rem 0;
		text-align: center;
		text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
	}

	.subtitle {
		color: rgba(255, 255, 255, 0.9);
		text-align: center;
		font-size: 1.2rem;
		margin: 0 0 2rem 0;
	}

	.card {
		background: white;
		border-radius: 12px;
		padding: 2rem;
		margin-bottom: 1.5rem;
		box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
		width: 100%;
	}

	h2 {
		margin: 0 0 1rem 0;
		color: #333;
		font-size: 1.5rem;
	}

	.info {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.info-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 0.75rem;
		background: #f5f5f5;
		border-radius: 6px;
	}

	.version, .database {
		color: #667eea;
		font-family: 'Monaco', 'Courier New', monospace;
		font-weight: 600;
	}

	.loading {
		color: #666;
		font-style: italic;
	}

	.error {
		color: #dc3545;
		padding: 1rem;
		background: #f8d7da;
		border-radius: 6px;
		border: 1px solid #f5c6cb;
	}

	ul {
		margin: 1rem 0;
		padding-left: 1.5rem;
	}

	li {
		margin: 0.5rem 0;
		color: #555;
	}

	li strong {
		color: #333;
	}
</style>

