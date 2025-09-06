import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import AppointmentForm from './AppointmentForm';

// Mock the clinicData
jest.mock('../../utils/clinicData', () => ({
  clinics: [
    { id: 1, name: 'General Clinic', doctors: ['Dr. Smith', 'Dr. Johnson'] },
    { id: 2, name: 'Specialist Clinic', doctors: ['Dr. Brown', 'Dr. Davis'] }
  ]
}));

describe('AppointmentForm', () => {
  const mockOnAddAppointment = jest.fn();

  beforeEach(() => {
    mockOnAddAppointment.mockClear();
  });

  test('renders appointment form with all fields', () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    expect(screen.getByLabelText(/patient name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/clinic/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/doctor/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/date/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/time/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /add appointment/i })).toBeInTheDocument();
  });

  test('updates patient name input', () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    const patientNameInput = screen.getByLabelText(/patient name/i);
    fireEvent.change(patientNameInput, { target: { value: 'John Doe' } });
    
    expect(patientNameInput.value).toBe('John Doe');
  });

  test('updates clinic selection and loads doctors', async () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    const clinicSelect = screen.getByLabelText(/clinic/i);
    fireEvent.change(clinicSelect, { target: { value: '1' } });
    
    expect(clinicSelect.value).toBe('1');
    
    // Wait for doctors to load
    await waitFor(() => {
      expect(screen.getByDisplayValue('Dr. Smith')).toBeInTheDocument();
    });
  });

  test('submits form with valid data', async () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    // Fill out the form
    fireEvent.change(screen.getByLabelText(/patient name/i), { 
      target: { value: 'John Doe' } 
    });
    
    fireEvent.change(screen.getByLabelText(/clinic/i), { 
      target: { value: '1' } 
    });
    
    // Wait for doctors to load and select one
    await waitFor(() => {
      const doctorSelect = screen.getByLabelText(/doctor/i);
      fireEvent.change(doctorSelect, { target: { value: 'Dr. Smith' } });
    });
    
    fireEvent.change(screen.getByLabelText(/date/i), { 
      target: { value: '2023-12-25' } 
    });
    
    fireEvent.change(screen.getByLabelText(/time/i), { 
      target: { value: '10:00' } 
    });
    
    // Submit the form
    fireEvent.click(screen.getByRole('button', { name: /add appointment/i }));
    
    await waitFor(() => {
      expect(mockOnAddAppointment).toHaveBeenCalledWith({
        patientName: 'John Doe',
        clinic: 'General Clinic',
        doctorName: 'Dr. Smith',
        appointmentDate: '2023-12-25',
        appointmentTime: '10:00'
      });
    });
  });

  test('does not submit form with missing required fields', () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    // Submit form without filling required fields
    fireEvent.click(screen.getByRole('button', { name: /add appointment/i }));
    
    expect(mockOnAddAppointment).not.toHaveBeenCalled();
  });

  test('resets form after successful submission', async () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    const patientNameInput = screen.getByLabelText(/patient name/i);
    
    // Fill and submit form
    fireEvent.change(patientNameInput, { target: { value: 'John Doe' } });
    fireEvent.change(screen.getByLabelText(/clinic/i), { target: { value: '1' } });
    
    await waitFor(() => {
      fireEvent.change(screen.getByLabelText(/doctor/i), { target: { value: 'Dr. Smith' } });
    });
    
    fireEvent.change(screen.getByLabelText(/date/i), { target: { value: '2023-12-25' } });
    fireEvent.change(screen.getByLabelText(/time/i), { target: { value: '10:00' } });
    
    fireEvent.click(screen.getByRole('button', { name: /add appointment/i }));
    
    await waitFor(() => {
      expect(patientNameInput.value).toBe('');
    });
  });
});
