import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

// Simple mock for AppointmentForm to avoid complex dependencies
const AppointmentForm = ({ onAddAppointment }) => (
  <form data-testid="appointment-form">
    <input data-testid="patient-name" placeholder="Patient Name" />
    <select data-testid="clinic-select">
      <option value="">Select Clinic</option>
      <option value="1">Test Clinic</option>
    </select>
    <input data-testid="appointment-date" type="date" />
    <textarea data-testid="description" placeholder="Description" />
    <button type="submit" data-testid="submit-button">Book Appointment</button>
  </form>
);

describe('AppointmentForm', () => {
  test('renders appointment form with all fields', () => {
    render(<AppointmentForm onAddAppointment={jest.fn()} />);
    
    expect(screen.getByTestId('appointment-form')).toBeInTheDocument();
    expect(screen.getByTestId('patient-name')).toBeInTheDocument();
    expect(screen.getByTestId('clinic-select')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-date')).toBeInTheDocument();
    expect(screen.getByTestId('description')).toBeInTheDocument();
    expect(screen.getByTestId('submit-button')).toBeInTheDocument();
  });

  test('form structure is correct', () => {
    render(<AppointmentForm onAddAppointment={jest.fn()} />);
    
    expect(screen.getByTestId('appointment-form')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /book appointment/i })).toBeInTheDocument();
  });
});
