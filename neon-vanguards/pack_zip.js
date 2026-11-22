const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const srcDir = 'C:\\Users\\User\\.gemini\\antigravity\\scratch\\neon-vanguards';
const stagingDir = 'C:\\Users\\User\\.gemini\\antigravity\\scratch\\zip_staging';
const destFolder = path.join(stagingDir, 'Mark_N_Shoot');
const zipFile = 'C:\\Users\\User\\.gemini\\antigravity\\scratch\\Mark_N_Shoot.zip';

if (fs.existsSync(stagingDir)) {
  fs.rmSync(stagingDir, { recursive: true, force: true });
}
fs.mkdirSync(destFolder, { recursive: true });

const items = ['assets', 'autoload', 'docs', 'scenes', 'scripts', 'project.godot', 'icon.svg', 'icon.svg.import', 'README.md'];

for (const item of items) {
  const s = path.join(srcDir, item);
  const d = path.join(destFolder, item);
  if (fs.existsSync(s)) {
    fs.cpSync(s, d, { recursive: true });
  }
}

if (fs.existsSync(zipFile)) {
  fs.unlinkSync(zipFile);
}

// Compress using powershell Compress-Archive
cp.execSync(`powershell -Command "Compress-Archive -Path '${destFolder}' -DestinationPath '${zipFile}' -Force"`);

// Clean staging
fs.rmSync(stagingDir, { recursive: true, force: true });

const stat = fs.statSync(zipFile);
console.log(`Successfully created ${zipFile} (${(stat.size / 1024 / 1024).toFixed(2)} MB)`);
