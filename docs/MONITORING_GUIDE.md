# Healthcare DevOps Pipeline - Monitoring Guide

This guide provides comprehensive monitoring and observability setup for the Healthcare DevOps Pipeline using Prometheus, Grafana, and other monitoring tools.

##   Monitoring Strategy

### Observability Pillars
```
┌─────────────────────────────────────────────────────────────┐
│                    Three Pillars of Observability           │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   METRICS   │  │    LOGS     │  │   TRACES    │        │
│  │             │  │             │  │             │        │
│  │ • Prometheus│  │ • ELK Stack │  │ • Jaeger    │        │
│  │ • Grafana   │  │ • Fluent Bit│  │ • OpenTel   │        │
│  │ • Alerting  │  │ • Kibana    │  │ • Zipkin    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### Monitoring Architecture
```
┌──────────────────────────────────────────────────────────────┐
│                    Healthcare Application                    │
│  ┌─────────────┐              ┌─────────────┐               │
│  │  Frontend   │              │   Backend   │               │
│  │  (React)    │              │  (Node.js)  │               │
│  │             │              │             │               │
│  │ /metrics    │              │ /api/metrics│               │
│  └─────────────┘              └─────────────┘               │
└──────────────┬─────────────────────────┬─────────────────────┘
               │                         │
               ▼                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    Prometheus Server                        │
│  • Scrapes metrics from application endpoints               │
│  • Stores time-series data                                  │
│  • Evaluates alerting rules                                 │
│  • Provides query interface (PromQL)                        │
└──────────────┬───────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────┐
│                      Grafana                                │
│  • Visualizes metrics in dashboards                         │
│  • Provides alerting capabilities                           │
│  • Supports multiple data sources                           │
│  • User-friendly interface for monitoring                   │
└──────────────────────────────────────────────────────────────┘
```

##   Prometheus Configuration

### 1. Prometheus Setup

#### Prometheus Configuration File
```yaml
# terraform/configs/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert-rules.yml"

scrape_configs:
  # Healthcare Frontend Metrics
  - job_name: 'healthcare-frontend'
    static_configs:
      - targets: ['healthcare-frontend-service:80']
    metrics_path: '/metrics'
    scrape_interval: 10s
    scrape_timeout: 5s
    
  # Healthcare Backend Metrics
  - job_name: 'healthcare-backend'
    static_configs:
      - targets: ['healthcare-backend-service:5000']
    metrics_path: '/api/metrics'
    scrape_interval: 10s
    scrape_timeout: 5s
    
  # MongoDB Exporter
  - job_name: 'mongodb'
    static_configs:
      - targets: ['mongodb-exporter:9216']
    scrape_interval: 30s
    
  # Node Exporter (System Metrics)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 15s
    
  # Kubernetes Metrics
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - healthcare-production
            - healthcare-staging
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

#### Alert Rules Configuration
```yaml
# terraform/configs/alert-rules.yml
groups:
  - name: healthcare-application-alerts
    rules:
      # Application Availability
      - alert: HealthcareApplicationDown
        expr: up{job=~"healthcare-.*"} == 0
        for: 1m
        labels:
          severity: critical
          service: healthcare
        annotations:
          summary: "Healthcare application {{ $labels.job }} is down"
          description: "{{ $labels.job }} has been down for more than 1 minute"
          runbook_url: "https://docs.healthcare.com/runbooks/application-down"
          
      # High Response Time
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="healthcare-backend"}[5m])) > 2
        for: 5m
        labels:
          severity: warning
          service: healthcare-backend
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s for the last 5 minutes"
          
      # High Error Rate
      - alert: HighErrorRate
        expr: (sum(rate(http_requests_total{job="healthcare-backend",status=~"5.."}[5m])) / sum(rate(http_requests_total{job="healthcare-backend"}[5m]))) * 100 > 1
        for: 3m
        labels:
          severity: critical
          service: healthcare-backend
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }}% for the last 3 minutes"
          
      # Memory Usage
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes{pod=~"healthcare-.*"} / container_spec_memory_limit_bytes{pod=~"healthcare-.*"}) * 100 > 80
        for: 5m
        labels:
          severity: warning
          service: healthcare
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is {{ $value }}% for pod {{ $labels.pod }}"
          
      # CPU Usage
      - alert: HighCPUUsage
        expr: (rate(container_cpu_usage_seconds_total{pod=~"healthcare-.*"}[5m]) / container_spec_cpu_quota{pod=~"healthcare-.*"} * container_spec_cpu_period{pod=~"healthcare-.*"}) * 100 > 80
        for: 5m
        labels:
          severity: warning
          service: healthcare
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is {{ $value }}% for pod {{ $labels.pod }}"
          
      # Database Connection Issues
      - alert: DatabaseConnectionFailure
        expr: mongodb_up{job="mongodb"} == 0
        for: 1m
        labels:
          severity: critical
          service: mongodb
        annotations:
          summary: "MongoDB connection failure"
          description: "Cannot connect to MongoDB for more than 1 minute"
          
  - name: healthcare-business-metrics
    rules:
      # Low Appointment Booking Rate
      - alert: LowAppointmentBookingRate
        expr: rate(appointments_created_total[1h]) < 0.1
        for: 30m
        labels:
          severity: warning
          service: healthcare-business
        annotations:
          summary: "Low appointment booking rate"
          description: "Appointment booking rate is {{ $value }} per second over the last hour"
          
      # High Appointment Cancellation Rate
      - alert: HighAppointmentCancellationRate
        expr: (rate(appointments_cancelled_total[1h]) / rate(appointments_created_total[1h])) * 100 > 20
        for: 15m
        labels:
          severity: warning
          service: healthcare-business
        annotations:
          summary: "High appointment cancellation rate"
          description: "Appointment cancellation rate is {{ $value }}% over the last hour"
```

