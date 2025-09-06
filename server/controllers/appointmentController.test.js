const request = require('supertest');
const express = require('express');
const mongoose = require('mongoose');
const Appointment = require('../models/appointment');
const appointmentController = require('./appointmentController');

// Create Express app for testing
const app = express();
app.use(express.json());

// Setup routes
app.get('/appointments', appointmentController.getAllAppointments);
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
          patientName: 'John Doe',
          doctorName: 'Dr. Smith',
          clinic: 'General Clinic',
          appointmentDate: new Date('2023-12-25'),
          appointmentTime: '10:00'
        }
      ];

      Appointment.find.mockResolvedValue(mockAppointments);

      const response = await request(app).get('/appointments');

      expect(response.status).toBe(200);
      expect(response.body).toEqual(mockAppointments);
      expect(Appointment.find).toHaveBeenCalledWith({});
    });

    test('should handle database errors', async () => {
      Appointment.find.mockRejectedValue(new Error('Database error'));

      const response = await request(app).get('/appointments');

      expect(response.status).toBe(500);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('POST /appointments', () => {
    test('should create a new appointment', async () => {
      const newAppointment = {
        patientName: 'John Doe',
        doctorName: 'Dr. Smith',
        clinic: 'General Clinic',
        appointmentDate: '2023-12-25',
        appointmentTime: '10:00'
      };

      const savedAppointment = {
        _id: 'generated-id',
        ...newAppointment,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      Appointment.prototype.save = jest.fn().mockResolvedValue(savedAppointment);
      Appointment.mockImplementation(() => ({
        save: Appointment.prototype.save
      }));

      const response = await request(app)
        .post('/appointments')
        .send(newAppointment);

      expect(response.status).toBe(201);
      expect(response.body).toEqual(savedAppointment);
    });

    test('should handle validation errors', async () => {
      const invalidAppointment = {
        patientName: '', // Missing required field
        doctorName: 'Dr. Smith'
      };

      const validationError = new Error('Validation failed');
      validationError.name = 'ValidationError';
      Appointment.prototype.save = jest.fn().mockRejectedValue(validationError);
      Appointment.mockImplementation(() => ({
        save: Appointment.prototype.save
      }));

      const response = await request(app)
        .post('/appointments')
        .send(invalidAppointment);

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('GET /appointments/:id', () => {
    test('should return appointment by id', async () => {
      const mockAppointment = {
        _id: '1',
        patientName: 'John Doe',
        doctorName: 'Dr. Smith'
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
      expect(response.body).toHaveProperty('error', 'Appointment not found');
    });
  });

  describe('PUT /appointments/:id', () => {
    test('should update appointment by id', async () => {
      const updateData = {
        patientName: 'John Updated',
        doctorName: 'Dr. Smith'
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
        { new: true, runValidators: true }
      );
    });

    test('should return 404 when updating non-existent appointment', async () => {
      Appointment.findByIdAndUpdate.mockResolvedValue(null);

      const response = await request(app)
        .put('/appointments/nonexistent')
        .send({ patientName: 'Test' });

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error', 'Appointment not found');
    });
  });

  describe('DELETE /appointments/:id', () => {
    test('should delete appointment by id', async () => {
      const deletedAppointment = {
        _id: '1',
        patientName: 'John Doe'
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
      expect(response.body).toHaveProperty('error', 'Appointment not found');
    });
  });
});
