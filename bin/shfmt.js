#!/usr/bin/env node
const fs = require('fs');
const {execFileSync, spawnSync} = require('child_process');
const os = require('os');
const path = require('path');

const VERSION = 'v3.7.0';
const BIN_DIR = path.join(__dirname, '..', '.shfmt');
const BIN_PATH = path.join(BIN_DIR, 'shfmt');

function download(url, dest) {
  const res = spawnSync('curl', ['-L', '-o', dest, url]);
  if (res.status !== 0) {
    throw new Error('Failed to download shfmt');
  }
  fs.chmodSync(dest, 0o755);
}

async function ensureBinary() {
  if (fs.existsSync(BIN_PATH)) return;
  fs.mkdirSync(BIN_DIR, {recursive: true});
  const platform = os.platform();
  const arch = os.arch();
  let url;
  if (platform === 'linux' && arch === 'x64') {
    url = `https://github.com/mvdan/sh/releases/download/${VERSION}/shfmt_${VERSION}_linux_amd64`;
  } else if (platform === 'linux' && arch === 'arm64') {
    url = `https://github.com/mvdan/sh/releases/download/${VERSION}/shfmt_${VERSION}_linux_arm64`;
  } else if (platform === 'darwin' && arch === 'x64') {
    url = `https://github.com/mvdan/sh/releases/download/${VERSION}/shfmt_${VERSION}_darwin_amd64`;
  } else if (platform === 'darwin' && arch === 'arm64') {
    url = `https://github.com/mvdan/sh/releases/download/${VERSION}/shfmt_${VERSION}_darwin_arm64`;
  } else if (platform === 'win32' && arch === 'x64') {
    url = `https://github.com/mvdan/sh/releases/download/${VERSION}/shfmt_${VERSION}_windows_amd64.exe`;
  } else {
    throw new Error(`Unsupported platform: ${platform}-${arch}`);
  }
  await download(url, BIN_PATH);
}

(async () => {
  try {
    await ensureBinary();
    const args = process.argv.slice(2);
    execFileSync(BIN_PATH, args, {stdio: 'inherit'});
  } catch (err) {
    console.error(err.message);
    process.exit(1);
  }
})();