### 2. Application Metrics Implementation

#### Frontend Metrics (React)
```javascript
// src/utils/metrics.js
class MetricsCollector {
    constructor() {
        this.metrics = {
            page_views: new Map(),
            user_actions: new Map(),
            errors: new Map(),
            performance: new Map()
        };
    }
    
    // Track page views
    trackPageView(page) {
        const key = `page_view_${page}`;
        this.metrics.page_views.set(key, (this.metrics.page_views.get(key) || 0) + 1);
        this.sendMetric('page_views_total', this.metrics.page_views.get(key), { page });
    }
    
    // Track user actions
    trackUserAction(action, details = {}) {
        const key = `action_${action}`;
        this.metrics.user_actions.set(key, (this.metrics.user_actions.get(key) || 0) + 1);
        this.sendMetric('user_actions_total', this.metrics.user_actions.get(key), { action, ...details });
    }
    
    // Track errors
    trackError(error, context = {}) {
        const key = `error_${error.name}`;
        this.metrics.errors.set(key, (this.metrics.errors.get(key) || 0) + 1);
        this.sendMetric('frontend_errors_total', this.metrics.errors.get(key), { 
            error_type: error.name,
            error_message: error.message,
            ...context 
        });
    }
    
    // Track performance metrics
    trackPerformance(metric, value, labels = {}) {
        this.sendMetric(`frontend_performance_${metric}`, value, labels);
    }
    
    // Send metrics to backend
    async sendMetric(name, value, labels = {}) {
        try {
            await fetch('/api/metrics/custom', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name, value, labels, timestamp: Date.now() })
            });
        } catch (error) {
            console.warn('Failed to send metric:', error);
        }
    }
    
    // Expose metrics endpoint for Prometheus
    getMetricsString() {
        let metricsString = '';
        
        // Page views
        this.metrics.page_views.forEach((value, key) => {
            const page = key.replace('page_view_', '');
            metricsString += `page_views_total{page="${page}"} ${value}\n`;
        });
        
        // User actions
        this.metrics.user_actions.forEach((value, key) => {
            const action = key.replace('action_', '');
            metricsString += `user_actions_total{action="${action}"} ${value}\n`;
        });
        
        // Errors
        this.metrics.errors.forEach((value, key) => {
            const error = key.replace('error_', '');
            metricsString += `frontend_errors_total{error_type="${error}"} ${value}\n`;
        });
        
        return metricsString;
    }
}

export const metrics = new MetricsCollector();

// Usage in components
import { metrics } from '../utils/metrics';

function AppointmentForm() {
    const handleSubmit = async (appointmentData) => {
        const startTime = Date.now();
        
        try {
            metrics.trackUserAction('appointment_booking_attempt');
            
            const response = await bookAppointment(appointmentData);
            
            metrics.trackUserAction('appointment_booking_success');
            metrics.trackPerformance('appointment_booking_duration', Date.now() - startTime);
            
        } catch (error) {
            metrics.trackError(error, { context: 'appointment_booking' });
            metrics.trackUserAction('appointment_booking_failure');
        }
    };
    
    useEffect(() => {
        metrics.trackPageView('appointment_form');
    }, []);
    
    return (
        // Component JSX
    );
}
```

