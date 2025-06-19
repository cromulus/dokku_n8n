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

function searchForExactProblem(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Look for the EXACT problematic string that's causing the error
    const exactProblems = [
      // The exact error pattern
      /pkce-challenge\/dist\/index\.node\.js.*\.index/g,
      /require\([^)]*pkce-challenge[^)]*\)\.index/g,
      // More specific patterns
      /new\s*\(\s*require\([^)]*pkce-challenge[^)]*\)\.index\s*\)/g,
      // String that might be eval'd
      /["'`]new\s*\(\s*require\([^)]*pkce-challenge/g,
      /["'`][^"'`]*pkce-challenge[^"'`]*index[^"'`]*["'`]/g,
    ];
    
    const results = [];
    
    for (const pattern of exactProblems) {
      const matches = content.matchAll(pattern);
      for (const match of matches) {
        const lines = content.split('\n');
        const lineIndex = content.substring(0, match.index).split('\n').length - 1;
        const contextStart = Math.max(0, lineIndex - 10);
        const contextEnd = Math.min(lines.length, lineIndex + 11);
        
        results.push({
          pattern: pattern.source,
          match: match[0],
          lineNumber: lineIndex + 1,
          context: lines.slice(contextStart, contextEnd).join('\n'),
          fullLine: lines[lineIndex],
          contextStart: contextStart + 1,
          contextEnd: contextEnd
        });
      }
    }
    
    return results;
  } catch (e) {
    return [];
  }
}

function searchForStringBuilding(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Look for code that might build the problematic string
    const buildingPatterns = [
      // Template literals or string concatenation
      /\$\{[^}]*pkce[^}]*\}/g,
      /\+\s*["'`][^"'`]*pkce[^"'`]*["'`]/g,
      /["'`][^"'`]*pkce[^"'`]*["'`]\s*\+/g,
      // Variable assignments that might contain the problematic code
      /=\s*["'`][^"'`]*new\s*\(/g,
      /=\s*["'`][^"'`]*require[^"'`]*["'`]/g,
      // Function calls that might generate the code
      /eval\s*\(/g,
      /Function\s*\(/g,
      /vm\.runInContext/g,
    ];
    
    const results = [];
    
    for (const pattern of buildingPatterns) {
      const matches = content.matchAll(pattern);
      for (const match of matches) {
        const lines = content.split('\n');
        const lineIndex = content.substring(0, match.index).split('\n').length - 1;
        const contextStart = Math.max(0, lineIndex - 5);
        const contextEnd = Math.min(lines.length, lineIndex + 6);
        
        results.push({
          pattern: pattern.source,
          match: match[0],
          lineNumber: lineIndex + 1,
          context: lines.slice(contextStart, contextEnd).join('\n'),
          fullLine: lines[lineIndex]
        });
      }
    }
    
    return results;
  } catch (e) {
    return [];
  }
}

async function deepAnalyzePackage(packageName) {
  const packagePath = `/tmp/n8n-nodes/node_modules/${packageName}`;
  
  if (!fs.existsSync(packagePath)) {
    return { error: 'Package not found' };
  }
  
  console.log(`\n🔍 DEEP ANALYSIS: ${packageName}`);
  
  const jsFiles = findJSFiles(packagePath);
  console.log(`   📁 Found ${jsFiles.length} JS/TS files`);
  
  let foundProblems = false;
  
  for (const file of jsFiles) {
    const exactProblems = searchForExactProblem(file);
    const stringBuilding = searchForStringBuilding(file);
    
    if (exactProblems.length > 0) {
      console.log(`   🎯 EXACT PROBLEM FOUND in ${path.relative(packagePath, file)}:`);
      foundProblems = true;
      
      for (const problem of exactProblems) {
        console.log(`      🚨 Line ${problem.lineNumber}: ${problem.match}`);
        console.log(`         Full line: ${problem.fullLine}`);
        console.log(`         Context (lines ${problem.contextStart}-${problem.contextEnd}):`);
        console.log(problem.context.split('\n').map(l => `           ${l}`).join('\n'));
        console.log(`         Pattern: ${problem.pattern}`);
      }
    }
    
    if (stringBuilding.length > 0) {
      console.log(`   🔧 STRING BUILDING FOUND in ${path.relative(packagePath, file)}:`);
      
      for (const building of stringBuilding) {
        console.log(`      📝 Line ${building.lineNumber}: ${building.match}`);
        console.log(`         Full line: ${building.fullLine}`);
        console.log(`         Context:`);
        console.log(building.context.split('\n').map(l => `           ${l}`).join('\n'));
      }
    }
  }
  
  return { foundProblems, totalFiles: jsFiles.length };
}

async function main() {
  console.log('=== AGGRESSIVE PKCE-CHALLENGE HUNTING ===');
  
  const problematicPackages = [];
  
  // Only analyze n8n node packages
  const nodePackages = pkgs.filter(pkg => pkg.startsWith('n8n-nodes-') || pkg.includes('n8n-nodes') || pkg.startsWith('@'));
  
  console.log(`\n🎯 Analyzing ${nodePackages.length} packages:`);
  console.log(nodePackages.map(p => `  - ${p}`).join('\n'));
  
  for (const pkg of nodePackages) {
    const results = await deepAnalyzePackage(pkg);
    
    if (results.foundProblems) {
      problematicPackages.push(pkg);
      console.log(`\n🚨 CONFIRMED PROBLEMATIC: ${pkg}`);
    }
  }
  
  console.log('\n=== FINAL HUNTING RESULTS ===');
  if (problematicPackages.length > 0) {
    console.log(`🎯 PROBLEMATIC PACKAGES: ${problematicPackages.join(', ')}`);
    console.log(`\n📋 REMOVAL COMMAND:`);
    console.log(`Remove these lines from Dockerfile:`);
    for (const pkg of problematicPackages) {
      console.log(`  - ${pkg} \\`);
    }
  } else {
    console.log('🤔 No obvious problems found in static analysis');
    console.log('   The issue might be in compiled/minified code or dynamic generation');
    
    // If we can't find it, let's try a different approach
    console.log('\n🔍 ALTERNATIVE APPROACH: Binary search recommendation');
    console.log('   Try removing half the packages and see if error persists:');
    const half1 = nodePackages.slice(0, Math.floor(nodePackages.length / 2));
    const half2 = nodePackages.slice(Math.floor(nodePackages.length / 2));
    
    console.log(`\n   HALF 1 (remove these first):`);
    half1.forEach(pkg => console.log(`     ${pkg} \\`));
    
    console.log(`\n   HALF 2 (keep these):`);
    half2.forEach(pkg => console.log(`     ${pkg} \\`));
  }
  
  // Test pkce-challenge one more time
  console.log('\n=== PKCE Module Test ===');
  try {
    const pkce = require('pkce-challenge');
    const challenge = pkce.generateChallenge();
    console.log('✅ pkce-challenge works correctly');
    console.log(`   Challenge keys: ${Object.keys(challenge).join(', ')}`);
    console.log(`   .index property: ${typeof pkce.index} (should be undefined)`);
  } catch (e) {
    console.log('❌ pkce-challenge failed:', e.message);
  }
}

main().catch(console.error); 