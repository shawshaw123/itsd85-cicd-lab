const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const DIR = path.join(__dirname, 'export', 'web');

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.json': 'application/json'
};

const server = http.createServer((req, res) => {
  // Required Godot 4 Web headers for WebAssembly
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  res.setHeader('Access-Control-Allow-Origin', '*');

  let decodedUrl = decodeURIComponent(req.url.split('?')[0]);
  let filePath = path.join(DIR, decodedUrl === '/' ? 'index.html' : decodedUrl);
  let ext = path.extname(filePath).toLowerCase();

  fs.readFile(filePath, (err, content) => {
    if (err) {
      // Fallback check in case file name has special characters
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('File Not Found');
    } else {
      res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
      res.end(content);
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`====================================================`);
  console.log(`   MARK N' SHOOT - IPHONE WIRELESS SERVER RUNNING!   `);
  console.log(`   Local PC: http://localhost:${PORT}               `);
  console.log(`   iPhone:   http://192.168.1.13:${PORT}            `);
  console.log(`====================================================`);
});