#### Backend Metrics (Node.js)
```javascript
// server/middleware/metrics.js
const promClient = require('prom-client');

// Create a Registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestsTotal = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code'],
    registers: [register]
});

const httpRequestDuration = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.1, 0.5, 1, 2, 5, 10],
    registers: [register]
});

const appointmentsTotal = new promClient.Counter({
    name: 'appointments_created_total',
    help: 'Total number of appointments created',
    labelNames: ['doctor_specialty', 'appointment_type'],
    registers: [register]
});

const appointmentsCancelled = new promClient.Counter({
    name: 'appointments_cancelled_total',
    help: 'Total number of appointments cancelled',
    labelNames: ['reason', 'doctor_specialty'],
    registers: [register]
});

const databaseConnections = new promClient.Gauge({
    name: 'database_connections_active',
    help: 'Number of active database connections',
    registers: [register]
});

const databaseQueryDuration = new promClient.Histogram({
    name: 'database_query_duration_seconds',
    help: 'Duration of database queries in seconds',
    labelNames: ['operation', 'collection'],
    buckets: [0.01, 0.05, 0.1, 0.5, 1, 2],
    registers: [register]
});

// Metrics middleware
const metricsMiddleware = (req, res, next) => {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        const route = req.route ? req.route.path : req.path;
        
        httpRequestsTotal.inc({
            method: req.method,
            route: route,
            status_code: res.statusCode
        });
        
        httpRequestDuration.observe({
            method: req.method,
            route: route,
            status_code: res.statusCode
        }, duration);
    });
    
    next();
};

// Database metrics wrapper
const trackDatabaseQuery = (operation, collection) => {
    return async (queryFunction) => {
        const start = Date.now();
        
        try {
            const result = await queryFunction();
            
            const duration = (Date.now() - start) / 1000;
            databaseQueryDuration.observe({ operation, collection }, duration);
            
            return result;
        } catch (error) {
            const duration = (Date.now() - start) / 1000;
            databaseQueryDuration.observe({ 
                operation: `${operation}_error`, 
                collection 
            }, duration);
            
            throw error;
        }
    };
};

// Business metrics tracking
const trackAppointmentCreated = (doctorSpecialty, appointmentType) => {
    appointmentsTotal.inc({ doctor_specialty: doctorSpecialty, appointment_type: appointmentType });
};

const trackAppointmentCancelled = (reason, doctorSpecialty) => {
    appointmentsCancelled.inc({ reason, doctor_specialty: doctorSpecialty });
};

// Expose metrics endpoint
const getMetrics = async (req, res) => {
    try {
        res.set('Content-Type', register.contentType);
        res.end(await register.metrics());
    } catch (error) {
        res.status(500).end(error);
    }
};

module.exports = {
    metricsMiddleware,
    trackDatabaseQuery,
    trackAppointmentCreated,
    trackAppointmentCancelled,
    databaseConnections,
    getMetrics,
    register
};

// Usage in routes
const { trackAppointmentCreated, trackDatabaseQuery } = require('../middleware/metrics');

// In appointment controller
const createAppointment = async (req, res) => {
    try {
        const appointmentData = req.body;
        
        const appointment = await trackDatabaseQuery('insert', 'appointments')(async () => {
            return await Appointment.create(appointmentData);
        });
        
        // Track business metric
        trackAppointmentCreated(
            appointmentData.doctorSpecialty || 'general',
            appointmentData.type || 'consultation'
        );
        
        res.status(201).json(appointment);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
```

##   Grafana Dashboard Configuration

### 1. Healthcare Application Dashboard

