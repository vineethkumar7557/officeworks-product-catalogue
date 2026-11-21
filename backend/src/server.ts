import { buildApp } from './composition';
import { loadConfig } from './config/config';

function main(): void {
  const config = loadConfig();
  const app = buildApp(config);

  app.listen(config.port, () => {
    console.log(`Catalogue API listening on http://localhost:${config.port}`);
  });
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}
