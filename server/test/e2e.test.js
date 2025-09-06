const request = require('supertest');
const app = require('../server');
const mongoose = require('mongoose');
const Appointment = require('../models/appointment');

// Advanced E2E test suite with database integration
describe('E2E Appointment Workflow Tests', () => {
  let server;
  let appointmentId;

  beforeAll(async () => {
    // Connect to test database
    const mongoUri = process.env.MONGODB_TEST_URI || 'mongodb://localhost:27017/healthcare-test';
    await mongoose.connect(mongoUri);
    
    // Start server
    server = app.listen(0);
  });

  afterAll(async () => {
    // Cleanup
    await mongoose.connection.dropDatabase();
    await mongoose.connection.close();
    if (server) {
      server.close();
    }
  });

  beforeEach(async () => {
    // Clear appointments before each test
    await Appointment.deleteMany({});
  });

  describe('Complete Appointment Booking Flow', () => {
    test('should complete full appointment booking workflow', async () => {
      // Step 1: Check initial empty state
      const initialResponse = await request(app).get('/api/appointments');
      expect(initialResponse.status).toBe(200);
      expect(initialResponse.body).toHaveLength(0);

      // Step 2: Create appointment
      const appointmentData = {
        title: 'Annual Checkup',
        description: 'Routine health examination',
        dateTime: '2024-01-15T10:00:00.000Z',
        clinic: 'c1',
        clinicName: 'City Medical Center',
        image: 'https://example.com/image.jpg',
        address: '123 Main St',
        doctor: 'Dr. Sarah Johnson',
        doctorSpecialty: 'General Practitioner'
      };

      const createResponse = await request(app)
        .post('/api/appointments')
        .send(appointmentData);

      expect(createResponse.status).toBe(201);
      expect(createResponse.body).toMatchObject(appointmentData);
      appointmentId = createResponse.body._id;

      // Step 3: Verify appointment exists
      const getResponse = await request(app).get(`/api/appointments/${appointmentId}`);
      expect(getResponse.status).toBe(200);
      expect(getResponse.body._id).toBe(appointmentId);

      // Step 4: Update appointment
      const updateData = { title: 'Updated Annual Checkup' };
      const updateResponse = await request(app)
        .put(`/api/appointments/${appointmentId}`)
        .send(updateData);

      expect(updateResponse.status).toBe(200);
      expect(updateResponse.body.title).toBe('Updated Annual Checkup');

      // Step 5: List all appointments
      const listResponse = await request(app).get('/api/appointments');
      expect(listResponse.status).toBe(200);
      expect(listResponse.body).toHaveLength(1);

      // Step 6: Delete appointment
      const deleteResponse = await request(app).delete(`/api/appointments/${appointmentId}`);
      expect(deleteResponse.status).toBe(200);

      // Step 7: Verify deletion
      const finalResponse = await request(app).get('/api/appointments');
      expect(finalResponse.status).toBe(200);
      expect(finalResponse.body).toHaveLength(0);
    });

    test('should handle concurrent appointment creation', async () => {
      const appointmentData = {
        title: 'Concurrent Test',
        description: 'Testing concurrent operations',
        dateTime: '2024-01-15T10:00:00.000Z',
        clinic: 'c1',
        clinicName: 'City Medical Center',
        image: 'https://example.com/image.jpg',
        address: '123 Main St',
        doctor: 'Dr. Sarah Johnson',
        doctorSpecialty: 'General Practitioner'
      };

      // Create multiple appointments concurrently
      const promises = Array(5).fill().map((_, index) => 
        request(app)
          .post('/api/appointments')
          .send({
            ...appointmentData,
            title: `Concurrent Appointment ${index + 1}`
          })
      );

      const responses = await Promise.all(promises);
      
      // All should succeed
      responses.forEach(response => {
        expect(response.status).toBe(201);
      });

      // Verify all were created
      const listResponse = await request(app).get('/api/appointments');
      expect(listResponse.status).toBe(200);
      expect(listResponse.body).toHaveLength(5);
    });
  });

  describe('Error Handling and Edge Cases', () => {
    test('should handle invalid appointment data gracefully', async () => {
      const invalidData = {
        title: '', // Invalid empty title
        description: 'Test'
      };

      const response = await request(app)
        .post('/api/appointments')
        .send(invalidData);

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('message');
    });

    test('should handle non-existent appointment operations', async () => {
      const fakeId = new mongoose.Types.ObjectId();

      // Try to get non-existent appointment
      const getResponse = await request(app).get(`/api/appointments/${fakeId}`);
      expect(getResponse.status).toBe(404);

      // Try to update non-existent appointment
      const updateResponse = await request(app)
        .put(`/api/appointments/${fakeId}`)
        .send({ title: 'Updated' });
      expect(updateResponse.status).toBe(404);

      // Try to delete non-existent appointment
      const deleteResponse = await request(app).delete(`/api/appointments/${fakeId}`);
      expect(deleteResponse.status).toBe(404);
    });

    test('should handle database connection issues', async () => {
      // Temporarily close database connection
      await mongoose.connection.close();

      const response = await request(app).get('/api/appointments');
      expect(response.status).toBe(500);

      // Reconnect for other tests
      await mongoose.connect(process.env.MONGODB_TEST_URI || 'mongodb://localhost:27017/healthcare-test');
    });
  });

  describe('Performance and Load Testing', () => {
    test('should handle bulk appointment creation efficiently', async () => {
      const startTime = Date.now();
      
      const bulkData = Array(50).fill().map((_, index) => ({
        title: `Bulk Appointment ${index + 1}`,
        description: 'Performance test appointment',
        dateTime: '2024-01-15T10:00:00.000Z',
        clinic: 'c1',
        clinicName: 'City Medical Center',
        image: 'https://example.com/image.jpg',
        address: '123 Main St',
        doctor: 'Dr. Sarah Johnson',
        doctorSpecialty: 'General Practitioner'
      }));

      // Create appointments in batches
      const batchSize = 10;
      for (let i = 0; i < bulkData.length; i += batchSize) {
        const batch = bulkData.slice(i, i + batchSize);
        const promises = batch.map(data => 
          request(app).post('/api/appointments').send(data)
        );
        await Promise.all(promises);
      }

      const endTime = Date.now();
      const duration = endTime - startTime;

      // Should complete within reasonable time (less than 10 seconds)
      expect(duration).toBeLessThan(10000);

      // Verify all appointments were created
      const listResponse = await request(app).get('/api/appointments');
      expect(listResponse.status).toBe(200);
      expect(listResponse.body).toHaveLength(50);
    });
  });
});
