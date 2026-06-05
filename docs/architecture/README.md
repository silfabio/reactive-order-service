# Architecture Diagrams

This directory contains the Mermaid source files and rendering tools for the project's architecture diagrams. All diagrams are authored using Mermaid.js syntax and rendered to PNG using the official `@mermaid-js/mermaid-cli` tool.

## Architecture Overview

High-level view of the system components across local development, IaC emulation, and the production AWS environment.

<div align="center">

![Architecture Diagram](architecture.png)

</div>

## Class Diagram

Internal structure of the service: domain entities, the layered architecture (controller → service → repository), and the asynchronous Kafka consumer.

<div align="center">

![Class Diagram](class-diagram.png)

</div>

## Sequence Diagram

Complete request lifecycle for creating and retrieving an order, including the synchronous HTTP flow and the asynchronous Kafka consumer processing.

<div align="center">

![Sequence Diagram](sequence-diagram.png)

</div>

## Prerequisites

- [Node.js](https://nodejs.org/) (which includes npm) must be installed on your system.

## Setup

To install the necessary dependencies, navigate to this directory and run:

```sh
cd docs/architecture
npm install
```

## Rendering the Diagrams

To regenerate all PNG files from their `.mmd` sources:

```sh
npm run render:all
```

Or render a specific diagram:

```sh
npm run render          # Architecture overview
npm run render:class    # Class diagram
npm run render:sequence # Sequence diagram
```

## Modifying the Diagrams

Edit the relevant `.mmd` source file. The `.png` files are generated artifacts and must not be edited directly. After modifying a `.mmd` file, run the corresponding render script to regenerate the image.

| Source | Command | Output |
|:---|:---|:---|
| `architecture.mmd` | `npm run render` | `architecture.png` |
| `class-diagram.mmd` | `npm run render:class` | `class-diagram.png` |
| `sequence-diagram.mmd` | `npm run render:sequence` | `sequence-diagram.png` |