#### Dashboard JSON Configuration
```json
{
  "dashboard": {
    "id": null,
    "title": "Healthcare Application Monitoring",
    "tags": ["healthcare", "application"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Application Health Overview",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=~\"healthcare-.*\"}",
            "legendFormat": "{{ job }}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "green", "value": 1}
              ]
            },
            "mappings": [
              {"options": {"0": {"text": "DOWN"}}, "type": "value"},
              {"options": {"1": {"text": "UP"}}, "type": "value"}
            ]
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{job=\"healthcare-backend\"}[5m])) by (job)",
            "legendFormat": "Requests/sec"
          }
        ],
        "yAxes": [
          {"label": "Requests/sec", "min": 0}
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Response Time (95th Percentile)",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job=\"healthcare-backend\"}[5m])) by (le))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket{job=\"healthcare-backend\"}[5m])) by (le))",
            "legendFormat": "50th percentile"
          }
        ],
        "yAxes": [
          {"label": "Seconds", "min": 0}
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{job=\"healthcare-backend\",status=~\"5..\"}[5m])) / sum(rate(http_requests_total{job=\"healthcare-backend\"}[5m])) * 100",
            "legendFormat": "Error Rate %"
          }
        ],
        "yAxes": [
          {"label": "Percentage", "min": 0, "max": 100}
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
      },
      {
        "id": 5,
        "title": "Active Appointments",
        "type": "stat",
        "targets": [
          {
            "expr": "appointments_created_total - appointments_cancelled_total",
            "legendFormat": "Active Appointments"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {"displayMode": "basic"}
          }
        },
        "gridPos": {"h": 8, "w": 8, "x": 0, "y": 16}
      },
      {
        "id": 6,
        "title": "Database Performance",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(database_query_duration_seconds_bucket[5m])) by (le, operation))",
            "legendFormat": "{{ operation }} - 95th percentile"
          }
        ],
        "yAxes": [
          {"label": "Seconds", "min": 0}
        ],
        "gridPos": {"h": 8, "w": 8, "x": 8, "y": 16}
      },
      {
        "id": 7,
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "container_memory_usage_bytes{pod=~\"healthcare-.*\"} / 1024 / 1024",
            "legendFormat": "{{ pod }}"
          }
        ],
        "yAxes": [
          {"label": "MB", "min": 0}
        ],
        "gridPos": {"h": 8, "w": 8, "x": 16, "y": 16}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
```

### 2. Infrastructure Dashboard

#### System Metrics Dashboard
```json
{
  "dashboard": {
    "title": "Healthcare Infrastructure Monitoring",
    "panels": [
      {
        "title": "CPU Usage by Node",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{ instance }}"
          }
        ]
      },
      {
        "title": "Memory Usage by Node",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "{{ instance }}"
          }
        ]
      },
      {
        "title": "Disk Usage by Node",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - ((node_filesystem_avail_bytes{mountpoint=\"/\"} * 100) / node_filesystem_size_bytes{mountpoint=\"/\"})",
            "legendFormat": "{{ instance }}"
          }
        ]
      },
      {
        "title": "Network I/O by Node",
        "type": "graph",
        "targets": [
          {
            "expr": "irate(node_network_receive_bytes_total{device!=\"lo\"}[5m])",
            "legendFormat": "{{ instance }} - {{ device }} receive"
          },
          {
            "expr": "irate(node_network_transmit_bytes_total{device!=\"lo\"}[5m])",
            "legendFormat": "{{ instance }} - {{ device }} transmit"
          }
        ]
      }
    ]
  }
}
```

## 🚨 Alerting Configuration

### 1. Alertmanager Setup

#### Alertmanager Configuration
```yaml
# terraform/configs/alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@healthcare.com'
  smtp_auth_username: 'alerts@healthcare.com'
  smtp_auth_password: 'password'

route:
  group_by: ['alertname', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'healthcare-team'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 10s
      repeat_interval: 1h
    - match:
        service: healthcare-business
      receiver: 'business-alerts'

receivers:
  - name: 'healthcare-team'
    email_configs:
      - to: 'team@healthcare.com'
        subject: '[Healthcare] {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#healthcare-alerts'
        title: '[Healthcare] Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        
  - name: 'critical-alerts'
    email_configs:
      - to: 'oncall@healthcare.com'
        subject: '[CRITICAL] Healthcare Alert'
        body: |
          CRITICAL ALERT
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Runbook: {{ .Annotations.runbook_url }}
          {{ end }}
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#healthcare-critical'
        title: '🚨 CRITICAL ALERT'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        
  - name: 'business-alerts'
    email_configs:
      - to: 'business@healthcare.com'
        subject: '[Business Metrics] Healthcare Alert'
        body: |
          Business metrics alert
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'service']
```

### 2. Slack Integration

