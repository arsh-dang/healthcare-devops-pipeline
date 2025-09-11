
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import NewAppointmentPage from './NewAppointment';

// Mock useNavigate hook
const mockNavigate = jest.fn();
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate
}));

// Mock the AppointmentForm component
jest.mock('../components/appointments/AppointmentForm', () => {
  // eslint-disable-next-line react/prop-types
  return function MockAppointmentForm({ onAddAppointment, disabled }) {
    return (
      <div data-testid="appointment-form">
        <button 
          onClick={() => onAddAppointment({
            patientName: 'John Doe',
            doctorName: 'Dr. Smith',
            date: '2024-01-15',
            time: '10:00'
          })}
          disabled={disabled}
          data-testid="submit-form"
        >
          {disabled ? 'Submitting...' : 'Book Appointment'}
        </button>
        <div data-testid="form-disabled">{disabled ? 'disabled' : 'enabled'}</div>
      </div>
    );
  };
});

// Mock fetch globally
global.fetch = jest.fn();

const renderWithRouter = (component) => {
  return render(
    <BrowserRouter>
      {component}
    </BrowserRouter>
  );
};

describe('NewAppointmentPage', () => {
  beforeEach(() => {
    fetch.mockClear();
    mockNavigate.mockClear();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('renders the page with title and form', () => {
    renderWithRouter(<NewAppointmentPage />);
    
    expect(screen.getByText('Book New Appointment')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-form')).toBeInTheDocument();
    expect(screen.queryByText('Submitting appointment data...')).not.toBeInTheDocument();
    expect(screen.queryByText(/error/i)).not.toBeInTheDocument();
  });

  test('submits appointment data successfully and navigates home', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true, id: '123' })
    });

    renderWithRouter(<NewAppointmentPage />);

    fireEvent.click(screen.getByTestId('submit-form'));

    // Check that form is disabled during submission
    await waitFor(() => {
      expect(screen.getByText('disabled')).toBeInTheDocument();
    });

    // Wait for navigation to occur
    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/');
    });

    expect(fetch).toHaveBeenCalledWith('http://127.0.0.1:5001/api/appointments', {
      method: 'POST',
      body: JSON.stringify({
        patientName: 'John Doe',
        doctorName: 'Dr. Smith',
        date: '2024-01-15',
        time: '10:00'
      }),
      headers: {
        'Content-Type': 'application/json'
      }
    });
  });

  test('displays error message when submission fails due to network error', async () => {
    fetch.mockRejectedValueOnce(new Error('Network error'));

    renderWithRouter(<NewAppointmentPage />);

    fireEvent.click(screen.getByTestId('submit-form'));

    await waitFor(() => {
      expect(screen.getByText('Network error')).toBeInTheDocument();
    });

    expect(screen.getByText('enabled')).toBeInTheDocument(); // Form should be re-enabled
    expect(screen.queryByText('Submitting appointment data...')).not.toBeInTheDocument();
    expect(mockNavigate).not.toHaveBeenCalled();
  });

  test('displays error message when response is not ok', async () => {
    fetch.mockResolvedValueOnce({
      ok: false,
      json: async () => ({ error: 'Server error' })
    });

    renderWithRouter(<NewAppointmentPage />);

    fireEvent.click(screen.getByTestId('submit-form'));

    await waitFor(() => {
      expect(screen.getByText('Failed to create appointment')).toBeInTheDocument();
    });

    expect(screen.getByText('enabled')).toBeInTheDocument(); // Form should be re-enabled
    expect(screen.queryByText('Submitting appointment data...')).not.toBeInTheDocument();
    expect(mockNavigate).not.toHaveBeenCalled();
  });

  test('displays generic error message when error has no message', async () => {
    fetch.mockRejectedValueOnce({});

    renderWithRouter(<NewAppointmentPage />);

    fireEvent.click(screen.getByTestId('submit-form'));

    await waitFor(() => {
      expect(screen.getByText('Something went wrong')).toBeInTheDocument();
    });

    expect(screen.getByText('enabled')).toBeInTheDocument();
    expect(mockNavigate).not.toHaveBeenCalled();
  });

  test('resets error state when submitting again after previous error', async () => {
    // First submission fails
    fetch.mockRejectedValueOnce(new Error('Network error'));

    renderWithRouter(<NewAppointmentPage />);

    fireEvent.click(screen.getByTestId('submit-form'));

    await waitFor(() => {
      expect(screen.getByText('Network error')).toBeInTheDocument();
    });

    // Second submission succeeds
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true })
    });

    fireEvent.click(screen.getByTestId('submit-form'));

    // Error should be cleared
    expect(screen.queryByText('Network error')).not.toBeInTheDocument();
    
    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/');
    });
  });

  test('sets isSubmitting state correctly during submission', async () => {
    let resolvePromise;
    fetch.mockImplementation(() => new Promise((resolve) => {
      resolvePromise = resolve;
    }));

    renderWithRouter(<NewAppointmentPage />);

    fireEvent.click(screen.getByTestId('submit-form'));

    // Should show submitting state
    expect(screen.getByText('disabled')).toBeInTheDocument();
    expect(screen.getByText('Submitting appointment data...')).toBeInTheDocument();

    // Resolve the promise
    resolvePromise({
      ok: true,
      json: async () => ({ success: true })
    });

    await waitFor(() => {
      expect(screen.getByText('enabled')).toBeInTheDocument();
    });

    expect(screen.queryByText('Submitting appointment data...')).not.toBeInTheDocument();
  });

  test('passes correct props to AppointmentForm', () => {
    renderWithRouter(<NewAppointmentPage />);
    
    expect(screen.getByText('enabled')).toBeInTheDocument(); // disabled=false initially
    expect(screen.getByTestId('appointment-form')).toBeInTheDocument();
  });

  test('handles multiple rapid submissions correctly', async () => {
    fetch.mockResolvedValue({
      ok: true,
      json: async () => ({ success: true })
    });

    renderWithRouter(<NewAppointmentPage />);

    // Click submit multiple times rapidly
    fireEvent.click(screen.getByTestId('submit-form'));
    fireEvent.click(screen.getByTestId('submit-form'));
    fireEvent.click(screen.getByTestId('submit-form'));

    // Should only navigate once
    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/');
    });

    expect(mockNavigate).toHaveBeenCalledTimes(1);
  });
});
