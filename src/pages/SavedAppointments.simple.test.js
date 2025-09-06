
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import SavedAppointmentsPage from './SavedAppointments';
import SavedAppointmentsContext from '../store/saved-appointments-context';

// Mock AppointmentList component
jest.mock('../components/appointments/AppointmentList', () => {
  const mockPropTypes = require('prop-types');
  function MockAppointmentList({ appointments }) {
    return (
      <div data-testid="appointment-list">
        {appointments.map((app, index) => (
          <div key={index} data-testid={`appointment-${index}`}>
            {app.doctor} - {app.clinic}
          </div>
        ))}
      </div>
    );
  }
  MockAppointmentList.propTypes = {
    appointments: mockPropTypes.array,
    onDeleteAppointment: mockPropTypes.func
  };
  return MockAppointmentList;
});

const renderWithContext = (contextValue) => {
  const defaultValue = {
    savedAppointments: [],
    totalSavedAppointments: 0,
    addAppointment: jest.fn(),
    removeAppointment: jest.fn(),
    itemIsAdded: jest.fn(() => false)
  };

  return render(
    <SavedAppointmentsContext.Provider value={{ ...defaultValue, ...contextValue }}>
      <SavedAppointmentsPage />
    </SavedAppointmentsContext.Provider>
  );
};

describe('SavedAppointmentsPage', () => {
  test('renders page title', () => {
    renderWithContext({ totalSavedAppointments: 0 });
    
    expect(screen.getByRole('heading', { name: /saved appointments/i })).toBeInTheDocument();
  });

  test('renders appointment list when appointments exist', () => {
    const mockAppointments = [
      { id: '1', doctor: 'Dr. Smith', clinic: 'Main Clinic', date: '2024-01-15', time: '10:00' },
      { id: '2', doctor: 'Dr. Jones', clinic: 'City Clinic', date: '2024-01-16', time: '14:00' }
    ];

    renderWithContext({ 
      totalSavedAppointments: 2,
      savedAppointments: mockAppointments
    });
    
    expect(screen.getByTestId('appointment-list')).toBeInTheDocument();
    expect(screen.getByText('Dr. Smith - Main Clinic')).toBeInTheDocument();
    expect(screen.getByText('Dr. Jones - City Clinic')).toBeInTheDocument();
  });

  test('renders message when no saved appointments', () => {
    renderWithContext({ totalSavedAppointments: 0 });
    
    expect(screen.getByText('You have no saved appointments yet. Book an appointment and save it.')).toBeInTheDocument();
    expect(screen.queryByTestId('appointment-list')).not.toBeInTheDocument();
  });
});
