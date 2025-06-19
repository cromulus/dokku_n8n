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
  'gtts-realtime-bindings',
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
  'n8n-nodes-graphiti',
  'n8n-nodes-twenty',
  'n8n-nodes-webpage-content-extractor',
  'n8n-nodes-websockets-lite'
];

function checkDependsOnPkce(packageName) {
  try {
    const packagePath = `/tmp/n8n-nodes/node_modules/${packageName}/package.json`;
    const fs = require('fs');
    if (fs.existsSync(packagePath)) {
      const pkg = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
      const allDeps = {
        ...pkg.dependencies,
        ...pkg.devDependencies,
        ...pkg.peerDependencies
      };
      return Object.keys(allDeps).includes('pkce-challenge');
    }
  } catch (e) {
    // Ignore errors
  }
  return false;
}

async function inspect(name) {
  const dependsOnPkce = checkDependsOnPkce(name);
  
  try {
    console.log(`\n🔍 Testing package: ${name}${dependsOnPkce ? ' (depends on pkce-challenge)' : ''}`);
    
    const mod = require(name);
    
    console.log('✅ require() successful');
    console.log(`   Type: ${typeof mod}`);
    console.log(`   Keys: ${Object.keys(mod).length > 0 ? Object.keys(mod).slice(0, 10).join(', ') + (Object.keys(mod).length > 10 ? '...' : '') : 'none'}`);
    
  } catch (e) {
    console.log('❌ require() failed');
    console.log(`   Error: ${e.message}`);
    console.log(`   Stack: ${e.stack.split('\n')[0]}`);
    
    // Check if this is specifically the pkce-challenge constructor error
    if (e.message.includes('is not a constructor') && 
        (e.stack.includes('pkce-challenge') || e.message.includes('index'))) {
      console.log('🎯 THIS IS THE PACKAGE CAUSING THE PKCE-CHALLENGE ISSUE!');
      console.log(`   Full error stack:`);
      console.log(e.stack.split('\n').slice(0, 5).map(line => `   ${line}`).join('\n'));
    }
    
    return false;
  }
  
  return true;
}

async function deepInspectPkceUsage() {
  console.log('\n=== Deep PKCE Analysis ===');
  
  // Check which packages actually have pkce-challenge in their node_modules
  const fs = require('fs');
  const path = require('path');
  
  try {
    const nodeModulesPath = '/tmp/n8n-nodes/node_modules';
    const dirs = fs.readdirSync(nodeModulesPath);
    
    for (const dir of dirs) {
      if (dir.startsWith('.') || dir.startsWith('@')) continue;
      
      const pkceInSubModule = path.join(nodeModulesPath, dir, 'node_modules', 'pkce-challenge');
      if (fs.existsSync(pkceInSubModule)) {
        console.log(`📦 ${dir} has its own pkce-challenge dependency`);
      }
    }
    
    // Check @scoped packages
    const scopedDirs = dirs.filter(d => d.startsWith('@'));
    for (const scopedDir of scopedDirs) {
      const scopePath = path.join(nodeModulesPath, scopedDir);
      const subDirs = fs.readdirSync(scopePath);
      for (const subDir of subDirs) {
        const pkceInSubModule = path.join(scopePath, subDir, 'node_modules', 'pkce-challenge');
        if (fs.existsSync(pkceInSubModule)) {
          console.log(`📦 ${scopedDir}/${subDir} has its own pkce-challenge dependency`);
        }
      }
    }
    
  } catch (e) {
    console.log('Error during deep inspection:', e.message);
  }
}

async function main() {
  console.log('=== Enhanced Package Inspection Report ===');
  
  let successfulPackages = [];
  let failedPackages = [];
  
  for (const pkg of pkgs) {
    const success = await inspect(pkg);
    if (success) {
      successfulPackages.push(pkg);
    } else {
      failedPackages.push(pkg);
    }
  }
  
  await deepInspectPkceUsage();
  
  console.log('\n=== Summary ===');
  console.log(`✅ Successful packages (${successfulPackages.length}): ${successfulPackages.slice(0, 5).join(', ')}${successfulPackages.length > 5 ? '...' : ''}`);
  console.log(`❌ Failed packages (${failedPackages.length}): ${failedPackages.join(', ')}`);
  
  // Test pkce-challenge one more time to confirm it works
  console.log('\n=== Final PKCE Test ===');
  try {
    const pkce = require('pkce-challenge');
    const challenge = pkce.generateChallenge();
    console.log('✅ pkce-challenge.generateChallenge() works correctly');
    console.log(`   Challenge created: ${challenge.codeChallenge.substring(0, 20)}...`);
  } catch (e) {
    console.log('❌ pkce-challenge.generateChallenge() failed:', e.message);
  }
}

main().catch(console.error); 