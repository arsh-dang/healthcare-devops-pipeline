const { execSync } = require('child_process');
const axios = require('axios');

// Configuration
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:5001/api';
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:3001';

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
    testResults.details.push({ 
      name: testName, 
      status: 'FAILED', 
      error: error.message 
    });
    console.log(`❌ ${testName} - FAILED: ${error.message}`);
  }
  testResults.total++;
}

async function testHealthEndpoint() {
  const response = await axios.get(`${API_BASE_URL.replace('/api', '')}/health`);
  if (response.status !== 200 || response.data.status !== 'ok') {
    throw new Error('Health check failed');
  }
}

async function testAppointmentsAPI() {
  // Test GET /api/appointments
  const response = await axios.get(`${API_BASE_URL}/appointments`);
  if (response.status !== 200) {
    throw new Error(`GET appointments failed with status ${response.status}`);
  }
  
  // Test POST /api/appointments
  const newAppointment = {
    patientName: 'Integration Test Patient',
    doctorName: 'Dr. Test',
    appointmentDate: new Date().toISOString(),
    appointmentTime: '10:00',
    clinic: 'Test Clinic'
  };
  
  const createResponse = await axios.post(`${API_BASE_URL}/appointments`, newAppointment);
  if (createResponse.status !== 201) {
    throw new Error(`POST appointment failed with status ${createResponse.status}`);
  }
  
  // Clean up - delete the test appointment
  if (createResponse.data.id) {
    await axios.delete(`${API_BASE_URL}/appointments/${createResponse.data.id}`);
  }
}

async function testFrontendAvailability() {
  const response = await axios.get(FRONTEND_URL);
  if (response.status !== 200) {
    throw new Error(`Frontend not accessible, status: ${response.status}`);
  }
}

async function testDatabaseConnection() {
  // This test assumes the backend has a specific endpoint for DB health
  // If not available, this will test through the appointments endpoint
  try {
    const response = await axios.get(`${API_BASE_URL}/appointments`);
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
