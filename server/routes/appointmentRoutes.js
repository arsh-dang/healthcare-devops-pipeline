const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');

// GET all appointments
router.get('/', appointmentController.getAppointments);

// POST a new appointment
router.post('/', appointmentController.createAppointment);

// GET a single appointment by id
router.get('/:id', appointmentController.getAppointmentById);

// PUT/UPDATE an appointment
router.put('/:id', appointmentController.updateAppointment);

// DELETE an appointment
router.delete('/:id', appointmentController.deleteAppointment);

module.exports = router;