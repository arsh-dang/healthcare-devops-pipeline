// API Configuration for different environments
// This ensures consistent API endpoint usage across the application

const isProduction = process.env.NODE_ENV === 'production';
const isDevelopment = process.env.NODE_ENV === 'development';

// API Base URLs for different environments
const API_BASE_URLS = {
  development: process.env.REACT_APP_API_BASE_URL || 'http://localhost:5001',
  production: process.env.REACT_APP_API_BASE_URL || 'http://backend:5001',
  test: process.env.REACT_APP_API_BASE_URL || 'http://localhost:5001'
};

// Determine current environment
const currentEnv = isProduction ? 'production' : (process.env.NODE_ENV || 'development');
export const API_BASE_URL = API_BASE_URLS[currentEnv];

// Full API endpoints
export const API_ENDPOINTS = {
  appointments: `${API_BASE_URL}/api/appointments`,
  health: `${API_BASE_URL}/health`,
  metrics: `${API_BASE_URL}/metrics`
};

// Helper function to build API URLs
export const buildApiUrl = (endpoint, params = {}) => {
  let url = API_ENDPOINTS[endpoint] || `${API_BASE_URL}${endpoint}`;
  
  // Add query parameters if provided
  if (Object.keys(params).length > 0) {
    const searchParams = new URLSearchParams(params);
    url += `?${searchParams.toString()}`;
  }
  
  return url;
};