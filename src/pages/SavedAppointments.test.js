
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import SavedAppointmentsPage from './SavedAppointments';

// Mock the context
const mockSavedAppointmentsContext = {
  savedAppointments: [],
  totalSavedAppointments: 0,
  saveAppointment: jest.fn(),
  removeAppointment: jest.fn(),
  isAppointmentSaved: jest.fn()
};

jest.mock('react', () => ({
  ...jest.requireActual('react'),
  useContext: () => mockSavedAppointmentsContext,
}));

// Mock AppointmentList component
jest.mock('../components/appointments/AppointmentList', () => {
  const mockPropTypes = require('prop-types');
  function MockAppointmentList({ appointments }) {
    return (
      <div data-testid="appointment-list">
        {appointments.map(appointment => (
          <div key={appointment.id} data-testid={`appointment-${appointment.id}`}>
            {appointment.title}
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

describe('SavedAppointmentsPage', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('renders page title', () => {
    render(<SavedAppointmentsPage />);
    
    expect(screen.getByText('My Saved Appointments')).toBeInTheDocument();
  });

  test('shows message when no saved appointments', () => {
    mockSavedAppointmentsContext.totalSavedAppointments = 0;
    mockSavedAppointmentsContext.savedAppointments = [];
    
    render(<SavedAppointmentsPage />);
    
    expect(screen.getByText('You have no saved appointments yet. Book an appointment and save it.')).toBeInTheDocument();
    expect(screen.queryByTestId('appointment-list')).not.toBeInTheDocument();
  });

  test('renders appointment list when saved appointments exist', () => {
    const mockAppointments = [
      {
        id: '1',
        title: 'Checkup',
        doctor: 'Dr. Smith',
        clinicName: 'General Clinic',
        dateTime: '2024-12-25T10:00:00Z'
      },
      {
        id: '2',
        title: 'Consultation',
        doctor: 'Dr. Johnson',
        clinicName: 'Specialist Clinic',
        dateTime: '2024-12-26T14:00:00Z'
      }
    ];

    mockSavedAppointmentsContext.totalSavedAppointments = 2;
    mockSavedAppointmentsContext.savedAppointments = mockAppointments;
    
    render(<SavedAppointmentsPage />);
    
    expect(screen.getByTestId('appointment-list')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-1')).toHaveTextContent('Checkup');
    expect(screen.getByTestId('appointment-2')).toHaveTextContent('Consultation');
    expect(screen.queryByText('You have no saved appointments yet. Book an appointment and save it.')).not.toBeInTheDocument();
  });

  test('renders correctly with single saved appointment', () => {
    const mockAppointments = [
      {
        id: '1',
        title: 'Annual Checkup',
        doctor: 'Dr. Wilson',
        clinicName: 'Health Center',
        dateTime: '2024-12-30T09:00:00Z'
      }
    ];

    mockSavedAppointmentsContext.totalSavedAppointments = 1;
    mockSavedAppointmentsContext.savedAppointments = mockAppointments;
    
    render(<SavedAppointmentsPage />);
    
    expect(screen.getByTestId('appointment-list')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-1')).toHaveTextContent('Annual Checkup');
  });

  test('renders section element', () => {
    render(<SavedAppointmentsPage />);
    
    const heading = screen.getByRole('heading', { level: 1 });
    expect(heading).toBeInTheDocument();
  });

  test('renders h1 heading with correct text', () => {
    render(<SavedAppointmentsPage />);
    
    const heading = screen.getByRole('heading', { level: 1 });
    expect(heading).toHaveTextContent('My Saved Appointments');
  });
});
