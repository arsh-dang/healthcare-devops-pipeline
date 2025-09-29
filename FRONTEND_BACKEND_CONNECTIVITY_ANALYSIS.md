# Frontend-Backend Connectivity Analysis

## 🚨 **CRITICAL CONNECTIVITY ISSUES IDENTIFIED**

### **❌ Problem 1: Missing Frontend Environment Variables**

#### **Frontend Deployment Configuration**
The frontend deployment in `terraform/main.tf` is **missing critical environment variables**:

```terraform
# Current frontend deployment - MISSING API configuration
resource "kubernetes_deployment" "frontend" {
  # ... metadata and spec ...
  spec {
    template {
      spec {
        container {
          name  = "frontend"
          image = var.frontend_image
          # ❌ MISSING: No environment variables for API configuration
          # ❌ MISSING: No REACT_APP_API_BASE_URL
          # ❌ MISSING: No NODE_ENV
        }
      }
    }
  }
}
```

#### **What's Missing:**
- `REACT_APP_API_BASE_URL` environment variable
- `NODE_ENV` environment variable
- Any environment configuration for the frontend container

### **❌ Problem 2: Inconsistent API Configuration**

#### **Frontend API Configuration (`src/utils/api.js`)**
```javascript
const API_BASE_URLS = {
  development: 'http://localhost:5001',           // ✅ Correct for dev
  production: 'http://backend:5001',              // ❌ WRONG for Kubernetes
  test: 'http://localhost:5001'                   // ✅ Correct for test
};
```

#### **The Issue:**
- **Production URL**: `http://backend:5001` - This won't work in Kubernetes
- **Kubernetes Service Name**: Should be `http://backend.healthcare-staging.svc.cluster.local:5001`
- **Environment Detection**: Uses `NODE_ENV === 'production'` but container doesn't set this

### **❌ Problem 3: Nginx Configuration Mismatch**

#### **Nginx Proxy Configuration (`nginx.conf`)**
```nginx
location /api {
    proxy_pass http://backend.healthcare-staging.svc.cluster.local:5001;
    # ✅ Correct Kubernetes service URL
}
```

#### **The Issue:**
- **Nginx expects**: Frontend to make API calls to `/api` (relative URLs)
- **Frontend actually makes**: Calls to `http://backend:5001/api/appointments` (absolute URLs)
- **Result**: Frontend bypasses nginx proxy entirely

### **❌ Problem 4: Environment Detection Logic**

#### **Current Logic (`src/utils/api.js`)**
```javascript
const isProduction = process.env.NODE_ENV === 'production';
const currentEnv = isProduction ? 'production' : (process.env.NODE_ENV || 'development');
```

