const pkgs = [
  'pkce-challenge',
  'lodash',
  'pdf-parse',
  'filenamify-url',
  '@mozilla/readability',
  'jsdom',
  'aws-transcription-to-vtt',
  'puppeteer',
  'tweetnacl',
  'gtfs-realtime-bindings',
  'node-fetch',
  '@itustudentcouncil/n8n-nodes-basecamp',
  '@n8n-zengchao/n8n-nodes-browserless',
  'n8n-nodes-advanced-flow',
  'n8n-nodes-browser',
  'n8n-nodes-carbonejs',
  'n8n-nodes-globals',
  'n8n-nodes-logger',
  'n8n-nodes-mcp',
  'n8n-nodes-odata',
  'n8n-nodes-puppeteer-extended',
  'n8n-nodes-text-manipulation',
  'n8n-nodes-turndown-html-to-markdown',
  'n8n-nodes-tweetnacl',
  'n8n-nodes-webpage-content-extractor',
  'n8n-nodes-websockets-lite',
  'n8n-openapi-node'
];

async function inspect(name) {
  try {
    const mod = require(name);
    console.log('↪', name, '→', Object.keys(mod).length ?
      `exports: ${Object.keys(mod).join(', ')}` :
      `${typeof mod} (no named exports)`);
    
    // Special check for pkce-challenge to see what's at .index
    if (name === 'pkce-challenge') {
      console.log('  └─ .index:', typeof mod.index, mod.index ? `(${mod.index.constructor.name})` : '(undefined)');
      if (mod.index) {
        try {
          const instance = new mod.index();
          console.log('  └─ new mod.index() works!');
        } catch (e) {
          console.log('  └─ new mod.index() failed:', e.message);
        }
      }
    }
  } catch (e) {
    console.log('✘', name, '→ require failed:', e.message);
  }
}

async function main() {
  console.log('=== Package Inspection Report ===\n');
  for (const pkg of pkgs) {
    await inspect(pkg);
  }
  
  console.log('\n=== Additional pkce-challenge tests ===');
  try {
    const pkceMod = require('pkce-challenge');
    console.log('pkce-challenge module type:', typeof pkceMod);
    console.log('pkce-challenge keys:', Object.keys(pkceMod));
    
    // Try different import patterns
    console.log('\nTrying different import patterns:');
    
    // Pattern 1: Direct constructor
    try {
      const instance1 = new pkceMod();
      console.log('✓ new pkceMod() works');
    } catch (e) {
      console.log('✘ new pkceMod() failed:', e.message);
    }
    
    // Pattern 2: .default
    try {
      const instance2 = new pkceMod.default();
      console.log('✓ new pkceMod.default() works');
    } catch (e) {
      console.log('✘ new pkceMod.default() failed:', e.message);
    }
    
    // Pattern 3: .index (the failing one)
    try {
      const instance3 = new pkceMod.index();
      console.log('✓ new pkceMod.index() works');
    } catch (e) {
      console.log('✘ new pkceMod.index() failed:', e.message);
    }
    
  } catch (e) {
    console.log('Failed to require pkce-challenge:', e.message);
  }
}

main().catch(console.error); 