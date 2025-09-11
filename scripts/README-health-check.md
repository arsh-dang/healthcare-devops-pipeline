# Health Check Script

This script performs comprehensive health checks for the Healthcare App deployment.

## Usage

```bash
# Run with default URLs
./scripts/health-check.sh

# Run with custom URLs
APP_URL="http://your-frontend-url:3001" API_URL="http://your-api-url:5001" ./scripts/health-check.sh
```

## Environment Variables

- `APP_URL`: Frontend application URL (default: http://localhost:3000)
- `API_URL`: Backend API URL (default: http://localhost:5001)
- `TIMEOUT`: HTTP request timeout in seconds (default: 10)

## Health Checks Performed

1. **Frontend Application**: Checks if the React app is responding (HTTP 200)
2. **API Health Endpoint**: Checks `/health` endpoint (HTTP 200)
3. **API Appointments Endpoint**: Checks `/api/appointments` endpoint (HTTP 200)
4. **Database Connectivity**: Tests MongoDB connection
5. **Performance**: Checks response time (< 2 seconds)

## Exit Codes

- `0`: All health checks passed (success rate >= 90%)
- `1`: Health checks failed (success rate < 90%)

## Integration with Jenkins

The script is automatically used by the Jenkins pipeline during blue-green deployments. If the script is not found, the pipeline falls back to simulation mode.

## Requirements

- `curl` for HTTP requests
- `mongosh` or `mongo` for database connectivity checks (optional)
- `bc` for performance calculations (optional)
