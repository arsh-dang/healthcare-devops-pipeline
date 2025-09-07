#!/usr/bin/env node

/**
 * Monitoring verification script for Grafana and Prometheus
 * Tests basic connectivity and health endpoints
 */

const http = require('http');
const https = require('https');

const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function makeRequest(url, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const req = client.get(url, { timeout }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          data: data
        });
      });
    });
    
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

async function testEndpoint(name, url, expectedStatus = 200) {
  try {
    log(`Testing ${name}...`, 'blue');
    const response = await makeRequest(url);
    
    if (response.statusCode === expectedStatus) {
      log(`✓ ${name}: OK (${response.statusCode})`, 'green');
      return true;
    } else {
      log(`✗ ${name}: Unexpected status ${response.statusCode}`, 'red');
      return false;
    }
  } catch (error) {
    log(`✗ ${name}: ${error.message}`, 'red');
    return false;
  }
}

async function testPrometheusTargets(url) {
  try {
    log('Testing Prometheus targets...', 'blue');
    const response = await makeRequest(url);
    
    if (response.statusCode === 200) {
      const data = JSON.parse(response.data);
      const activeTargets = data.data?.activeTargets || [];
      const healthyTargets = activeTargets.filter(t => t.health === 'up');
      
      log(`✓ Prometheus targets: ${healthyTargets.length}/${activeTargets.length} healthy`, 'green');
      
      // Log target details
      activeTargets.forEach(target => {
        const status = target.health === 'up' ? '✓' : '✗';
        const color = target.health === 'up' ? 'green' : 'red';
        log(`  ${status} ${target.job}: ${target.instance} (${target.health})`, color);
      });
      
      return healthyTargets.length > 0;
    } else {
      log(`✗ Prometheus targets: HTTP ${response.statusCode}`, 'red');
      return false;
    }
  } catch (error) {
    log(`✗ Prometheus targets: ${error.message}`, 'red');
    return false;
  }
}

async function main() {
  const args = process.argv.slice(2);
  const grafanaPort = args[0] || '3000';
  const prometheusPort = args[1] || '9090';
  
  log('Healthcare App Monitoring Verification', 'blue');
  log('=====================================', 'blue');
  
  const results = [];
  
  // Test Grafana
  results.push(await testEndpoint('Grafana Login', `http://localhost:${grafanaPort}/login`));
  
  // Test Prometheus
  results.push(await testEndpoint('Prometheus Ready', `http://localhost:${prometheusPort}/-/ready`));
  results.push(await testEndpoint('Prometheus Health', `http://localhost:${prometheusPort}/-/healthy`));
  
  // Test Prometheus targets
  results.push(await testPrometheusTargets(`http://localhost:${prometheusPort}/api/v1/targets`));
  
  // Summary
  log('\nSummary:', 'blue');
  const passed = results.filter(r => r).length;
  const total = results.length;
  
  if (passed === total) {
    log(`✓ All ${total} tests passed`, 'green');
    process.exit(0);
  } else {
    log(`✗ ${total - passed}/${total} tests failed`, 'red');
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch(error => {
    log(`Fatal error: ${error.message}`, 'red');
    process.exit(1);
  });
}

module.exports = { testEndpoint, testPrometheusTargets };
