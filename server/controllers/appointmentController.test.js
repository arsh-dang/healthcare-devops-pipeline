const request = require('supertest');
const express = require('express');
const mongoose = require('mongoose');
const Appointment = require('../models/appointment');
const appointmentController = require('./appointmentController');

// Create Express app for testing
const app = express();
app.use(express.json());

// Setup routes with correct function names
app.get('/appointments', appointmentController.getAppointments);
app.post('/appointments', appointmentController.createAppointment);
app.get('/appointments/:id', appointmentController.getAppointmentById);
app.put('/appointments/:id', appointmentController.updateAppointment);
app.delete('/appointments/:id', appointmentController.deleteAppointment);

// Mock the Appointment model
jest.mock('../models/appointment');

describe('Appointment Controller', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /appointments', () => {
    test('should return all appointments', async () => {
      const mockAppointments = [
        {
          _id: '1',
          title: 'Checkup',
          description: 'Regular checkup',
          dateTime: new Date('2023-12-25T10:00:00'),
          doctor: 'Dr. Smith',
          clinicName: 'General Clinic'
        }
      ];

      Appointment.find.mockResolvedValue(mockAppointments);

      const response = await request(app).get('/appointments');

      expect(response.status).toBe(200);
      expect(response.body).toEqual(mockAppointments);
      expect(Appointment.find).toHaveBeenCalledWith();
    });

    test('should handle database errors', async () => {
      Appointment.find.mockRejectedValue(new Error('Database error'));

      const response = await request(app).get('/appointments');

      expect(response.status).toBe(500);
      expect(response.body).toHaveProperty('message');
    });
  });

  describe('POST /appointments', () => {
    test('should create a new appointment', async () => {
      const newAppointment = {
        title: 'Checkup',
        description: 'Regular checkup',
        dateTime: '2023-12-25T10:00:00',
        doctor: 'Dr. Smith',
        clinicName: 'General Clinic'
      };

      const savedAppointment = {
        _id: 'generated-id',
        ...newAppointment,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      const mockSave = jest.fn().mockResolvedValue(savedAppointment);
      Appointment.mockImplementation(() => ({
        save: mockSave
      }));

      const response = await request(app)
        .post('/appointments')
        .send(newAppointment);

      expect(response.status).toBe(201);
      expect(response.body).toEqual(savedAppointment);
      expect(mockSave).toHaveBeenCalled();
    });

    test('should handle validation errors', async () => {
      const invalidAppointment = {
        title: '', // Missing required field
        description: 'Test'
      };

      const validationError = new Error('Validation failed');
      validationError.name = 'ValidationError';
      
      const mockSave = jest.fn().mockRejectedValue(validationError);
      Appointment.mockImplementation(() => ({
        save: mockSave
      }));

      const response = await request(app)
        .post('/appointments')
        .send(invalidAppointment);

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('message');
    });
  });

  describe('GET /appointments/:id', () => {
    test('should return appointment by id', async () => {
      const mockAppointment = {
        _id: '1',
        title: 'Checkup',
        description: 'Regular checkup',
        doctor: 'Dr. Smith'
      };

      Appointment.findById.mockResolvedValue(mockAppointment);

      const response = await request(app).get('/appointments/1');

      expect(response.status).toBe(200);
      expect(response.body).toEqual(mockAppointment);
      expect(Appointment.findById).toHaveBeenCalledWith('1');
    });

    test('should return 404 for non-existent appointment', async () => {
      Appointment.findById.mockResolvedValue(null);

      const response = await request(app).get('/appointments/nonexistent');

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('message', 'Appointment not found');
    });
  });

  describe('PUT /appointments/:id', () => {
    test('should update appointment by id', async () => {
      const updateData = {
        title: 'Updated Checkup',
        doctor: 'Dr. Smith'
      };

      const updatedAppointment = {
        _id: '1',
        ...updateData
      };

      Appointment.findByIdAndUpdate.mockResolvedValue(updatedAppointment);

      const response = await request(app)
        .put('/appointments/1')
        .send(updateData);

      expect(response.status).toBe(200);
      expect(response.body).toEqual(updatedAppointment);
      expect(Appointment.findByIdAndUpdate).toHaveBeenCalledWith(
        '1',
        updateData,
        { new: true }
      );
    });

    test('should return 404 when updating non-existent appointment', async () => {
      Appointment.findByIdAndUpdate.mockResolvedValue(null);

      const response = await request(app)
        .put('/appointments/nonexistent')
        .send({ title: 'Test' });

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('message', 'Appointment not found');
    });
  });

  describe('DELETE /appointments/:id', () => {
    test('should delete appointment by id', async () => {
      const deletedAppointment = {
        _id: '1',
        title: 'Checkup'
      };

      Appointment.findByIdAndDelete.mockResolvedValue(deletedAppointment);

      const response = await request(app).delete('/appointments/1');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Appointment deleted successfully');
      expect(Appointment.findByIdAndDelete).toHaveBeenCalledWith('1');
    });

    test('should return 404 when deleting non-existent appointment', async () => {
      Appointment.findByIdAndDelete.mockResolvedValue(null);

      const response = await request(app).delete('/appointments/nonexistent');

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('message', 'Appointment not found');
    });
  });
});
