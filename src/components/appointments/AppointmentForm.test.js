import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import AppointmentForm from './AppointmentForm';

// Mock the Card component
jest.mock('../ui/Card', () => {
  // eslint-disable-next-line react/prop-types
  return function Card({ children }) {
    return <div data-testid="card">{children}</div>;
  };
});

// Mock clinic data
jest.mock('../../utils/clinicData', () => ({
  CLINICS: [
    { id: 'c1', name: 'Downtown Health', address: '123 Main St', image: 'test.jpg' },
    { id: 'c2', name: 'Westside Medical', address: '456 Oak Ave', image: 'test2.jpg' }
  ],
  DOCTORS: {
    'c1': [
      { id: 'd1', name: 'Dr. Smith', specialty: 'General Medicine' },
      { id: 'd2', name: 'Dr. Johnson', specialty: 'Cardiology' }
    ],
    'c2': [
      { id: 'd3', name: 'Dr. Brown', specialty: 'Pediatrics' }
    ]
  }
}));

describe('AppointmentForm', () => {
  const mockOnAddAppointment = jest.fn();

  beforeEach(() => {
    mockOnAddAppointment.mockClear();
  });

  test('renders all form fields correctly', () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    expect(screen.getByLabelText(/appointment type/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/select clinic/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/select doctor/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/date & time/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/notes/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /book appointment/i })).toBeInTheDocument();
  });

  test('updates available doctors when clinic changes', async () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    const clinicSelect = screen.getByLabelText(/select clinic/i);
    
    // Initially shows doctors from first clinic
    expect(screen.getByText('Dr. Smith - General Medicine')).toBeInTheDocument();
    
    // Change to second clinic
    fireEvent.change(clinicSelect, { target: { value: 'c2' } });
    
    await waitFor(() => {
      expect(screen.getByText('Dr. Brown - Pediatrics')).toBeInTheDocument();
    });
  });

  test('submits form with correct data', () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    // Fill out form
    fireEvent.change(screen.getByLabelText(/appointment type/i), { target: { value: 'Annual Check-up' } });
    fireEvent.change(screen.getByLabelText(/date & time/i), { target: { value: '2025-09-15T10:30' } });
    fireEvent.change(screen.getByLabelText(/notes/i), { target: { value: 'Regular checkup visit' } });
    
    // Submit form
    fireEvent.click(screen.getByRole('button', { name: /book appointment/i }));
    
    expect(mockOnAddAppointment).toHaveBeenCalledWith({
      title: 'Annual Check-up',
      description: 'Regular checkup visit',
      dateTime: '2025-09-15T10:30',
      clinic: 'c1',
      clinicName: 'Downtown Health',
      image: 'test.jpg',
      address: '123 Main St',
      doctor: 'Dr. Smith',
      doctorSpecialty: 'General Medicine'
    });
  });

  test('disables form when disabled prop is true', () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} disabled={true} />);
    
    expect(screen.getByLabelText(/appointment type/i)).toBeDisabled();
    expect(screen.getByLabelText(/select clinic/i)).toBeDisabled();
    expect(screen.getByLabelText(/select doctor/i)).toBeDisabled();
    expect(screen.getByLabelText(/date & time/i)).toBeDisabled();
    expect(screen.getByLabelText(/notes/i)).toBeDisabled();
    expect(screen.getByRole('button')).toHaveTextContent('Submitting...');
    expect(screen.getByRole('button')).toBeDisabled();
  });

  test('submits form with empty title and description (current behavior)', () => {
    render(<AppointmentForm onAddAppointment={mockOnAddAppointment} />);
    
    // Submit without filling optional fields (title, description, dateTime are optional in current implementation)
    fireEvent.click(screen.getByRole('button', { name: /book appointment/i }));
    
    // Form should submit with default/empty values
    expect(mockOnAddAppointment).toHaveBeenCalledWith({
      title: '',
      description: '',
      dateTime: '',
      clinic: 'c1',
      clinicName: 'Downtown Health',
      image: 'test.jpg',
      address: '123 Main St',
      doctor: 'Dr. Smith',
      doctorSpecialty: 'General Medicine'
    });
  });
});
