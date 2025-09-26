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

    // Performance assertions
    expect(result.errors).toBe(0);
    expect(result.timeouts).toBe(0);
    expect(result.non2xx).toBe(0);
    expect(result.latency.average).toBeLessThan(100); // Average latency < 100ms
    expect(result.requests.average).toBeGreaterThan(100); // > 100 requests/sec
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
    expect(result.errors).toBe(0);
    expect(result.timeouts).toBe(0);
    expect(result.latency.average).toBeLessThan(200); // Average latency < 200ms for POST
    expect(result.requests.average).toBeGreaterThan(50); // > 50 POST requests/sec
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
    expect(result.errors).toBe(0);
    expect(result.timeouts).toBe(0);
    expect(result.latency.p99).toBeLessThan(1000); // 99th percentile < 1 second
  }, 30000);
});
