const { execSync } = require('child_process');
const axios = require('axios');

// Configuration
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:5001/api';
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:3001';

// For Jenkins/CI environment, try host machine IP if localhost fails
const CI_API_BASE_URL = process.env.CI_API_BASE_URL || 'http://host.docker.internal:5001/api';
const CI_FRONTEND_URL = process.env.CI_FRONTEND_URL || 'http://host.docker.internal:3001';

// Test results
let testResults = {
  passed: 0,
  failed: 0,
  total: 0,
  details: []
};

async function runTest(testName, testFunction) {
  try {
    console.log(`🧪 Running ${testName}...`);
    await testFunction();
    testResults.passed++;
    testResults.details.push({ name: testName, status: 'PASSED' });
    console.log(`✅ ${testName} - PASSED`);
  } catch (error) {
    testResults.failed++;
    const errorDetails = {
      name: testName,
      status: 'FAILED',
      error: error.message,
      stack: error.stack,
      config: error.config ? {
        url: error.config.url,
        method: error.config.method,
        timeout: error.config.timeout
      } : undefined,
      response: error.response ? {
        status: error.response.status,
        statusText: error.response.statusText,
        data: error.response.data
      } : undefined
    };
    testResults.details.push(errorDetails);
    console.log(`❌ ${testName} - FAILED: ${error.message}`);
    if (error.response) {
      console.log(`   Response Status: ${error.response.status}`);
      console.log(`   Response Data:`, error.response.data);
    }
    if (error.config) {
      console.log(`   Request URL: ${error.config.url}`);
    }
  }
  testResults.total++;
}

async function testHealthEndpoint() {
  let apiUrl = API_BASE_URL;
  
  // Try CI URL first if we're in a CI environment
  if (process.env.CI || process.env.JENKINS_URL) {
    try {
      const response = await axios.get(`${CI_API_BASE_URL.replace('/api', '')}/health`, { timeout: 5000 });
      if (response.status === 200 && response.data.status === 'ok') {
        return; // Success with CI URL
      }
    } catch (error) {
      console.log('CI URL failed, trying localhost...');
      apiUrl = API_BASE_URL;
    }
  }
  
  const response = await axios.get(`${apiUrl.replace('/api', '')}/health`);
  if (response.status !== 200 || response.data.status !== 'ok') {
    throw new Error('Health check failed');
  }
}

async function testAppointmentsAPI() {
  let apiUrl = API_BASE_URL;
  
  // Try CI URL first if we're in a CI environment
  if (process.env.CI || process.env.JENKINS_URL) {
    try {
      const testResponse = await axios.get(`${CI_API_BASE_URL}/appointments`, { timeout: 5000 });
      if (testResponse.status === 200) {
        apiUrl = CI_API_BASE_URL; // Use CI URL for the rest of the test
      }
    } catch (error) {
      console.log('CI API URL failed, trying localhost...');
      apiUrl = API_BASE_URL;
    }
  }
  
  // Test GET /api/appointments
  const response = await axios.get(`${apiUrl}/appointments`);
  if (response.status !== 200) {
    throw new Error(`GET appointments failed with status ${response.status}`);
  }
  
  // Test POST /api/appointments
  const newAppointment = {
    title: 'Integration Test Appointment',
    description: 'Automated integration test appointment',
    dateTime: new Date().toISOString(),
    clinic: 'test-clinic',
    clinicName: 'Test Clinic',
    image: 'test-image.jpg',
    address: '123 Test Street, Test City',
    doctor: 'Dr. Test',
    doctorSpecialty: 'General Practice'
  };
  
  const createResponse = await axios.post(`${apiUrl}/appointments`, newAppointment);
  if (createResponse.status !== 201) {
    throw new Error(`POST appointment failed with status ${createResponse.status}`);
  }
  
  // Clean up - delete the test appointment
  if (createResponse.data._id) {
    await axios.delete(`${apiUrl}/appointments/${createResponse.data._id}`);
  }
}

async function testFrontendAvailability() {
  let frontendUrl = FRONTEND_URL;
  
  // Try CI URL first if we're in a CI environment
  if (process.env.CI || process.env.JENKINS_URL) {
    try {
      const response = await axios.get(CI_FRONTEND_URL, { timeout: 5000 });
      if (response.status === 200) {
        return; // Success with CI URL
      }
    } catch (error) {
      console.log('CI Frontend URL failed, trying localhost...');
      frontendUrl = FRONTEND_URL;
    }
  }
  
  const response = await axios.get(frontendUrl);
  if (response.status !== 200) {
    throw new Error(`Frontend not accessible, status: ${response.status}`);
  }
}

async function testDatabaseConnection() {
  let apiUrl = API_BASE_URL;
  
  // Try CI URL first if we're in a CI environment  
  if (process.env.CI || process.env.JENKINS_URL) {
    try {
      const response = await axios.get(`${CI_API_BASE_URL}/appointments`, { timeout: 5000 });
      if (response.status === 200) {
        return; // Success with CI URL
      }
    } catch (error) {
      console.log('CI Database test failed, trying localhost...');
      apiUrl = API_BASE_URL;
    }
  }
  
  // This test assumes the backend has a specific endpoint for DB health
  // If not available, this will test through the appointments endpoint
  try {
    const response = await axios.get(`${apiUrl}/appointments`);
    if (response.status !== 200) {
      throw new Error('Database connection test failed');
    }
  } catch (error) {
    throw new Error(`Database connection test failed: ${error.message}`);
  }
}

async function runIntegrationTests() {
  console.log('🚀 Starting Integration Tests...');
  console.log(`API Base URL: ${API_BASE_URL}`);
  console.log(`Frontend URL: ${FRONTEND_URL}`);
  
  // Show CI environment URLs if available
  if (process.env.CI || process.env.JENKINS_URL) {
    console.log(`CI API Base URL: ${CI_API_BASE_URL}`);
    console.log(`CI Frontend URL: ${CI_FRONTEND_URL}`);
    console.log('Running in CI environment - will try CI URLs first');
  }
  
  // Wait for services to be ready
  console.log('⏳ Waiting for services to be ready...');
  await new Promise(resolve => setTimeout(resolve, 10000));
  
  // Run all tests
  await runTest('Health Endpoint Test', testHealthEndpoint);
  await runTest('Database Connection Test', testDatabaseConnection);
  await runTest('Appointments API Test', testAppointmentsAPI);
  await runTest('Frontend Availability Test', testFrontendAvailability);
  
  // Print summary
  console.log('\n📊 Integration Test Summary:');
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
  
  // Exit with appropriate code
  process.exit(testResults.failed > 0 ? 1 : 0);
}

// Run the tests
runIntegrationTests().catch(error => {
  console.error('💥 Integration tests crashed:', error);
  process.exit(1);
});
