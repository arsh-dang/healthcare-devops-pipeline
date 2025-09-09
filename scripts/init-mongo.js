// MongoDB initialization script for Docker
// This script runs when the MongoDB container starts for the first time

db = db.getSiblingDB('healthcare-app');

// Create application user with read/write access
db.createUser({
  user: 'healthcare-user',
  pwd: 'securepassword123',
  roles: [
    {
      role: 'readWrite',
      db: 'healthcare-app'
    }
  ]
});

// Create collections with indexes
db.createCollection('appointments');
db.appointments.createIndex({ "dateTime": 1 });
db.appointments.createIndex({ "clinic": 1 });
db.appointments.createIndex({ "doctor": 1 });

db.createCollection('users');
db.users.createIndex({ "email": 1 }, { unique: true });

db.createCollection('clinics');
db.clinics.createIndex({ "name": 1 });

db.createCollection('doctors');
db.doctors.createIndex({ "name": 1 });
db.doctors.createIndex({ "specialty": 1 });

// Insert sample data for development
db.appointments.insertMany([
  {
    title: "Sample Appointment 1",
    description: "Regular checkup",
    dateTime: new Date("2024-01-15T10:00:00Z"),
    clinic: "Main Clinic",
    clinicName: "Downtown Medical Center",
    image: "clinic1.jpg",
    address: "123 Main St, City, State",
    doctor: "Dr. Smith",
    doctorSpecialty: "General Practice",
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    title: "Sample Appointment 2",
    description: "Cardiology consultation",
    dateTime: new Date("2024-01-20T14:30:00Z"),
    clinic: "Heart Center",
    clinicName: "Cardiac Care Clinic",
    image: "clinic2.jpg",
    address: "456 Health Ave, City, State",
    doctor: "Dr. Johnson",
    doctorSpecialty: "Cardiology",
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

print('Database initialized successfully with sample data');
