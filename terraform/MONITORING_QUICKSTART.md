# Monitoring Enhancements Quick Start

## Overview
Your healthcare application now has comprehensive monitoring capabilities including:
- **Ingress Monitoring** - Nginx Ingress Controller with metrics
- **Log Aggregation** - Fluent Bit for centralized logging
- **Synthetic Monitoring** - Automated health checks
- **Distributed Tracing** - Jaeger for request tracing
- **Enhanced Alerting** - Advanced Prometheus rules
- **Grafana Dashboards** - Rich visualizations

## Quick Deployment

### 1. Deploy Monitoring Infrastructure
```bash
cd terraform
terraform apply
```

### 2. Validate Deployment
```bash
./deploy-monitoring.sh [environment]
```
Replace `[environment]` with `staging` or `production`.

### 3. Test Monitoring Components
```bash
./test-monitoring.sh [environment]
```

## Access Monitoring Interfaces

### Grafana (Dashboards & Visualizations)
```bash
kubectl port-forward -n monitoring-staging svc/grafana 3000:3000
```
- URL: http://localhost:3000
- Default credentials: admin/admin

### Prometheus (Metrics & Querying)
```bash
kubectl port-forward -n monitoring-staging svc/prometheus 9090:9090
```
- URL: http://localhost:9090

### Jaeger (Distributed Tracing)
```bash
kubectl port-forward -n monitoring-staging svc/jaeger 16686:16686
```
- URL: http://localhost:16686

### Alertmanager (Alert Management)
```bash
kubectl port-forward -n monitoring-staging svc/alertmanager 9093:9093
```
- URL: http://localhost:9093

## Key Features Added

### Ingress Monitoring
- Real-time request metrics
- Response time tracking
- Error rate monitoring
- Traffic pattern analysis

### Log Aggregation
- Centralized application logs
- Kubernetes metadata enrichment
- Structured logging support
- Log filtering and routing

### Synthetic Monitoring
- Automated health checks
- Endpoint availability testing
- Performance monitoring
- SLA compliance tracking

### Distributed Tracing
- Request flow visualization
- Performance bottleneck identification
- Service dependency mapping
- Error trace analysis

## Configuration Variables

The following Terraform variables control the monitoring features:

```hcl
enable_ingress_monitoring    = true
enable_log_aggregation       = true
enable_synthetic_monitoring  = true
enable_distributed_tracing   = true
```

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource quotas and RBAC permissions
2. **Metrics not appearing**: Verify service discovery and scrape configurations
3. **Logs not aggregating**: Check Fluent Bit configuration and permissions
4. **Traces not showing**: Ensure application instrumentation is enabled

### Useful Commands

```bash
# Check pod status
kubectl get pods -n monitoring-staging

# View logs
kubectl logs -n monitoring-staging deployment/prometheus

# Check services
kubectl get services -n monitoring-staging

# Debug network issues
kubectl exec -it deployment/prometheus -n monitoring-staging -- /bin/sh
```

## Next Steps

1. **Configure Application Instrumentation**: Add tracing libraries to your backend
2. **Set up Alert Notifications**: Configure Alertmanager receivers (email, Slack, etc.)
3. **Create Custom Dashboards**: Build application-specific Grafana dashboards
4. **Implement Log Retention**: Set up log storage and rotation policies
5. **Performance Tuning**: Adjust scrape intervals and retention based on your needs

## Support

For detailed documentation, see `MONITORING_ENHANCEMENTS.md` in the terraform directory.
