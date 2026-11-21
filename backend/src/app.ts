import cors from 'cors';
import express, { Express } from 'express';
import helmet from 'helmet';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { CatalogueServices, createCatalogueRouter } from './routes/catalogueRoutes';
import { createEnquiryRouter, RateLimitOptions } from './routes/enquiryRoutes';
import { EnquiryService } from './services/enquiryService';

export interface AppDependencies extends CatalogueServices {
  corsOrigin: string;
  enquiryService: EnquiryService;
  enquiryRateLimit: RateLimitOptions;
}

// Builds the web app from the pieces it is given. Tests build it with fake pieces.
export function createApp(dependencies: AppDependencies): Express {
  const app = express();

  app.use(helmet());
  app.use(cors({ origin: dependencies.corsOrigin }));
  app.use(express.json({ limit: '10kb' }));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });
  app.use(createCatalogueRouter(dependencies));
  app.use(createEnquiryRouter(dependencies.enquiryService, dependencies.enquiryRateLimit));

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
