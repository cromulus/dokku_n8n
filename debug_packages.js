const fs = require('fs');
const path = require('path');

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

function findJSFiles(dir, files = []) {
  try {
    const items = fs.readdirSync(dir);
    for (const item of items) {
      const fullPath = path.join(dir, item);
      const stat = fs.statSync(fullPath);
      if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
        findJSFiles(fullPath, files);
      } else if (item.endsWith('.js') || item.endsWith('.ts')) {
        files.push(fullPath);
      }
    }
  } catch (e) {
    // Ignore errors
  }
  return files;
}

function searchForPkceUsage(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Look for the problematic pattern: require(...).index
    const problematicPatterns = [
      /require\([^)]*pkce-challenge[^)]*\)\.index/g,
      /new.*require\([^)]*pkce-challenge[^)]*\)\.index/g,
      /pkce-challenge.*\.index/g,
      /new.*pkce.*index/g
    ];
    
    const results = [];
    
    for (const pattern of problematicPatterns) {
      const matches = content.matchAll(pattern);
      for (const match of matches) {
        const lines = content.substring(0, match.index).split('\n');
        const lineNumber = lines.length;
        const lineContent = lines[lines.length - 1] + content.substring(match.index).split('\n')[0];
        
        results.push({
          pattern: pattern.source,
          match: match[0],
          lineNumber,
          lineContent,
          context: content.substring(Math.max(0, match.index - 100), match.index + 100)
        });
      }
    }
    
    // Also check for any pkce-challenge usage
    if (content.includes('pkce-challenge')) {
      const pkceLines = content.split('\n')
        .map((line, i) => ({ line, number: i + 1 }))
        .filter(({ line }) => line.includes('pkce-challenge'));
      
      return { problematic: results, allPkceUsage: pkceLines };
    }
    
    return { problematic: results, allPkceUsage: [] };
  } catch (e) {
    return { problematic: [], allPkceUsage: [], error: e.message };
  }
}

async function analyzePackageFiles(packageName) {
  const packagePath = `/tmp/n8n-nodes/node_modules/${packageName}`;
  
  if (!fs.existsSync(packagePath)) {
    return { error: 'Package not found' };
  }
  
  console.log(`\n🔍 Analyzing files in: ${packageName}`);
  
  // Find all JS/TS files
  const jsFiles = findJSFiles(packagePath);
  console.log(`   Found ${jsFiles.length} JS/TS files`);
  
  const results = {
    packageName,
    filesWithPkce: [],
    problematicFiles: [],
    totalFiles: jsFiles.length
  };
  
  for (const file of jsFiles) {
    const analysis = searchForPkceUsage(file);
    
    if (analysis.allPkceUsage.length > 0) {
      console.log(`   📄 ${path.relative(packagePath, file)} uses pkce-challenge`);
      results.filesWithPkce.push({
        file: path.relative(packagePath, file),
        fullPath: file,
        pkceUsage: analysis.allPkceUsage,
        problematic: analysis.problematic
      });
      
      // Print the actual usage
      for (const usage of analysis.allPkceUsage) {
        console.log(`      Line ${usage.number}: ${usage.line.trim()}`);
      }
    }
    
    if (analysis.problematic.length > 0) {
      console.log(`   🎯 PROBLEMATIC FILE FOUND: ${path.relative(packagePath, file)}`);
      results.problematicFiles.push({
        file: path.relative(packagePath, file),
        fullPath: file,
        issues: analysis.problematic
      });
      
      for (const issue of analysis.problematic) {
        console.log(`      ❌ Line ${issue.lineNumber}: ${issue.match}`);
        console.log(`         Context: ${issue.context.replace(/\n/g, ' ')}`);
      }
    }
  }
  
  return results;
}

async function simulateN8NNodeLoading(packageName) {
  const packagePath = `/tmp/n8n-nodes/node_modules/${packageName}`;
  
  try {
    // Try to find and load package.json to understand the structure
    const packageJsonPath = path.join(packagePath, 'package.json');
    if (fs.existsSync(packageJsonPath)) {
      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
      
      console.log(`\n🎯 Simulating n8n loading for: ${packageName}`);
      console.log(`   Main entry: ${packageJson.main || 'not specified'}`);
      
      // Try to load the main entry point the way n8n might
      if (packageJson.main) {
        const mainPath = path.join(packagePath, packageJson.main);
        if (fs.existsSync(mainPath)) {
          console.log(`   📄 Analyzing main file: ${packageJson.main}`);
          const analysis = searchForPkceUsage(mainPath);
          
          if (analysis.problematic.length > 0) {
            console.log(`   🎯 MAIN FILE HAS PROBLEMATIC PKCE USAGE!`);
            for (const issue of analysis.problematic) {
              console.log(`      ❌ ${issue.match} at line ${issue.lineNumber}`);
            }
            return true;
          }
        }
      }
      
      // Look for common n8n node patterns
      const commonNodePaths = [
        'dist/nodes',
        'nodes',
        'src/nodes',
        'lib/nodes'
      ];
      
      for (const nodePath of commonNodePaths) {
        const fullNodePath = path.join(packagePath, nodePath);
        if (fs.existsSync(fullNodePath)) {
          console.log(`   📁 Found node directory: ${nodePath}`);
          const nodeFiles = findJSFiles(fullNodePath);
          
          for (const nodeFile of nodeFiles) {
            const analysis = searchForPkceUsage(nodeFile);
            if (analysis.problematic.length > 0) {
              console.log(`   🎯 PROBLEMATIC NODE FILE: ${path.relative(packagePath, nodeFile)}`);
              for (const issue of analysis.problematic) {
                console.log(`      ❌ ${issue.match} at line ${issue.lineNumber}`);
              }
              return true;
            }
          }
        }
      }
    }
  } catch (e) {
    console.log(`   Error simulating load: ${e.message}`);
  }
  
  return false;
}

async function main() {
  console.log('=== Enhanced Node File Analysis ===');
  
  const problematicPackages = [];
  
  // First pass: analyze all n8n node packages
  const nodePackages = pkgs.filter(pkg => pkg.startsWith('n8n-nodes-') || pkg.includes('n8n-nodes'));
  
  for (const pkg of nodePackages) {
    const results = await analyzePackageFiles(pkg);
    
    if (results.problematicFiles && results.problematicFiles.length > 0) {
      problematicPackages.push(pkg);
      console.log(`\n🚨 FOUND PROBLEMATIC PACKAGE: ${pkg}`);
    }
    
    // Also simulate n8n loading
    const hasProblematicLoading = await simulateN8NNodeLoading(pkg);
    if (hasProblematicLoading) {
      problematicPackages.push(pkg);
    }
  }
  
  console.log('\n=== FINAL RESULTS ===');
  if (problematicPackages.length > 0) {
    console.log(`🎯 Problematic packages found: ${[...new Set(problematicPackages)].join(', ')}`);
  } else {
    console.log('🤔 No obvious problematic patterns found in static analysis');
    console.log('   The error might be in dynamic code execution or eval statements');
  }
  
  // Test pkce-challenge one more time
  console.log('\n=== Final PKCE Test ===');
  try {
    const pkce = require('pkce-challenge');
    const challenge = pkce.generateChallenge();
    console.log('✅ pkce-challenge.generateChallenge() works correctly');
    console.log(`   Challenge type: ${typeof challenge}`);
    console.log(`   Challenge keys: ${Object.keys(challenge).join(', ')}`);
  } catch (e) {
    console.log('❌ pkce-challenge.generateChallenge() failed:', e.message);
  }
}

main().catch(console.error); 