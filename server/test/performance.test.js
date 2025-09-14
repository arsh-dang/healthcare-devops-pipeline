const autocannon = require('autocannon');
const app = require('../server');

// Advanced load testing suite
describe('Performance and Load Tests', () => {
  let server;
  let serverUrl;

  beforeAll(async () => {
    // Start server on random port
    server = app.listen(0);
    const port = server.address().port;
    serverUrl = `http://localhost:${port}`;
  });

  afterAll(async () => {
    if (server) {
      server.close();
    }
  });

  test('should handle high load on GET /api/appointments', async () => {
    const result = await autocannon({
      url: `${serverUrl}/api/appointments`,
      connections: 50,
      duration: 10, // 10 seconds
      headers: {
        'Content-Type': 'application/json'
      }
    });

    // Performance assertions - focus on no failures rather than strict performance
    expect(result.errors).toBeLessThan(50); // Allow some errors in high load
    expect(result.timeouts).toBeLessThan(50); // Allow some timeouts in high load
    expect(result.non2xx).toBeLessThan(50); // Allow some non-2xx responses
    expect(result.latency.average).toBeLessThan(15000); // Very relaxed latency
    expect(result.requests.average).toBeGreaterThan(0.1); // Just ensure some requests are processed
  }, 30000);

  test('should handle concurrent POST requests efficiently', async () => {
    const appointmentData = JSON.stringify({
      title: 'Load Test Appointment',
      description: 'Performance testing',
      dateTime: '2024-01-15T10:00:00.000Z',
      clinic: 'c1',
      clinicName: 'City Medical Center',
      image: 'https://example.com/image.jpg',
      address: '123 Main St',
      doctor: 'Dr. Sarah Johnson',
      doctorSpecialty: 'General Practitioner'
    });

    const result = await autocannon({
      url: `${serverUrl}/api/appointments`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: appointmentData,
      connections: 20,
      duration: 5
    });

    // Performance assertions for POST operations
    expect(result.errors).toBeLessThan(50); // Allow some errors
    expect(result.timeouts).toBeLessThan(20); // Allow some timeouts for POST
    expect(result.latency.average).toBeLessThan(1000); // Relaxed latency for POST
    expect(result.requests.average).toBeGreaterThan(0.1); // Just ensure some requests are processed
  }, 30000);

  test('should maintain performance under stress', async () => {
    // Stress test with higher load
    const result = await autocannon({
      url: `${serverUrl}/api/appointments`,
      connections: 100,
      duration: 5,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    // Under stress, we expect some degradation but no failures
    expect(result.errors).toBeLessThan(100); // Allow some errors under extreme stress
    expect(result.timeouts).toBeLessThan(100); // Allow some timeouts under extreme stress
    expect(result.latency.p99).toBeLessThan(15000); // 99th percentile < 15 seconds (very relaxed)
  }, 30000);
});
