import puppeteer from 'puppeteer';
import fs from 'fs/promises';
import path from 'path';

// Helper function to fetch an image and convert it to a Base64 data URI
const imageToDataURI = async (url) => {
  const response = await fetch(url);
  if (!response.ok) {
    console.warn(`Failed to fetch image ${url}: ${response.statusText}`);
    return url; // Return original URL on failure
  }
  const buffer = await response.arrayBuffer();
  const base64 = Buffer.from(buffer).toString('base64');
  // Get content type from headers, default to svg
  const contentType = response.headers.get('content-type') || 'image/svg+xml';
  return `data:${contentType};base64,${base64}`;
};

const renderDiagram = async () => {
  console.log('Starting diagram rendering with image embedding...');

  // 1. Read source files
  const mmdPath = path.resolve(process.cwd(), 'architecture.mmd');
  const mmdContent = await fs.readFile(mmdPath, 'utf-8');
  const mermaidLibPath = path.resolve(process.cwd(), 'node_modules/mermaid/dist/mermaid.min.js');
  const mermaidLibContent = await fs.readFile(mermaidLibPath, 'utf-8');

  // 2. Launch Puppeteer
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();

  // 3. Render the diagram inside the browser context
  const rawSvgResult = await page.evaluate(
    (mmd, mermaidJs) => {
      document.body.innerHTML = `<div id="container"></div>`;
      const container = document.getElementById('container');
      const script = document.createElement('script');
      script.innerHTML = mermaidJs;
      document.head.appendChild(script);
      window.mermaid.initialize({ startOnLoad: false, flowchart: { htmlLabels: true } });
      return window.mermaid.render('mermaid-diagram', mmd, container);
    },
    mmdContent,
    mermaidLibContent
  );

  await browser.close();

  // 4. Post-process the SVG to embed images
  console.log('Post-processing SVG to embed images...');
  let svg = rawSvgResult.svg;

  // Find all image tags
  const imgRegex = /<img src="([^"]+)"/g;
  const matches = [...svg.matchAll(imgRegex)];
  
  if (matches.length > 0) {
    const urls = matches.map(match => match[1]);
    const dataUris = await Promise.all(urls.map(imageToDataURI));

    // Replace each URL with its corresponding data URI
    urls.forEach((url, index) => {
      console.log(`Embedding ${url}...`);
      svg = svg.replace(url, dataUris[index]);
    });
  }

  // 5. Clean the generated SVG by self-closing <br> and <img> tags
  const finalSvg = svg
    .replace(/<br>/g, '<br/>')
    .replace(/<img([^>]+)>/g, (match, group1) => `<img${group1}/>`);

  // 6. Write the final SVG to a file
  const outputPath = path.resolve(process.cwd(), 'architecture.svg');
  await fs.writeFile(outputPath, finalSvg);

  console.log('Diagram rendered successfully with embedded images to architecture.svg');
};

renderDiagram().catch(error => {
  console.error('Error rendering diagram:', error);
  process.exit(1);
});
