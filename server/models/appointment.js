const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  title: { 
    type: String, 
    required: true 
  },
  description: { 
    type: String, 
    required: true 
  },
  dateTime: { 
    type: String, 
    required: true 
  },
  clinic: { 
    type: String, 
    required: true 
  },
  clinicName: { 
    type: String, 
    required: true 
  },
  image: { 
    type: String, 
    required: true 
  },
  address: { 
    type: String, 
    required: true 
  },
  doctor: { 
    type: String, 
    required: true 
  },
  doctorSpecialty: { 
    type: String, 
    required: true 
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Appointment', appointmentSchema);