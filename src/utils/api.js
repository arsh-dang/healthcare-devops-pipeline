// API Configuration for different environments
// This ensures consistent API endpoint usage across the application

const isProduction = process.env.NODE_ENV === 'production';
const isContainer = process.env.REACT_APP_ENVIRONMENT === 'staging' || process.env.REACT_APP_ENVIRONMENT === 'production';

// API Base URLs for different environments
const API_BASE_URLS = {
  development: process.env.REACT_APP_API_BASE_URL || 'http://localhost:5001',
  production: process.env.REACT_APP_API_BASE_URL || '',  // Empty for relative URLs via nginx proxy
  test: process.env.REACT_APP_API_BASE_URL || 'http://localhost:5001'
};

// Determine current environment
let currentEnv = 'development';
if (isContainer) {
  currentEnv = 'production';  // Use production config in containers (relative URLs)
} else if (isProduction) {
  currentEnv = 'production';
} else {
  currentEnv = process.env.NODE_ENV || 'development';
}

export const API_BASE_URL = API_BASE_URLS[currentEnv];

// Full API endpoints
export const API_ENDPOINTS = {
  appointments: API_BASE_URL ? `${API_BASE_URL}/api/appointments` : '/api/appointments',
  health: API_BASE_URL ? `${API_BASE_URL}/health` : '/api/health',
  metrics: API_BASE_URL ? `${API_BASE_URL}/metrics` : '/api/metrics'
};

// Helper function to build API URLs
export const buildApiUrl = (endpoint, params = {}) => {
  let url = API_ENDPOINTS[endpoint] || (API_BASE_URL ? `${API_BASE_URL}${endpoint}` : endpoint);
  
  // Add query parameters if provided
  if (Object.keys(params).length > 0) {
    const searchParams = new URLSearchParams(params);
    url += `?${searchParams.toString()}`;
  }
  
  return url;
};