#### Slack Webhook Setup
```javascript
// server/utils/alerting.js
const axios = require('axios');

class AlertingService {
    constructor() {
        this.slackWebhookUrl = process.env.SLACK_WEBHOOK_URL;
        this.emailService = require('./email');
    }
    
    async sendSlackAlert(message, severity = 'warning') {
        const colors = {
            critical: '#FF0000',
            warning: '#FFA500',
            info: '#0000FF'
        };
        
        const payload = {
            username: 'Healthcare Monitoring',
            icon_emoji: ':hospital:',
            attachments: [{
                color: colors[severity],
                title: `${severity.toUpperCase()} Alert`,
                text: message,
                footer: 'Healthcare DevOps Pipeline',
                ts: Math.floor(Date.now() / 1000)
            }]
        };
        
        try {
            await axios.post(this.slackWebhookUrl, payload);
        } catch (error) {
            console.error('Failed to send Slack alert:', error);
        }
    }
    
    async sendHealthCheck() {
        const healthStatus = await this.checkApplicationHealth();
        
        if (!healthStatus.healthy) {
            await this.sendSlackAlert(
                `Health check failed: ${healthStatus.details}`,
                'critical'
            );
        }
    }
    
    async checkApplicationHealth() {
        try {
            // Check frontend
            const frontendResponse = await axios.get('http://healthcare-frontend/health', { timeout: 5000 });
            
            // Check backend
            const backendResponse = await axios.get('http://healthcare-backend/api/health', { timeout: 5000 });
            
            // Check database
            const dbStatus = await this.checkDatabaseConnection();
            
            return {
                healthy: frontendResponse.status === 200 && 
                        backendResponse.status === 200 && 
                        dbStatus.connected,
                details: {
                    frontend: frontendResponse.status === 200,
                    backend: backendResponse.status === 200,
                    database: dbStatus.connected
                }
            };
        } catch (error) {
            return {
                healthy: false,
                details: error.message
            };
        }
    }
    
    async checkDatabaseConnection() {
        const mongoose = require('mongoose');
        return {
            connected: mongoose.connection.readyState === 1
        };
    }
}

module.exports = new AlertingService();

// Scheduled health checks
setInterval(async () => {
    const alerting = require('./utils/alerting');
    await alerting.sendHealthCheck();
}, 60000); // Every minute
```

## 📱 Custom Monitoring Solutions

### 1. Business Metrics Dashboard

#### Appointment Metrics
```javascript
// server/services/metricsService.js
class BusinessMetricsService {
    constructor() {
        this.Appointment = require('../models/appointment');
        this.User = require('../models/user');
    }
    
    async getAppointmentMetrics(timeRange = '24h') {
        const startTime = this.getStartTime(timeRange);
        
        const metrics = await Promise.all([
            this.getAppointmentCount(startTime),
            this.getAppointmentsBySpecialty(startTime),
            this.getCancellationRate(startTime),
            this.getAverageBookingTime(startTime),
            this.getPatientSatisfactionScore(startTime)
        ]);
        
        return {
            timestamp: new Date().toISOString(),
            timeRange,
            appointments: {
                total: metrics[0],
                bySpecialty: metrics[1],
                cancellationRate: metrics[2],
                averageBookingTime: metrics[3],
                patientSatisfaction: metrics[4]
            }
        };
    }
    
    async getAppointmentCount(startTime) {
        return await this.Appointment.countDocuments({
            createdAt: { $gte: startTime }
        });
    }
    
    async getAppointmentsBySpecialty(startTime) {
        return await this.Appointment.aggregate([
            { $match: { createdAt: { $gte: startTime } } },
            { $group: { _id: '$doctor.specialty', count: { $sum: 1 } } },
            { $sort: { count: -1 } }
        ]);
    }
    
    async getCancellationRate(startTime) {
        const total = await this.Appointment.countDocuments({
            createdAt: { $gte: startTime }
        });
        
        const cancelled = await this.Appointment.countDocuments({
            createdAt: { $gte: startTime },
            status: 'cancelled'
        });
        
        return total > 0 ? (cancelled / total) * 100 : 0;
    }
    
    async getAverageBookingTime(startTime) {
        const appointments = await this.Appointment.find({
            createdAt: { $gte: startTime },
            bookingCompletedAt: { $exists: true }
        }).select('createdAt bookingCompletedAt');
        
        if (appointments.length === 0) return 0;
        
        const totalTime = appointments.reduce((sum, appointment) => {
            return sum + (appointment.bookingCompletedAt - appointment.createdAt);
        }, 0);
        
        return totalTime / appointments.length / 1000; // Return in seconds
    }
    
    async getPatientSatisfactionScore(startTime) {
        const reviews = await this.Appointment.find({
            createdAt: { $gte: startTime },
            'review.rating': { $exists: true }
        }).select('review.rating');
        
        if (reviews.length === 0) return null;
        
        const averageRating = reviews.reduce((sum, review) => {
            return sum + review.review.rating;
        }, 0) / reviews.length;
        
        return Math.round(averageRating * 100) / 100;
    }
    
    getStartTime(timeRange) {
        const now = new Date();
        switch (timeRange) {
            case '1h': return new Date(now - 60 * 60 * 1000);
            case '24h': return new Date(now - 24 * 60 * 60 * 1000);
            case '7d': return new Date(now - 7 * 24 * 60 * 60 * 1000);
            case '30d': return new Date(now - 30 * 24 * 60 * 60 * 1000);
            default: return new Date(now - 24 * 60 * 60 * 1000);
        }
    }
}

module.exports = new BusinessMetricsService();

// API endpoint for business metrics
app.get('/api/metrics/business', async (req, res) => {
    try {
        const timeRange = req.query.timeRange || '24h';
        const metrics = await businessMetricsService.getAppointmentMetrics(timeRange);
        res.json(metrics);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
```

