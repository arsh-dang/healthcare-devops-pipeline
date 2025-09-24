const axios = require('axios');

// Configuration for monitoring stack
const MONITORING_BASE_URL = process.env.MONITORING_BASE_URL || 'http://localhost';
const GRAFANA_PORT = process.env.GRAFANA_PORT || '32679';
const PROMETHEUS_PORT = process.env.PROMETHEUS_PORT || '32683';
const ALERTMANAGER_PORT = process.env.ALERTMANAGER_PORT || '32681';

// Test results
let testResults = {
  passed: 0,
  failed: 0,
  total: 0,
  details: []
};

async function runTest(testName, testFunction) {
  try {
    console.log(`Running ${testName}...`);
    await testFunction();
    testResults.passed++;
    testResults.details.push({ name: testName, status: 'PASSED' });
    console.log(`[SUCCESS] ${testName} - PASSED`);
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
    console.log(`[ERROR] ${testName} - FAILED: ${error.message}`);
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

async function testGrafanaHealth() {
  const grafanaUrl = `${MONITORING_BASE_URL}:${GRAFANA_PORT}`;
  const response = await axios.get(grafanaUrl, {
    timeout: 10000,
    headers: {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }
  });

  if (response.status !== 200) {
    throw new Error(`Grafana not accessible, status: ${response.status}`);
  }

  // Check if response contains Grafana branding
  if (!response.data.includes('Grafana') && !response.data.includes('grafana')) {
    throw new Error('Grafana response does not contain expected content');
  }
}

async function testPrometheusHealth() {
  const prometheusUrl = `${MONITORING_BASE_URL}:${PROMETHEUS_PORT}/-/healthy`;
  const response = await axios.get(prometheusUrl, { timeout: 5000 });

  if (response.status !== 200) {
    throw new Error(`Prometheus health check failed, status: ${response.status}`);
  }

  if (response.data !== 'Prometheus Server is Healthy.') {
    throw new Error(`Unexpected Prometheus health response: ${response.data}`);
  }
}

async function testPrometheusMetrics() {
  const prometheusUrl = `${MONITORING_BASE_URL}:${PROMETHEUS_PORT}/api/v1/query?query=up`;
  const response = await axios.get(prometheusUrl, { timeout: 5000 });

  if (response.status !== 200) {
    throw new Error(`Prometheus metrics query failed, status: ${response.status}`);
  }

  if (!response.data.status || response.data.status !== 'success') {
    throw new Error('Prometheus metrics query did not return success status');
  }
}

async function testAlertmanagerHealth() {
  const alertmanagerUrl = `${MONITORING_BASE_URL}:${ALERTMANAGER_PORT}/-/healthy`;
  const response = await axios.get(alertmanagerUrl, { timeout: 5000 });

  if (response.status !== 200) {
    throw new Error(`Alertmanager health check failed, status: ${response.status}`);
  }

  if (response.data !== 'OK') {
    throw new Error(`Unexpected Alertmanager health response: ${response.data}`);
  }
}

async function testAlertmanagerStatus() {
  const alertmanagerUrl = `${MONITORING_BASE_URL}:${ALERTMANAGER_PORT}/api/v2/status`;
  const response = await axios.get(alertmanagerUrl, { timeout: 5000 });

  if (response.status !== 200) {
    throw new Error(`Alertmanager status check failed, status: ${response.status}`);
  }

  if (!response.data.versionInfo) {
    throw new Error('Alertmanager status does not contain version info');
  }
}

async function runMonitoringIntegrationTests() {
  console.log('Starting Monitoring Integration Tests...');
  console.log(`Monitoring Base URL: ${MONITORING_BASE_URL}`);
  console.log(`Grafana Port: ${GRAFANA_PORT}`);
  console.log(`Prometheus Port: ${PROMETHEUS_PORT}`);
  console.log(`Alertmanager Port: ${ALERTMANAGER_PORT}`);

  // Wait for services to be ready
  console.log('Waiting for monitoring services to be ready...');
  await new Promise(resolve => setTimeout(resolve, 5000));

  // Run all monitoring tests
  await runTest('Grafana Health Test', testGrafanaHealth);
  await runTest('Prometheus Health Test', testPrometheusHealth);
  await runTest('Prometheus Metrics Test', testPrometheusMetrics);
  await runTest('Alertmanager Health Test', testAlertmanagerHealth);
  await runTest('Alertmanager Status Test', testAlertmanagerStatus);

  // Print summary
  console.log('\nMonitoring Integration Test Summary:');
  console.log(`Total Tests: ${testResults.total}`);
  console.log(`Passed: ${testResults.passed}`);
  console.log(`Failed: ${testResults.failed}`);
  console.log(`Success Rate: ${((testResults.passed / testResults.total) * 100).toFixed(2)}%`);

  if (testResults.failed > 0) {
    console.log('\n[ERROR] Failed Tests:');
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
runMonitoringIntegrationTests().catch(error => {
  console.error('Monitoring integration tests crashed:', error);
  process.exit(1);
});
