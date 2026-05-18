import puppeteer from 'puppeteer';
import fs from 'fs/promises';
import path from 'path';

const inputFile = 'architecture.mmd';
const outputFile = 'architecture.svg';

async function renderDiagram() {
  console.log('Launching browser...');
  const browser = await puppeteer.launch({ headless: "new" });
  const page = await browser.newPage();

  try {
    console.log(`Reading diagram source from ${inputFile}...`);
    const mermaidCode = await fs.readFile(inputFile, 'utf-8');

    const htmlContent = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <title>Diagram Renderer</title>
      </head>
      <body>
          <div class="mermaid">${mermaidCode}</div>
          <script type="module">
              import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
              mermaid.initialize({
                startOnLoad: true,
                securityLevel: 'loose',
                flowchart: {
                  htmlLabels: true
                }
              });
          </script>
      </body>
      </html>
    `;

    console.log('Setting page content and waiting for all network activity to finish...');
    await page.setContent(htmlContent, { waitUntil: 'networkidle0', timeout: 60000 });

    console.log('Waiting for Mermaid diagram to render...');
    await page.waitForSelector('.mermaid svg', { timeout: 60000 });

    console.log('Extracting SVG content using XMLSerializer...');
    const svgContent = await page.$eval('.mermaid svg', (svgEl) => {
      return new XMLSerializer().serializeToString(svgEl);
    });

    console.log(`Writing SVG to ${outputFile}...`);
    await fs.writeFile(outputFile, svgContent);

    console.log('Diagram rendered successfully!');

  } catch (error) {
    console.error('An error occurred during rendering:', error);
  } finally {
    await browser.close();
    console.log('Browser closed.');
  }
}

renderDiagram();
