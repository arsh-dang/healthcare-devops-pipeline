import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import AllAppointmentsPage from './AllAppointments';
import { SavedAppointmentsProvider } from '../store/saved-appointments-context';

// Mock AppointmentList component
jest.mock('../components/appointments/AppointmentList', () => {
  return function MockAppointmentList({ appointments, onDeleteAppointment }) {
    return (
      <div data-testid="appointment-list">
        {appointments.map((appointment) => (
          <div key={appointment.id} data-testid={`appointment-${appointment.id}`}>
            <span>{appointment.title}</span>
            <button onClick={() => onDeleteAppointment(appointment.id)}>Delete</button>
          </div>
        ))}
      </div>
    );
  };
});

// Mock console.error to avoid error logs in tests
const originalConsoleError = console.error;
beforeAll(() => {
  console.error = jest.fn();
});

afterAll(() => {
  console.error = originalConsoleError;
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
    global.fetch = jest.fn();
    jest.clearAllMocks();
  });

  afterEach(() => {
    global.fetch.mockRestore();
  });

  test('displays loading state initially', () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve([])
    });

    renderWithProviders(<AllAppointmentsPage />);
    
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  test('displays appointments when loaded successfully', async () => {
    const mockAppointments = [
      { _id: '1', title: 'Doctor Visit', date: '2024-01-15', time: '10:00' },
      { _id: '2', title: 'Dentist Check', date: '2024-01-16', time: '14:30' }
    ];

    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(mockAppointments)
    });

    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByText('Available Appointments')).toBeInTheDocument();
    });

    expect(screen.getByTestId('appointment-list')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-1')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-2')).toBeInTheDocument();
  });

  test('displays "no appointments found" message when empty array returned', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve([])
    });

    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByText('Available Appointments')).toBeInTheDocument();
    });

    expect(screen.getByText('No appointments found. Book a new one!')).toBeInTheDocument();
  });

  test('handles network error (response not ok)', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: false,
      status: 500
    });

    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByText(/Error:/)).toBeInTheDocument();
    });

    expect(screen.getByText('Error: Network response was not ok')).toBeInTheDocument();
    expect(screen.getByText('Try Again')).toBeInTheDocument();
  });

  test('handles fetch rejection error', async () => {
    const errorMessage = 'Failed to fetch';
    global.fetch.mockRejectedValueOnce(new Error(errorMessage));

    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByText(/Error:/)).toBeInTheDocument();
    });

    expect(screen.getByText(`Error: ${errorMessage}`)).toBeInTheDocument();
    expect(screen.getByText('Try Again')).toBeInTheDocument();
    expect(console.error).toHaveBeenCalledWith('Error fetching appointments:', expect.any(Error));
  });

  test('retry functionality works after error', async () => {
    // First call fails
    global.fetch.mockRejectedValueOnce(new Error('Network error'));
    
    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByText('Error: Network error')).toBeInTheDocument();
    });

    // Second call succeeds
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve([
        { _id: '1', title: 'Doctor Visit', date: '2024-01-15', time: '10:00' }
      ])
    });

    const tryAgainButton = screen.getByText('Try Again');
    fireEvent.click(tryAgainButton);

    await waitFor(() => {
      expect(screen.getByText('Available Appointments')).toBeInTheDocument();
    });

    expect(screen.getByTestId('appointment-1')).toBeInTheDocument();
  });

  test('handles appointment deletion', async () => {
    const mockAppointments = [
      { _id: '1', title: 'Doctor Visit', date: '2024-01-15', time: '10:00' },
      { _id: '2', title: 'Dentist Check', date: '2024-01-16', time: '14:30' }
    ];

    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(mockAppointments)
    });

    renderWithProviders(<AllAppointmentsPage />);

    await waitFor(() => {
      expect(screen.getByTestId('appointment-1')).toBeInTheDocument();
    });

    // Delete the first appointment
    const deleteButton = screen.getAllByText('Delete')[0];
    fireEvent.click(deleteButton);

    // First appointment should be removed
    expect(screen.queryByTestId('appointment-1')).not.toBeInTheDocument();
    expect(screen.getByTestId('appointment-2')).toBeInTheDocument();
  });
});
