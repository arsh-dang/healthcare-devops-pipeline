import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import AppointmentList from './AppointmentList';

describe('AppointmentList', () => {
  const mockAppointments = [
    {
      id: '1',
      title: 'Checkup',
      doctor: 'Dr. Smith',
      clinicName: 'General Clinic',
      dateTime: '2023-12-25 10:00',
      address: '123 Main St',
      description: 'Regular checkup'
    },
    {
      id: '2',
      title: 'Consultation',
      doctor: 'Dr. Johnson',
      clinicName: 'Specialist Clinic',
      dateTime: '2023-12-26 14:30',
      address: '456 Oak Ave',
      description: 'Specialist consultation'
    }
  ];

  test('renders appointment list with appointments', () => {
    render(<AppointmentList appointments={mockAppointments} />);
    
    expect(screen.getByTestId('appointment-item-1')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-item-2')).toBeInTheDocument();
  });

  test('renders empty state when no appointments', () => {
    render(<AppointmentList appointments={[]} />);
    
    expect(screen.getByText(/no appointments found/i)).toBeInTheDocument();
  });

  test('displays correct number of appointments', () => {
    render(<AppointmentList appointments={mockAppointments} />);
    
    // Check that both appointments are rendered
    const appointmentItems = screen.getAllByTestId(/appointment-item/);
    expect(appointmentItems).toHaveLength(2);
  });

  test('handles undefined appointments prop', () => {
    render(<AppointmentList />);
    
    expect(screen.getByText(/no appointments found/i)).toBeInTheDocument();
  });
});
