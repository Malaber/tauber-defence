import { copyFile, mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const output = new URL('../dist/client/', import.meta.url);
const routes = ['capabilities', 'privacy', 'support'];

for (const route of routes) {
  const routeDirectory = new URL(`${route}/`, output);
  await mkdir(routeDirectory, { recursive: true });
  await copyFile(new URL(`${route}.html`, output), new URL('index.html', routeDirectory));
  await copyFile(new URL(`${route}.rsc`, output), new URL('index.rsc', routeDirectory));
}

await writeFile(join(output.pathname, '.nojekyll'), '');
