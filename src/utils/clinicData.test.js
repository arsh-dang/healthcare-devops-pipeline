import { CLINICS, DOCTORS, getClinicById, getDoctorById, getAllDoctors } from './clinicData';

describe('clinicData', () => {
  describe('CLINICS constant', () => {
    test('exports clinic data array', () => {
      expect(Array.isArray(CLINICS)).toBe(true);
      expect(CLINICS.length).toBeGreaterThan(0);
    });

    test('each clinic has required properties', () => {
      CLINICS.forEach(clinic => {
        expect(clinic).toHaveProperty('id');
        expect(clinic).toHaveProperty('name');
        expect(clinic).toHaveProperty('address');
        expect(clinic).toHaveProperty('image');
        expect(clinic).toHaveProperty('specialty');
      });
    });

    test('contains expected clinics', () => {
      const clinicIds = CLINICS.map(clinic => clinic.id);
      expect(clinicIds).toContain('c1');
      expect(clinicIds).toContain('c2');
      expect(clinicIds).toContain('c3');
    });
  });

  describe('DOCTORS constant', () => {
    test('exports doctors data object', () => {
      expect(typeof DOCTORS).toBe('object');
      expect(DOCTORS).not.toBeNull();
    });

    test('has doctors for each clinic', () => {
      expect(DOCTORS).toHaveProperty('c1');
      expect(DOCTORS).toHaveProperty('c2');
      expect(DOCTORS).toHaveProperty('c3');
      
      expect(Array.isArray(DOCTORS.c1)).toBe(true);
      expect(Array.isArray(DOCTORS.c2)).toBe(true);
      expect(Array.isArray(DOCTORS.c3)).toBe(true);
    });

    test('each doctor has required properties', () => {
      Object.values(DOCTORS).forEach(clinicDoctors => {
        clinicDoctors.forEach(doctor => {
          expect(doctor).toHaveProperty('id');
          expect(doctor).toHaveProperty('name');
          expect(doctor).toHaveProperty('specialty');
        });
      });
    });
  });

  describe('getClinicById', () => {
    test('returns clinic for valid ID', () => {
      const clinic = getClinicById('c1');
      expect(clinic).toBeDefined();
      expect(clinic.id).toBe('c1');
      expect(clinic.name).toBe('City Medical Center');
    });

    test('returns clinic for another valid ID', () => {
      const clinic = getClinicById('c2');
      expect(clinic).toBeDefined();
      expect(clinic.id).toBe('c2');
      expect(clinic.name).toBe('Westside Health Clinic');
    });

    test('returns undefined for invalid ID', () => {
      const clinic = getClinicById('invalid');
      expect(clinic).toBeUndefined();
    });

    test('returns undefined for null ID', () => {
      const clinic = getClinicById(null);
      expect(clinic).toBeUndefined();
    });
  });

  describe('getDoctorById', () => {
    test('returns doctor for valid ID', () => {
      const doctor = getDoctorById('d1');
      expect(doctor).toBeDefined();
      expect(doctor.id).toBe('d1');
      expect(doctor.name).toBe('Dr. Sarah Johnson');
    });

    test('returns doctor from different clinic', () => {
      const doctor = getDoctorById('d3');
      expect(doctor).toBeDefined();
      expect(doctor.id).toBe('d3');
      expect(doctor.name).toBe('Dr. Amanda Wilson');
    });

    test('returns null for invalid ID', () => {
      const doctor = getDoctorById('invalid');
      expect(doctor).toBeNull();
    });

    test('returns null for null ID', () => {
      const doctor = getDoctorById(null);
      expect(doctor).toBeNull();
    });
  });

  describe('getAllDoctors', () => {
    test('returns array of all doctors', () => {
      const allDoctors = getAllDoctors();
      expect(Array.isArray(allDoctors)).toBe(true);
      expect(allDoctors.length).toBeGreaterThan(0);
    });

    test('includes doctors from all clinics', () => {
      const allDoctors = getAllDoctors();
      const doctorIds = allDoctors.map(doctor => doctor.id);
      
      expect(doctorIds).toContain('d1');
      expect(doctorIds).toContain('d2');
      expect(doctorIds).toContain('d3');
      expect(doctorIds).toContain('d4');
      expect(doctorIds).toContain('d5');
      expect(doctorIds).toContain('d6');
    });

    test('each doctor has correct structure', () => {
      const allDoctors = getAllDoctors();
      allDoctors.forEach(doctor => {
        expect(doctor).toHaveProperty('id');
        expect(doctor).toHaveProperty('name');
        expect(doctor).toHaveProperty('specialty');
      });
    });

    test('returns consistent data on multiple calls', () => {
      const doctors1 = getAllDoctors();
      const doctors2 = getAllDoctors();
      expect(doctors1).toEqual(doctors2);
    });
  });
});
