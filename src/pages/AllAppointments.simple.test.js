
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import AllAppointmentsPage from './AllAppointments';
import SavedAppointmentsProvider from '../store/saved-appointments-context';

// Mock fetch globally
global.fetch = jest.fn();

// Mock AppointmentList component
jest.mock('../components/appointments/AppointmentList', () => {
  function MockAppointmentList({ appointments }) {
    return (
      <div data-testid="appointment-list">
        {appointments.map((appointment, index) => (
          <div key={index} data-testid={`appointment-${index}`}>
            {appointment.patientName}
          </div>
        ))}
      </div>
    );
  }  return MockAppointmentList;
});

const renderWithProviders = () => {
  return render(
    <BrowserRouter>
      <SavedAppointmentsProvider>
        <AllAppointmentsPage />
      </SavedAppointmentsProvider>
    </BrowserRouter>
  );
};

describe('AllAppointmentsPage', () => {
  beforeEach(() => {
    fetch.mockClear();
  });

  test('renders loading state initially', () => {
    fetch.mockImplementation(() => new Promise(() => {}));
    
    renderWithProviders();
    
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  test('fetches and displays appointments successfully', async () => {
    const mockAppointments = [
      { _id: '1', patientName: 'John Doe' },
      { _id: '2', patientName: 'Jane Smith' }
    ];

    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockAppointments
    });

    renderWithProviders();

    await waitFor(() => {
      expect(screen.getByText('Available Appointments')).toBeInTheDocument();
    });
    
    expect(screen.getByTestId('appointment-list')).toBeInTheDocument();
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Jane Smith')).toBeInTheDocument();
  });

  test('displays no appointments message when empty', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => []
    });

    renderWithProviders();

    await waitFor(() => {
      expect(screen.getByText('No appointments found. Book a new one!')).toBeInTheDocument();
    });
  });
});
