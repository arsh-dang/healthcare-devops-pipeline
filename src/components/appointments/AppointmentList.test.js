
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import AppointmentList from './AppointmentList';

// Mock AppointmentItem to capture function calls
jest.mock('./AppointmentItem', () => {
  const mockPropTypes = require('prop-types');
  function MockAppointmentItem({ onDelete, id, title }) {
    return (
      <div data-testid={`appointment-item-${id}`}>
        <span>{title}</span>
        <button onClick={() => onDelete && onDelete(id)}>Delete</button>
      </div>
    );
  }
  MockAppointmentItem.propTypes = {
    onDelete: mockPropTypes.func,
    id: mockPropTypes.string.isRequired,
    title: mockPropTypes.string.isRequired
  };
  return MockAppointmentItem;
});

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

  test('calls onDeleteAppointment when delete is triggered', () => {
    const mockOnDelete = jest.fn();
    render(<AppointmentList appointments={mockAppointments} onDeleteAppointment={mockOnDelete} />);
    
    // Click delete button on first appointment
    const deleteButton = screen.getAllByText('Delete')[0];
    fireEvent.click(deleteButton);
    
    expect(mockOnDelete).toHaveBeenCalledWith('1');
  });

  test('uses default onDeleteAppointment when none provided', () => {
    // This test ensures the defaultProps.onDeleteAppointment function is used
    render(<AppointmentList appointments={mockAppointments} />);
    
    // Should render without errors even without onDeleteAppointment prop
    expect(screen.getByTestId('appointment-item-1')).toBeInTheDocument();
    
    // Try clicking delete - should not throw error with default function
    const deleteButton = screen.getAllByText('Delete')[0];
    fireEvent.click(deleteButton);
    
    // Should still render (no errors)
    expect(screen.getByTestId('appointment-item-1')).toBeInTheDocument();
  });
});
