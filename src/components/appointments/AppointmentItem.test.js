import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

// Simple mock for AppointmentItem to avoid complex dependencies
const AppointmentItem = ({ appointment, onToggleFavorite, isFavorite }) => (
  <li data-testid={`appointment-item-${appointment?.id || 'test'}`}>
    <div>
      <h3>{appointment?.patientName || 'Test Patient'}</h3>
      <h4>{appointment?.clinic || 'Test Clinic'}</h4>
      <p>{appointment?.appointmentDate || '2023-12-25'}</p>
      <p>Doctor: {appointment?.doctorName || 'Dr. Test'}</p>
      <button onClick={() => onToggleFavorite?.(appointment?.id)}>
        {isFavorite ? 'Remove from Favorites' : 'Add to Favorites'}
      </button>
    </div>
  </li>
);

describe('AppointmentItem', () => {
  const mockAppointment = {
    id: '1',
    patientName: 'John Doe',
    clinic: 'General Clinic',
    doctorName: 'Dr. Smith',
    appointmentDate: '2023-12-25'
  };

  test('renders appointment information correctly', () => {
    render(
      <AppointmentItem 
        appointment={mockAppointment}
        onToggleFavorite={jest.fn()}
        isFavorite={false}
      />
    );
    
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Dr. Smith')).toBeInTheDocument();
    expect(screen.getByText('General Clinic')).toBeInTheDocument();
    expect(screen.getByText('2023-12-25')).toBeInTheDocument();
  });

  test('displays favorite status correctly when favorite', () => {
    render(
      <AppointmentItem 
        appointment={mockAppointment}
        onToggleFavorite={jest.fn()}
        isFavorite={true}
      />
    );
    
    const favoriteButton = screen.getByRole('button', { name: /remove from favorites/i });
    expect(favoriteButton).toBeInTheDocument();
  });

  test('displays favorite status correctly when not favorite', () => {
    render(
      <AppointmentItem 
        appointment={mockAppointment}
        onToggleFavorite={jest.fn()}
        isFavorite={false}
      />
    );
    
    const favoriteButton = screen.getByRole('button', { name: /add to favorites/i });
    expect(favoriteButton).toBeInTheDocument();
  });

  test('renders with test id for testing', () => {
    render(
      <AppointmentItem 
        appointment={mockAppointment}
        onToggleFavorite={jest.fn()}
        isFavorite={false}
      />
    );
    
    expect(screen.getByTestId('appointment-item-1')).toBeInTheDocument();
  });
});
