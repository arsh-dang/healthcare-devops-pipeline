import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import AppointmentItem from './AppointmentItem';

describe('AppointmentItem', () => {
  const mockAppointment = {
    id: '1',
    patientName: 'John Doe',
    doctorName: 'Dr. Smith',
    clinic: 'General Clinic',
    appointmentDate: '2023-12-25',
    appointmentTime: '10:00'
  };

  const mockOnToggleFavorite = jest.fn();

  beforeEach(() => {
    mockOnToggleFavorite.mockClear();
  });

  test('renders appointment information correctly', () => {
    render(
      <AppointmentItem 
        appointment={mockAppointment} 
        onToggleFavorite={mockOnToggleFavorite}
        isFavorite={false}
      />
    );
    
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Dr. Smith')).toBeInTheDocument();
    expect(screen.getByText('General Clinic')).toBeInTheDocument();
    expect(screen.getByText('2023-12-25')).toBeInTheDocument();
    expect(screen.getByText('10:00')).toBeInTheDocument();
  });

  test('displays favorite status correctly when favorite', () => {
    render(
      <AppointmentItem 
        appointment={mockAppointment} 
        onToggleFavorite={mockOnToggleFavorite}
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
        onToggleFavorite={mockOnToggleFavorite}
        isFavorite={false}
      />
    );
    
    const favoriteButton = screen.getByRole('button', { name: /add to favorites/i });
    expect(favoriteButton).toBeInTheDocument();
  });

  test('calls onToggleFavorite when favorite button is clicked', () => {
    render(
      <AppointmentItem 
        appointment={mockAppointment} 
        onToggleFavorite={mockOnToggleFavorite}
        isFavorite={false}
      />
    );
    
    const favoriteButton = screen.getByRole('button', { name: /add to favorites/i });
    fireEvent.click(favoriteButton);
    
    expect(mockOnToggleFavorite).toHaveBeenCalledWith('1');
  });

  test('renders with test id for testing', () => {
    render(
      <AppointmentItem 
        appointment={mockAppointment} 
        onToggleFavorite={mockOnToggleFavorite}
        isFavorite={false}
      />
    );
    
    expect(screen.getByTestId('appointment-item-1')).toBeInTheDocument();
  });
});
