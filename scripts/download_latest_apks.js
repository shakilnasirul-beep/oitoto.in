const fs = require('fs');
const path = require('path');
const { execSync, spawnSync } = require('child_process');

function getGitHubToken() {
  const creds = execSync('git credential fill', { input: 'protocol=https\nhost=github.com\n\n' }).toString();
  let token = '';
  creds.split('\n').forEach(line => {
    if (line.startsWith('password=')) token = line.substring(9).trim();
  });
  return token;
}

const token = getGitHubToken();
const repo = 'shakilnasirul-beep/oitoto.in';

const tempDir = path.join(__dirname, '../temp_download');
if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir, { recursive: true });

const downloadsDir = path.join(__dirname, '../downloads');
const deployDownloadsDir = path.join(__dirname, '../deploy-web/downloads');
if (!fs.existsSync(downloadsDir)) fs.mkdirSync(downloadsDir, { recursive: true });
if (!fs.existsSync(deployDownloadsDir)) fs.mkdirSync(deployDownloadsDir, { recursive: true });

console.log('Downloading Customer APK zip (ID 12564279921)...');
const custZip = path.join(tempDir, 'customer.zip');
spawnSync('curl.exe', [
  '-L',
  '-H', `Authorization: Bearer ${token}`,
  '-H', 'User-Agent: NodeJS',
  'https://api.github.com/repos/shakilnasirul-beep/oitoto.in/actions/artifacts/12564279921/zip',
  '-o', custZip
], { stdio: 'inherit' });

console.log('Downloading Driver APK zip (ID 12564951528)...');
const drvZip = path.join(tempDir, 'driver.zip');
spawnSync('curl.exe', [
  '-L',
  '-H', `Authorization: Bearer ${token}`,
  '-H', 'User-Agent: NodeJS',
  'https://api.github.com/repos/shakilnasirul-beep/oitoto.in/actions/artifacts/12564951528/zip',
  '-o', drvZip
], { stdio: 'inherit' });

console.log('Customer zip size:', fs.statSync(custZip).size);
console.log('Driver zip size:', fs.statSync(drvZip).size);

// Extract Customer
const custExtract = path.join(tempDir, 'cust_apk');
if (fs.existsSync(custExtract)) fs.rmSync(custExtract, { recursive: true, force: true });
fs.mkdirSync(custExtract);
execSync(`powershell -Command "Expand-Archive -Path '${custZip}' -DestinationPath '${custExtract}' -Force"`);

const custApkName = fs.readdirSync(custExtract).find(f => f.endsWith('.apk'));
console.log('Found Customer APK file:', custApkName);
const custApkSource = path.join(custExtract, custApkName);
const custSize = fs.statSync(custApkSource).size;
console.log('Customer APK size:', custSize, 'bytes');

fs.copyFileSync(custApkSource, path.join(downloadsDir, 'OiToto_Customer_v1.0.5.apk'));
fs.copyFileSync(custApkSource, path.join(downloadsDir, 'oi_toto_customer.apk'));
fs.copyFileSync(custApkSource, path.join(deployDownloadsDir, 'OiToto_Customer_v1.0.5.apk'));
fs.copyFileSync(custApkSource, path.join(deployDownloadsDir, 'oi_toto_customer.apk'));
console.log('✅ Customer APK v1.0.5 placed successfully in downloads/ and deploy-web/downloads/!');

// Extract Driver
const drvExtract = path.join(tempDir, 'drv_apk');
if (fs.existsSync(drvExtract)) fs.rmSync(drvExtract, { recursive: true, force: true });
fs.mkdirSync(drvExtract);
execSync(`powershell -Command "Expand-Archive -Path '${drvZip}' -DestinationPath '${drvExtract}' -Force"`);

const drvApkName = fs.readdirSync(drvExtract).find(f => f.endsWith('.apk'));
console.log('Found Driver APK file:', drvApkName);
const drvApkSource = path.join(drvExtract, drvApkName);
const drvSize = fs.statSync(drvApkSource).size;
console.log('Driver APK size:', drvSize, 'bytes');

fs.copyFileSync(drvApkSource, path.join(downloadsDir, 'OiToto_Driver_v1.0.5.apk'));
fs.copyFileSync(drvApkSource, path.join(downloadsDir, 'oi_toto_driver.apk'));
fs.copyFileSync(drvApkSource, path.join(deployDownloadsDir, 'OiToto_Driver_v1.0.5.apk'));
fs.copyFileSync(drvApkSource, path.join(deployDownloadsDir, 'oi_toto_driver.apk'));
console.log('✅ Driver APK v1.0.5 placed successfully in downloads/ and deploy-web/downloads/!');

// Cleanup
fs.rmSync(tempDir, { recursive: true, force: true });
console.log('ALL APKS DOWNLOADED, EXTRACTED AND PLACED IN LANDING PAGE DIRECTORY SUCCESSFULLY!');
