import { seedProduction } from './production-seed';

seedProduction()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.error('[seed] Failed:', err);
    process.exit(1);
  });
