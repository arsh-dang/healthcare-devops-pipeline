// Initialize Datadog APM if available and enabled
try {
  if (process.env.DD_TRACE_ENABLED === "true") {
    // eslint-disable-next-line global-require
    require("dd-trace").init({
      service: "healthcare-backend",
      env: process.env.NODE_ENV || "staging",
    });
  }
} catch (e) {
  // eslint-disable-next-line no-console
  console.warn("Datadog APM not initialized:", e.message);
}

// Initialize Jaeger tracing
let tracer;
try {
  const { initTracer } = require('jaeger-client');
  
  const config = {
    serviceName: 'healthcare-backend',
    sampler: {
      type: 'const',
      param: 1, // Sample all traces for demo purposes
    },
    reporter: {
      logSpans: true,
      agentHost: process.env.JAEGER_AGENT_HOST || 'jaeger.monitoring-staging.svc.cluster.local',
      agentPort: process.env.JAEGER_AGENT_PORT || 6832,
    },
  };
  
  const options = {
    logger: {
      info: (msg) => console.log('INFO:', msg),
      error: (msg) => console.error('ERROR:', msg),
    },
  };
  
  tracer = initTracer(config, options);
  console.log('Jaeger tracing initialized successfully');
} catch (e) {
  console.warn('Jaeger tracing not initialized:', e.message);
}

const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const promClient = require("prom-client");
require("dotenv").config();

const appointmentRoutes = require("./routes/appointmentRoutes");

// Initialize Prometheus metrics collection
const collectDefaultMetrics = promClient.collectDefaultMetrics;
const Registry = promClient.Registry;
const register = new Registry();
collectDefaultMetrics({ register });

// Create custom metrics
const httpRequestDurationMicroseconds = new promClient.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "code"],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
});

const httpRequestCounter = new promClient.Counter({
  name: "http_request_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "code"],
});

register.registerMetric(httpRequestDurationMicroseconds);
register.registerMetric(httpRequestCounter);

// Create Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Jaeger tracing middleware
app.use((req, res, next) => {
  if (tracer) {
    const span = tracer.startSpan(`${req.method} ${req.path}`);
    span.setTag('http.method', req.method);
    span.setTag('http.url', req.url);
    span.setTag('http.user_agent', req.get('User-Agent'));
    
    req.span = span;
    
    res.on('finish', () => {
      span.setTag('http.status_code', res.statusCode);
      span.finish();
    });
  }
  next();
});

// Metrics middleware
app.use((req, res, next) => {
  const start = process.hrtime();

  res.on("finish", () => {
    const duration = process.hrtime(start);
    const durationInSeconds = duration[0] + duration[1] / 1e9;
    const path = req.path.split("/").slice(0, 3).join("/");

    httpRequestDurationMicroseconds
      .labels(req.method, path, res.statusCode)
      .observe(durationInSeconds);

    httpRequestCounter.labels(req.method, path, res.statusCode).inc();
  });

  next();
});

// Routes
app.use("/api/appointments", appointmentRoutes);

// GDPR Compliance Routes
app.use("/api/gdpr", require("./routes/gdprRoutes"));

// API routes for ingress rewriting
app.get("/api/", (req, res) => {
  if (req.span) {
    req.span.setTag('operation', 'api-root');
  }
  res.send("Healthcare Appointment API is running");
});

app.get("/api/health", (req, res) => {
  if (req.span) {
    req.span.setTag('operation', 'health-check');
  }
  
  // Check MongoDB connection status
  const mongoStatus = mongoose.connection.readyState;
  const isMongoConnected = mongoStatus === 1; // 1 = connected

  if (isMongoConnected) {
    res.status(200).json({ status: "ok", mongodb: "connected" });
  } else {
    res.status(503).json({ status: "error", mongodb: "disconnected" });
  }
});

app.get("/api/metrics", async (req, res) => {
  if (req.span) {
    req.span.setTag('operation', 'metrics');
  }
  
  try {
    res.set("Content-Type", register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err);
  }
});

// Root route
app.get("/", (req, res) => {
  if (req.span) {
    req.span.setTag('operation', 'root');
  }
  res.send("Healthcare Appointment API is running");
});

// Health check endpoint
app.get("/health", (req, res) => {
  if (req.span) {
    req.span.setTag('operation', 'health');
  }
  
  // Check MongoDB connection status
  const mongoStatus = mongoose.connection.readyState;
  const isMongoConnected = mongoStatus === 1; // 1 = connected

  if (isMongoConnected) {
    res.status(200).json({ status: "ok", mongodb: "connected" });
  } else {
    res.status(503).json({ status: "error", mongodb: "disconnected" });
  }
});

// Connect to MongoDB
const PORT = process.env.PORT || 5001;

// Construct MongoDB URI from environment variables
const MONGODB_HOST = process.env.MONGODB_HOST || "localhost";
const MONGODB_PORT = process.env.MONGODB_PORT || "27017";
const MONGODB_USERNAME = process.env.MONGODB_USERNAME;
const MONGODB_PASSWORD = process.env.MONGODB_PASSWORD;
const MONGODB_DATABASE = process.env.MONGODB_DATABASE || 'healthcare-app';

let MONGODB_URI;
if (MONGODB_USERNAME && MONGODB_PASSWORD) {
  // URL encode the password to handle special characters
  const encodedPassword = encodeURIComponent(MONGODB_PASSWORD);
  MONGODB_URI = `mongodb://${MONGODB_USERNAME}:${encodedPassword}@${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DATABASE}?authSource=admin`;
} else {
  MONGODB_URI =
    process.env.MONGODB_URI ||
    `mongodb://${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DATABASE}`;
}

console.log(`Connecting to MongoDB at: ${MONGODB_HOST}:${MONGODB_PORT}`);
console.log(`Database: ${MONGODB_DATABASE}`);
console.log(`Using authentication: ${!!MONGODB_USERNAME}`);

mongoose
  .connect(MONGODB_URI)
  .then(() => {
    // eslint-disable-next-line no-console
    console.log('Connected to MongoDB');
  })
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error('Failed to connect to MongoDB', err);
  });

// Start the server regardless of MongoDB connection status
app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Server running on port ${PORT}`);
});

// Handle unhandled promise rejections
process.on("unhandledRejection", (err) => {
  // eslint-disable-next-line no-console
  console.error("Unhandled Promise Rejection:", err);
});
