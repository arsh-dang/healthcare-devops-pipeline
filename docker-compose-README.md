# Local Development Commands
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services  
docker-compose down

# Rebuild and restart
docker-compose up --build -d

# Run tests
docker-compose exec backend npm test

# Access database
docker-compose exec mongodb mongosh -u admin -p
