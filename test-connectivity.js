#!/usr/bin/env node

/**
 * Healthcare App Connectivity Test
 * Tests frontend-backend connectivity in different environments
 */

const axios = require('axios');

// Configuration for different environments
const ENVIRONMENTS = {
  development: {
    frontend: 'http://localhost:3001',
    backend: 'http://localhost:5001',
    description: 'Local development environment'
  },
  container: {
    frontend: 'http://localhost:8082',
    backend: 'http://localhost:8083',
    description: 'Container environment via port forwarding'
  },
  nginx: {
    frontend: 'http://localhost:8082',
    backend: 'http://localhost:8082/api',
    description: 'Container environment via nginx proxy'
  }
};

// Test results
let testResults = {
  passed: 0,
  failed: 0,
  total: 0,
  details: []
};

async function runTest(testName, testFunction) {
  try {
    console.log(`\n🧪 Running ${testName}...`);
    await testFunction();
    testResults.passed++;
    testResults.details.push({ name: testName, status: 'PASSED' });
    console.log(`✅ ${testName} - PASSED`);
  } catch (error) {
    testResults.failed++;
    testResults.details.push({ name: testName, status: 'FAILED', error: error.message });
    console.log(`❌ ${testName} - FAILED: ${error.message}`);
  }
  testResults.total++;
}

async function testBackendDirect(environment) {
  const backendUrl = environment.backend;
  console.log(`   Testing direct backend connection: ${backendUrl}`);
  
  const response = await axios.get(`${backendUrl}/health`, { timeout: 5000 });
  
  if (response.status !== 200) {
    throw new Error(`Backend health check failed with status ${response.status}`);
  }
  
  if (response.data.status !== 'ok') {
    throw new Error(`Backend health check returned invalid status: ${response.data.status}`);
  }
  
  console.log(`   ✅ Backend health check passed`);
}

async function testFrontendDirect(environment) {
  const frontendUrl = environment.frontend;
  console.log(`   Testing direct frontend connection: ${frontendUrl}`);
  
  const response = await axios.get(frontendUrl, { timeout: 5000 });
  
  if (response.status !== 200) {
    throw new Error(`Frontend connection failed with status ${response.status}`);
  }
  
  console.log(`   ✅ Frontend connection passed`);
}

async function testAPIViaNginx(environment) {
  const nginxUrl = environment.backend;
  console.log(`   Testing API via nginx proxy: ${nginxUrl}`);
  
  // Test health endpoint
  const healthResponse = await axios.get(`${nginxUrl}/health`, { timeout: 5000 });
  
  if (healthResponse.status !== 200) {
    throw new Error(`Nginx proxy health check failed with status ${healthResponse.status}`);
  }
  
  if (healthResponse.data.status !== 'ok') {
    throw new Error(`Nginx proxy health check returned invalid status: ${healthResponse.data.status}`);
  }
  
  // Test appointments endpoint
  const appointmentsResponse = await axios.get(`${nginxUrl}/appointments`, { timeout: 5000 });
  
  if (appointmentsResponse.status !== 200) {
    throw new Error(`Nginx proxy appointments check failed with status ${appointmentsResponse.status}`);
  }
  
  console.log(`   ✅ Nginx proxy API calls passed`);
}

async function testFrontendBackendIntegration(environment) {
  console.log(`   Testing frontend-backend integration...`);
  
  // Test if frontend can reach backend through the configured method
  const backendUrl = environment.backend;
  
  // Simulate a frontend API call
  const response = await axios.get(`${backendUrl}/api/appointments`, { timeout: 5000 });
  
  if (response.status !== 200) {
    throw new Error(`Frontend-backend integration failed with status ${response.status}`);
  }
  
  console.log(`   ✅ Frontend-backend integration passed`);
}

async function runEnvironmentTests(envName, environment) {
  console.log(`\n🌐 Testing ${envName} Environment`);
  console.log(`   Description: ${environment.description}`);
  console.log(`   Frontend: ${environment.frontend}`);
  console.log(`   Backend: ${environment.backend}`);
  
  // Test direct backend connection
  await runTest(`${envName} - Backend Direct`, () => testBackendDirect(environment));
  
  // Test direct frontend connection
  await runTest(`${envName} - Frontend Direct`, () => testFrontendDirect(environment));
  
  // Test API via nginx proxy (only for nginx environment)
  if (envName === 'nginx') {
    await runTest(`${envName} - API Via Nginx`, () => testAPIViaNginx(environment));
  }
  
  // Test frontend-backend integration
  await runTest(`${envName} - Frontend-Backend Integration`, () => testFrontendBackendIntegration(environment));
}

async function main() {
  console.log('🚀 Healthcare App Connectivity Test');
  console.log('===================================');
  
  // Test each environment
  for (const [envName, environment] of Object.entries(ENVIRONMENTS)) {
    try {
      await runEnvironmentTests(envName, environment);
    } catch (error) {
      console.log(`❌ ${envName} environment tests failed: ${error.message}`);
    }
  }
  
  // Print summary
  console.log('\n📊 Connectivity Test Summary');
  console.log('============================');
  console.log(`Total Tests: ${testResults.total}`);
  console.log(`Passed: ${testResults.passed}`);
  console.log(`Failed: ${testResults.failed}`);
  console.log(`Success Rate: ${((testResults.passed / testResults.total) * 100).toFixed(2)}%`);
  
  if (testResults.failed > 0) {
    console.log('\n❌ Failed Tests:');
    testResults.details
      .filter(test => test.status === 'FAILED')
      .forEach(test => {
        console.log(`  - ${test.name}: ${test.error}`);
      });
  }
  
  // Recommendations
  console.log('\n💡 Recommendations:');
  
  if (testResults.details.some(test => test.name.includes('Development') && test.status === 'PASSED')) {
    console.log('  ✅ Development environment is working correctly');
  } else {
    console.log('  ⚠️  Development environment needs attention');
  }
  
  if (testResults.details.some(test => test.name.includes('Container') && test.status === 'PASSED')) {
    console.log('  ✅ Container environment is working correctly');
  } else {
    console.log('  ⚠️  Container environment needs attention - check port forwarding');
  }
  
  if (testResults.details.some(test => test.name.includes('nginx') && test.status === 'PASSED')) {
    console.log('  ✅ Nginx proxy routing is working correctly');
  } else {
    console.log('  ⚠️  Nginx proxy routing needs attention - check frontend environment variables');
  }
  
  // Exit with appropriate code
  process.exit(testResults.failed > 0 ? 1 : 0);
}

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (error) => {
  console.error('Unhandled Rejection:', error);
  process.exit(1);
});

// Run the tests
main().catch(error => {
  console.error('Connectivity tests crashed:', error);
  process.exit(1);
});
