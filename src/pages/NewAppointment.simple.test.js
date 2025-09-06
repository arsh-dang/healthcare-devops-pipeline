
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

// Mock fetch globally
global.fetch = jest.fn();

// Mock AppointmentForm component
jest.mock('../components/appointments/AppointmentForm', () => {
  function MockAppointmentForm({ onAddAppointment, disabled }) {
    return (
      <div data-testid="appointment-form">
        <button 
          onClick={() => onAddAppointment({ patientName: 'John Doe' })}
          disabled={disabled}
          data-testid="submit-button"
        >
          Submit
        </button>
      </div>
    );
  }  return MockAppointmentForm;
});

const renderWithRouter = () => {
  return render(
    <BrowserRouter>
      <NewAppointmentPage />
    </BrowserRouter>
  );
};

describe('NewAppointmentPage', () => {
  beforeEach(() => {
    fetch.mockClear();
    mockNavigate.mockClear();
  });

  test('renders page title and form', () => {
    renderWithRouter();
    
    expect(screen.getByText('Book New Appointment')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-form')).toBeInTheDocument();
  });

  test('submits appointment successfully', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true })
    });

    renderWithRouter();

    fireEvent.click(screen.getByTestId('submit-button'));

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/');
    });
  });

  test('displays error on submission failure', async () => {
    fetch.mockRejectedValueOnce(new Error('Network error'));

    renderWithRouter();

    fireEvent.click(screen.getByTestId('submit-button'));

    await waitFor(() => {
      expect(screen.getByText('Network error')).toBeInTheDocument();
    });
  });

  test('displays error when response is not ok', async () => {
    fetch.mockResolvedValueOnce({
      ok: false,
      status: 400
    });

    renderWithRouter();

    fireEvent.click(screen.getByTestId('submit-button'));

    await waitFor(() => {
      expect(screen.getByText('Failed to create appointment')).toBeInTheDocument();
    });
  });

  test('disables form while submitting', () => {
    fetch.mockImplementation(() => new Promise(() => {})); // Never resolves

    renderWithRouter();

    fireEvent.click(screen.getByTestId('submit-button'));

    expect(screen.getByTestId('submit-button')).toBeDisabled();
  });

  test('displays fallback error message when error has no message', async () => {
    fetch.mockRejectedValueOnce({}); // Error without message property

    renderWithRouter();

    fireEvent.click(screen.getByTestId('submit-button'));

    await waitFor(() => {
      expect(screen.getByText('Something went wrong')).toBeInTheDocument();
    });
  });
});
