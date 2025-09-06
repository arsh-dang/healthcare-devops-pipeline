// Centralized clinic and doctor data for healthcare booking system

export const CLINICS = [
  { 
    id: 'c1', 
    name: 'City Medical Center', 
    address: '123 Main St, Downtown', 
    image: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=500&auto=format&fit=crop',
    specialty: 'General Medicine & Pediatrics' 
  },
  { 
    id: 'c2', 
    name: 'Westside Health Clinic', 
    address: '456 Park Ave, Westside', 
    image: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?q=80&w=500&auto=format&fit=crop',
    specialty: 'Cardiology & Dermatology'
  },
  { 
    id: 'c3', 
    name: 'Riverside Hospital', 
    address: '789 River Rd, Riverside', 
    image: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?q=80&w=500&auto=format&fit=crop',
    specialty: 'Neurology & Orthopedics'
  }
];

// Predefined doctors for each clinic
export const DOCTORS = {
  'c1': [
    { id: 'd1', name: 'Dr. Sarah Johnson', specialty: 'General Practitioner' },
    { id: 'd2', name: 'Dr. Michael Chen', specialty: 'Pediatrician' }
  ],
  'c2': [
    { id: 'd3', name: 'Dr. Amanda Wilson', specialty: 'Cardiologist' },
    { id: 'd4', name: 'Dr. Robert Garcia', specialty: 'Dermatologist' }
  ],
  'c3': [
    { id: 'd5', name: 'Dr. Emily Patel', specialty: 'Neurologist' },
    { id: 'd6', name: 'Dr. James Williams', specialty: 'Orthopedist' }
  ]
};

// Helper function to get clinic by ID
export const getClinicById = (clinicId) => {
  return CLINICS.find(clinic => clinic.id === clinicId);
};

// Helper function to get doctor by ID
export const getDoctorById = (doctorId) => {
  for (const clinicId in DOCTORS) {
    const doctor = DOCTORS[clinicId].find(doc => doc.id === doctorId);
    if (doctor) return doctor;
  }
  return null;
};

// Helper function to get all doctors
export const getAllDoctors = () => {
  let allDoctors = [];
  for (const clinicId in DOCTORS) {
    allDoctors = [...allDoctors, ...DOCTORS[clinicId]];
  }
  return allDoctors;
};