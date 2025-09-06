
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import AllAppointmentsPage from './AllAppointments';
import SavedAppointmentsProvider from '../store/saved-appointments-context';

global.fetch = jest.fn();

jest.mock('../components/appointments/AppointmentList', () => {
  function MockAppointmentList({ appointments }) {
    return (
      <div data-testid="appointment-list">
        {appointments.map((appointment) => (
          <div key={appointment.id}>{appointment.patientName}</div>
        ))}
      </div>
    );
  }
  return MockAppointmentList;
});

const renderWithProviders = (component) => {
  return render(
    <BrowserRouter>
      <SavedAppointmentsProvider>
        {component}
      </SavedAppointmentsProvider>
    </BrowserRouter>
  );
};

describe('AllAppointmentsPage', () => {
  beforeEach(() => {
    fetch.mockClear();
  });

  test('renders loading state', () => {
    fetch.mockImplementation(() => new Promise(() => {}));
    
    renderWithProviders(<AllAppointmentsPage />);
    
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  test('fetches appointments successfully', async () => {
    const mockAppointments = [{ _id: '1', patientName: 'John Doe' }];

    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockAppointments
    });

    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByText('Available Appointments')).toBeInTheDocument();
    });

    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });

  test('displays error message', async () => {
    fetch.mockRejectedValueOnce(new Error('Network error'));

    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByText('Error: Network error')).toBeInTheDocument();
    });
  });

  test('displays empty state', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => []
    });

    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByText('No appointments found. Book a new one!')).toBeInTheDocument();
    });
  });
});
