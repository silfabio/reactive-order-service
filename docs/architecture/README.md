# Architecture Diagram

This directory contains the source code (`architecture.mmd`) and rendering script for the project's architecture diagram.

The diagram is authored using Mermaid.js syntax. The final SVG is generated using a Node.js script with Puppeteer to ensure external icons are rendered correctly.

<div align="center">

![Architecture Diagram](docs/architecture/architecture.svg)

</div>

## Prerequisites

- [Node.js](https://nodejs.org/) (which includes npm) must be installed on your system.

## Setup

To install the necessary dependencies for rendering the diagram, navigate to this directory and run `npm install`.

```sh
cd docs/architecture
npm install
```

This will create a local `node_modules` directory inside `docs/architecture/` with the required packages.

## Rendering the Diagram

To generate or update the `architecture.svg` file from the `architecture.mmd` source, run the rendering script from within this directory:

```sh
node render-diagram.mjs
```

Alternatively, you can use the npm script shortcut:

```sh
npm run render
```

This command will launch a headless browser, render the diagram, and save the output to `architecture.svg`.

## Modifying the Diagram

To make changes, edit the `architecture.mmd` file. The `architecture.svg` file is a generated artifact and should not be edited directly. After modifying the `.mmd` file, run the rendering script to regenerate the SVG.
