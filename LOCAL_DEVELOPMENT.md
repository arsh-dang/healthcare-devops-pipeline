# Local Development Guide

## Quick Start

### Full Stack Development
```bash
# Start all services (MongoDB, Backend, Frontend, Redis)
docker-compose --profile full up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Backend-Only Development
```bash
# Start only MongoDB and Backend
docker-compose --profile backend-only up -d

# Access API at http://localhost:5001
```

### Frontend-Only Development
```bash
# Start only Frontend (requires backend running separately)
docker-compose --profile frontend-only up -d

# Access app at http://localhost:3000
```

## Development URLs

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5001
- **MongoDB**: localhost:27017
- **Redis**: localhost:6379

## Useful Commands

```bash
# Rebuild and restart all services
docker-compose up --build -d

# View specific service logs
docker-compose logs -f backend

# Execute commands in containers
docker-compose exec backend bash
docker-compose exec mongodb mongosh -u admin -p

# Run backend tests
docker-compose exec backend npm test

# Clean up everything
docker-compose down -v --remove-orphans
```

## Environment Variables

Create a `.env` file in the project root:

```bash
# Database
MONGODB_USERNAME=admin
MONGODB_PASSWORD=securepassword123
MONGODB_DATABASE=healthcare-app

# JWT
JWT_SECRET=your-super-secret-jwt-key

# API
NODE_ENV=development
LOG_LEVEL=debug

# Frontend
REACT_APP_API_BASE_URL=http://localhost:5001/api
```

## Troubleshooting

### Port Conflicts
If ports are already in use:
```bash
# Find what's using the port
lsof -i :3000

# Kill the process
kill -9 <PID>
```

### Database Issues
```bash
# Reset database
docker-compose down -v
docker-compose up -d mongodb

# Access MongoDB shell
docker-compose exec mongodb mongosh -u admin -p securepassword123
```

### Build Issues
```bash
# Clean build
docker-compose build --no-cache
docker-compose up -d
```

## Alternative: Direct Development

For faster development without Docker:

### Backend
```bash
cd server
npm install
npm run dev
```

### Frontend
```bash
npm install
npm start
```

### Database
Use local MongoDB or MongoDB Atlas for database.

## Testing

```bash
# Unit tests
docker-compose exec backend npm test

# Integration tests
docker-compose exec backend npm run test:integration

# E2E tests (requires full stack)
npm run test:e2e
```