#### **The Issue:**
- **Container Environment**: `NODE_ENV` is not set in the frontend container
- **Default Behavior**: Falls back to `'development'` mode
- **API URL**: Uses `http://localhost:5001` (which doesn't exist in container)

---

## 🔧 **REQUIRED FIXES**

### **Fix 1: Add Frontend Environment Variables**

#### **Update `terraform/main.tf` Frontend Deployment**
```terraform
resource "kubernetes_deployment" "frontend" {
  # ... existing configuration ...
  
  spec {
    template {
      spec {
        container {
          name  = "frontend"
          image = var.frontend_image
          
          # ✅ ADD: Environment variables
          env {
            name  = "NODE_ENV"
            value = "production"
          }
          
          env {
            name  = "REACT_APP_API_BASE_URL"
            value = ""  # Empty for relative URLs via nginx proxy
          }
          
          env {
            name  = "REACT_APP_ENVIRONMENT"
            value = var.environment
          }
          
          # ... rest of container config ...
        }
      }
    }
  }
}
```

### **Fix 2: Update Frontend API Configuration**

#### **Update `src/utils/api.js`**
```javascript
// API Configuration for different environments
const isProduction = process.env.NODE_ENV === 'production';
const isContainer = process.env.REACT_APP_ENVIRONMENT === 'staging' || process.env.REACT_APP_ENVIRONMENT === 'production';

// API Base URLs for different environments
const API_BASE_URLS = {
  development: process.env.REACT_APP_API_BASE_URL || 'http://localhost:5001',
  production: process.env.REACT_APP_API_BASE_URL || '',  // Empty for relative URLs
  test: process.env.REACT_APP_API_BASE_URL || 'http://localhost:5001'
};

// Determine current environment
let currentEnv = 'development';
if (isContainer) {
  currentEnv = 'production';  // Use production config in containers
} else if (isProduction) {
  currentEnv = 'production';
} else {
  currentEnv = process.env.NODE_ENV || 'development';
}

export const API_BASE_URL = API_BASE_URLS[currentEnv];
```

### **Fix 3: Update API Endpoints for Relative URLs**

#### **Update API endpoint construction**
```javascript
// Full API endpoints
export const API_ENDPOINTS = {
  appointments: API_BASE_URL ? `${API_BASE_URL}/api/appointments` : '/api/appointments',
  health: API_BASE_URL ? `${API_BASE_URL}/health` : '/api/health',
  metrics: API_BASE_URL ? `${API_BASE_URL}/metrics` : '/api/metrics'
};
```

---

## 🎯 **CONNECTIVITY SCENARIOS**

### **✅ Scenario 1: Development Environment**
- **Frontend**: React dev server on port 3001
- **Backend**: Node.js on port 5001
- **API Calls**: Direct to `http://localhost:5001/api/appointments`
- **Status**: ✅ **WORKS** (direct connection)

### **❌ Scenario 2: Container Environment (Current)**
- **Frontend**: Nginx container on port 80
- **Backend**: Node.js container on port 5001
- **API Calls**: Attempts `http://backend:5001/api/appointments`
- **Status**: ❌ **FAILS** (backend hostname not resolvable)

### **✅ Scenario 3: Container Environment (Fixed)**
- **Frontend**: Nginx container on port 80 with environment variables
- **Backend**: Node.js container on port 5001
- **API Calls**: Relative URLs `/api/appointments` → nginx proxy → backend
- **Status**: ✅ **WORKS** (via nginx proxy)

### **✅ Scenario 4: Port Forwarding Environment**
- **Frontend**: Local port 8082 → Container port 80
- **Backend**: Local port 8083 → Container port 5001
- **API Calls**: Direct to `http://localhost:8083/api/appointments`
- **Status**: ✅ **WORKS** (direct connection to port-forwarded backend)

---

## 🚀 **IMPLEMENTATION PLAN**

### **Step 1: Update Terraform Configuration**
1. Add environment variables to frontend deployment
2. Set `NODE_ENV=production` and `REACT_APP_ENVIRONMENT=staging`
3. Set `REACT_APP_API_BASE_URL=""` for relative URLs

### **Step 2: Update Frontend Code**
1. Modify `src/utils/api.js` to handle container environment
2. Use relative URLs when `REACT_APP_API_BASE_URL` is empty
3. Update environment detection logic

### **Step 3: Test Connectivity**
1. Deploy updated configuration
2. Test API calls from frontend
3. Verify nginx proxy routing
4. Test port forwarding access

---

## 📊 **Summary**

### **Current Status: ❌ FRONTEND-BACKEND CONNECTIVITY BROKEN**

#### **Root Causes:**
1. **Missing Environment Variables**: Frontend container has no API configuration
2. **Wrong API URLs**: Uses `http://backend:5001` instead of relative URLs
3. **Environment Detection**: Falls back to development mode in containers
4. **Bypassed Proxy**: Frontend doesn't use nginx proxy for API calls

#### **Impact:**
- **Container Environment**: Frontend cannot reach backend API
- **User Experience**: API calls fail, appointments cannot be loaded/saved
- **Application Functionality**: Healthcare app is non-functional in containers

#### **Required Actions:**
1. **Immediate**: Add environment variables to frontend deployment
2. **Code Changes**: Update API configuration for relative URLs
3. **Testing**: Verify connectivity in all environments
4. **Deployment**: Rebuild and redeploy containers

**Priority**: 🚨 **CRITICAL** - Application is currently non-functional in container environment
