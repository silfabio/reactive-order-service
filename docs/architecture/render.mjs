import puppeteer from 'puppeteer';
import fs from 'fs/promises';
import path from 'path';

// Helper function to fetch a file and convert it to a Base64 data URI
const toDataURI = async (url) => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch ${url}: ${response.statusText}`);
  }
  const buffer = await response.arrayBuffer();
  const base64 = Buffer.from(buffer).toString('base64');
  const ext = path.extname(url).substring(1);
  const mime = {
    'woff2': 'font/woff2',
    'ttf': 'font/ttf',
  }[ext] || 'application/octet-stream';
  return `data:${mime};base64,${base64}`;
};

const renderDiagram = async () => {
  console.log('Starting diagram rendering...');

  // 1. Define Font Awesome font files to embed
  const faBaseUrl = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/webfonts/';
  const fontFiles = {
    'fa-solid-900.woff2': { weight: '900', family: '"Font Awesome 5 Free"' },
    'fa-regular-400.woff2': { weight: '400', family: '"Font Awesome 5 Free"' },
    'fa-brands-400.woff2': { weight: '400', family: '"Font Awesome 5 Brands"' },
  };

  // 2. Fetch and encode all fonts in parallel
  console.log('Fetching and encoding fonts...');
  const fontDataURIs = await Promise.all(
    Object.keys(fontFiles).map(file => toDataURI(`${faBaseUrl}${file}`))
  );

  // 3. Construct the full @font-face CSS with embedded Base64 data
  let css = '';
  Object.keys(fontFiles).forEach((file, index) => {
    const { weight, family } = fontFiles[file];
    css += `
      @font-face {
        font-family: ${family};
        font-style: normal;
        font-weight: ${weight};
        font-display: block;
        src: url(${fontDataURIs[index]}) format('woff2');
      }
    `;
  });
  // Add the basic Font Awesome class definitions
  const faCssResponse = await fetch('https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css');
  const faCss = await faCssResponse.text();
  // We only need the rules, not the @font-face declarations from the original file
  css += faCss.replace(/@font-face\s*{[^}]*}/g, '');


  // 4. Read the Mermaid diagram source
  const mmdPath = path.resolve(process.cwd(), 'architecture.mmd');
  const mmdContent = await fs.readFile(mmdPath, 'utf-8');
  
  // 5. Launch Puppeteer and render the diagram
  console.log('Launching headless browser to render SVG...');
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();

  const mermaidLibPath = path.resolve(process.cwd(), 'node_modules/mermaid/dist/mermaid.min.js');
  const mermaidLibContent = await fs.readFile(mermaidLibPath, 'utf-8');

  const { svg } = await page.evaluate(
    (mmd, mermaidJs) => {
      document.body.innerHTML = `<div id="container"></div>`;
      const container = document.getElementById('container');
      const script = document.createElement('script');
      script.innerHTML = mermaidJs;
      document.head.appendChild(script);
      window.mermaid.initialize({ startOnLoad: false });
      return window.mermaid.render('mermaid-diagram', mmd, container);
    },
    mmdContent,
    mermaidLibContent
  );

  // 6. Inject the generated CSS into the SVG
  const finalSvg = svg.replace(
    '</svg>',
    `<style>${css}</style></svg>`
  );

  // 7. Write the final SVG to a file
  const outputPath = path.resolve(process.cwd(), 'architecture.svg');
  await fs.writeFile(outputPath, finalSvg);

  await browser.close();
  console.log('Diagram rendered successfully to architecture.svg');
};

renderDiagram().catch(error => {
  console.error('Error rendering diagram:', error);
  process.exit(1);
});