### 2. Real-time Monitoring

#### WebSocket Monitoring Dashboard
```javascript
// Real-time monitoring with WebSocket
const WebSocket = require('ws');
const metricsService = require('./services/metricsService');

class RealTimeMonitoring {
    constructor() {
        this.wss = new WebSocket.Server({ port: 8080 });
        this.clients = new Set();
        this.setupWebSocketServer();
        this.startMetricsCollection();
    }
    
    setupWebSocketServer() {
        this.wss.on('connection', (ws) => {
            this.clients.add(ws);
            console.log('Client connected to monitoring dashboard');
            
            // Send initial metrics
            this.sendMetricsToClient(ws);
            
            ws.on('close', () => {
                this.clients.delete(ws);
                console.log('Client disconnected from monitoring dashboard');
            });
            
            ws.on('error', (error) => {
                console.error('WebSocket error:', error);
                this.clients.delete(ws);
            });
        });
    }
    
    async sendMetricsToClient(ws) {
        try {
            const metrics = await this.collectCurrentMetrics();
            ws.send(JSON.stringify({
                type: 'metrics_update',
                data: metrics,
                timestamp: new Date().toISOString()
            }));
        } catch (error) {
            console.error('Error sending metrics to client:', error);
        }
    }
    
    async broadcastMetrics() {
        const metrics = await this.collectCurrentMetrics();
        const message = JSON.stringify({
            type: 'metrics_update',
            data: metrics,
            timestamp: new Date().toISOString()
        });
        
        this.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(message);
            }
        });
    }
    
    async collectCurrentMetrics() {
        const [
            systemMetrics,
            applicationMetrics,
            businessMetrics
        ] = await Promise.all([
            this.getSystemMetrics(),
            this.getApplicationMetrics(),
            metricsService.getAppointmentMetrics('1h')
        ]);
        
        return {
            system: systemMetrics,
            application: applicationMetrics,
            business: businessMetrics
        };
    }
    
    async getSystemMetrics() {
        // Get system metrics from Prometheus
        const prometheusUrl = process.env.PROMETHEUS_URL || 'http://localhost:9090';
        
        try {
            const responses = await Promise.all([
                axios.get(`${prometheusUrl}/api/v1/query?query=up{job=~"healthcare-.*"}`),
                axios.get(`${prometheusUrl}/api/v1/query?query=rate(http_requests_total[5m])`),
                axios.get(`${prometheusUrl}/api/v1/query?query=histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`)
            ]);
            
            return {
                uptime: responses[0].data.data.result,
                requestRate: responses[1].data.data.result,
                responseTime: responses[2].data.data.result
            };
        } catch (error) {
            console.error('Error fetching system metrics:', error);
            return null;
        }
    }
    
    async getApplicationMetrics() {
        return {
            activeConnections: this.clients.size,
            memoryUsage: process.memoryUsage(),
            uptime: process.uptime()
        };
    }
    
    startMetricsCollection() {
        // Broadcast metrics every 10 seconds
        setInterval(() => {
            this.broadcastMetrics();
        }, 10000);
    }
}

// Initialize real-time monitoring
const realTimeMonitoring = new RealTimeMonitoring();

module.exports = realTimeMonitoring;
```

---

**This comprehensive monitoring guide ensures complete observability of the Healthcare DevOps Pipeline with metrics, alerting, and real-time monitoring capabilities.**
