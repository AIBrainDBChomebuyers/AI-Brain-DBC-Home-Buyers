import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import { config } from './config/index.js';
import { routes } from './routes/index.js';
import { notFound, errorHandler } from './middleware/errors.js';

config.requiredInProduction();

const app = express();
app.use(helmet());
app.use(cors({ origin: config.corsOrigin, credentials: true }));
app.use(express.json({ limit: '1mb' }));
app.use(pinoHttp({ level: config.logLevel }));

app.use('/api', routes);
app.use(notFound);
app.use(errorHandler);

app.listen(config.port, () => {
  console.log(`ai-brain api on :${config.port} (${config.env})`);
});
