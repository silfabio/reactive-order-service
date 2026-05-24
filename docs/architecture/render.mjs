import puppeteer from 'puppeteer';
import fs from 'fs/promises';
import path from 'path';

const renderDiagram = async () => {
  console.log('Starting diagram rendering...');

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

  // 4. Clean the generated SVG by self-closing <br> and <img> tags
  let cleanedSvg = rawSvgResult.svg
    .replace(/<br>/g, '<br/>')
    .replace(/<img([^>]+)>/g, (match, group1) => `<img${group1}/>`);

  // 5. Write the final SVG to a file
  const outputPath = path.resolve(process.cwd(), 'architecture.svg');
  await fs.writeFile(outputPath, cleanedSvg);

  await browser.close();
  console.log('Diagram rendered successfully to architecture.svg');
};

renderDiagram().catch(error => {
  console.error('Error rendering diagram:', error);
  process.exit(1);
});
