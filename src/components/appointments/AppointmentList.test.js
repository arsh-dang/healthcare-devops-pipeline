import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import AppointmentList from './AppointmentList';

describe('AppointmentList', () => {
  const mockAppointments = [
    {
      id: '1',
      patientName: 'John Doe',
      doctorName: 'Dr. Smith',
      clinic: 'General Clinic',
      appointmentDate: '2023-12-25',
      appointmentTime: '10:00'
    },
    {
      id: '2',
      patientName: 'Jane Smith',
      doctorName: 'Dr. Johnson',
      clinic: 'Specialist Clinic',
      appointmentDate: '2023-12-26',
      appointmentTime: '14:30'
    }
  ];

  test('renders appointment list with appointments', () => {
    render(<AppointmentList appointments={mockAppointments} />);
    
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    expect(screen.getByText('Dr. Smith')).toBeInTheDocument();
    expect(screen.getByText('Dr. Johnson')).toBeInTheDocument();
  });

  test('renders empty state when no appointments', () => {
    render(<AppointmentList appointments={[]} />);
    
    expect(screen.getByText(/no appointments/i)).toBeInTheDocument();
  });

  test('displays correct number of appointments', () => {
    render(<AppointmentList appointments={mockAppointments} />);
    
    // Check that both appointments are rendered
    const appointmentItems = screen.getAllByTestId(/appointment-item/i);
    expect(appointmentItems).toHaveLength(2);
  });

  test('handles undefined appointments prop', () => {
    render(<AppointmentList />);
    
    expect(screen.getByText(/no appointments/i)).toBeInTheDocument();
  });
});
