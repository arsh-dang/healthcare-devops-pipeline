
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import AppointmentItem from './AppointmentItem';
import { SavedAppointmentsProvider } from '../../store/saved-appointments-context';

// Mock Card component
jest.mock('../ui/Card', () => {
  // eslint-disable-next-line react/prop-types
  return function MockCard({ children }) {
    return <div data-testid="card">{children}</div>;
  };
});

// Mock fetch and window methods
global.fetch = jest.fn();
global.confirm = jest.fn();
global.alert = jest.fn();
const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

const mockProps = {
  id: 'apt-1',
  title: 'Cardiology Consultation',
  description: 'Heart checkup',
  image: '/images/clinic1.jpg',
  address: '123 Health St',
  doctor: 'Dr. Smith',
  doctorSpecialty: 'Cardiology',
  clinicName: 'Downtown Clinic',
  dateTime: '2024-12-25T10:30:00Z'
};

const renderAppointmentItem = (props = {}) => {
  const finalProps = { ...mockProps, ...props };
  return render(
    <SavedAppointmentsProvider>
      <AppointmentItem {...finalProps} />
    </SavedAppointmentsProvider>
  );
};

describe('AppointmentItem Component', () => {
  beforeEach(() => {
    fetch.mockClear();
    global.confirm.mockClear();
    global.alert.mockClear();
    consoleErrorSpy.mockClear();
  });

  afterAll(() => {
    consoleErrorSpy.mockRestore();
  });

  test('renders appointment title and clinic name', () => {
    renderAppointmentItem();
    
    expect(screen.getByText('Cardiology Consultation')).toBeInTheDocument();
    expect(screen.getByText('Downtown Clinic')).toBeInTheDocument();
  });

  test('renders appointment address', () => {
    renderAppointmentItem();
    
    expect(screen.getByText('123 Health St')).toBeInTheDocument();
  });

  test('renders appointment description', () => {
    renderAppointmentItem();
    
    expect(screen.getByText('Heart checkup')).toBeInTheDocument();
  });

  test('renders doctor with specialty', () => {
    renderAppointmentItem();
    
    expect(screen.getByText(/Dr. Smith \(Cardiology\)/)).toBeInTheDocument();
  });

  test('renders doctor without specialty when null', () => {
    renderAppointmentItem({ doctorSpecialty: null });
    
    expect(screen.getByText('Dr. Smith')).toBeInTheDocument();
    expect(screen.queryByText(/\(Cardiology\)/)).not.toBeInTheDocument();
  });

  test('renders formatted appointment date and time', () => {
    renderAppointmentItem();
    
    expect(screen.getByText(/Appointment:/)).toBeInTheDocument();
  });

  test('does not render date when dateTime is empty', () => {
    renderAppointmentItem({ dateTime: '' });
    
    expect(screen.queryByText(/Appointment:/)).not.toBeInTheDocument();
  });

  test('renders save appointment button initially', () => {
    renderAppointmentItem();
    
    expect(screen.getByText('Save Appointment')).toBeInTheDocument();
  });

  test('renders delete appointment button', () => {
    renderAppointmentItem();
    
    expect(screen.getByText('Delete Appointment')).toBeInTheDocument();
  });

  test('toggles to "Remove from Saved" when save button clicked', () => {
    renderAppointmentItem();
    
    const saveButton = screen.getByText('Save Appointment');
    fireEvent.click(saveButton);
    
    expect(screen.getByText('Remove from Saved')).toBeInTheDocument();
    expect(screen.queryByText('Save Appointment')).not.toBeInTheDocument();
  });

  test('toggles back to "Save Appointment" when remove button clicked', () => {
    renderAppointmentItem();
    
    // First save
    const saveButton = screen.getByText('Save Appointment');
    fireEvent.click(saveButton);
    
    // Then remove
    const removeButton = screen.getByText('Remove from Saved');
    fireEvent.click(removeButton);
    
    expect(screen.getByText('Save Appointment')).toBeInTheDocument();
    expect(screen.queryByText('Remove from Saved')).not.toBeInTheDocument();
  });

  test('renders image with correct alt text', () => {
    renderAppointmentItem();
    
    const image = screen.getByRole('img');
    expect(image).toHaveAttribute('src', '/images/clinic1.jpg');
    expect(image).toHaveAttribute('alt', 'Downtown Clinic');
  });

  test('uses title as alt text when clinicName not provided', () => {
    renderAppointmentItem({ clinicName: '' });
    
    const image = screen.getByRole('img');
    expect(image).toHaveAttribute('alt', 'Cardiology Consultation');
  });

  test('renders without description when not provided', () => {
    renderAppointmentItem({ description: '' });
    
    expect(screen.queryByText('Heart checkup')).not.toBeInTheDocument();
  });

  // Delete functionality tests
  test('handles delete confirmation cancellation', () => {
    global.global.confirm.mockReturnValue(false);
    
    renderAppointmentItem();
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    expect(global.confirm).toHaveBeenCalledWith("Are you sure you want to delete this appointment? This action cannot be undone.");
    expect(fetch).not.toHaveBeenCalled();
  });

  test('handles successful delete operation', async () => {
    const onDeleteMock = jest.fn();
    global.confirm.mockReturnValue(true);
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true })
    });
    
    renderAppointmentItem({ onDelete: onDeleteMock });
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    expect(global.confirm).toHaveBeenCalled();
    expect(fetch).toHaveBeenCalledWith('http://127.0.0.1:5001/api/appointments/apt-1', {
      method: 'DELETE'
    });
    
    await waitFor(() => {
      expect(onDeleteMock).toHaveBeenCalledWith('apt-1');
    });
  });

  test('shows deleting state during delete operation', async () => {
    global.confirm.mockReturnValue(true);
    let resolvePromise;
    fetch.mockImplementationOnce(() => new Promise(resolve => {
      resolvePromise = resolve;
    }));
    
    renderAppointmentItem();
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    expect(screen.getByText('Deleting...')).toBeInTheDocument();
    expect(deleteButton).toBeDisabled();
    
    // Resolve the promise
    resolvePromise({ ok: true, json: async () => ({ success: true }) });
    
    await waitFor(() => {
      expect(screen.getByText('Delete Appointment')).toBeInTheDocument();
    });
  });

  test('handles delete operation failure', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockRejectedValueOnce(new Error('Network error'));
    
    renderAppointmentItem();
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(consoleErrorSpy).toHaveBeenCalledWith('Error deleting appointment:', expect.any(Error));
    });
    
    await waitFor(() => {
      expect(global.alert).toHaveBeenCalledWith('Failed to delete appointment. Please try again.');
    });
    
    expect(screen.getByText('Delete Appointment')).toBeInTheDocument();
  });

  test('handles delete operation with non-ok response', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockResolvedValueOnce({
      ok: false,
      status: 404
    });
    
    renderAppointmentItem();
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(consoleErrorSpy).toHaveBeenCalledWith('Error deleting appointment:', expect.any(Error));
    });
    
    await waitFor(() => {
      expect(global.alert).toHaveBeenCalledWith('Failed to delete appointment. Please try again.');
    });
  });

  test('removes from saved appointments when deleting saved appointment', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true })
    });
    
    renderAppointmentItem();
    
    // First save the appointment
    const saveButton = screen.getByText('Save Appointment');
    fireEvent.click(saveButton);
    
    // Then delete it
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(fetch).toHaveBeenCalledWith('http://127.0.0.1:5001/api/appointments/apt-1', {
        method: 'DELETE'
      });
    });
  });

  test('disables save button during delete operation', async () => {
    global.confirm.mockReturnValue(true);
    let resolvePromise;
    fetch.mockImplementationOnce(() => new Promise(resolve => {
      resolvePromise = resolve;
    }));
    
    renderAppointmentItem();
    
    const deleteButton = screen.getByText('Delete Appointment');
    const saveButton = screen.getByText('Save Appointment');
    
    fireEvent.click(deleteButton);
    
    expect(saveButton).toBeDisabled();
    
    // Resolve the promise
    resolvePromise({ ok: true, json: async () => ({ success: true }) });
    
    await waitFor(() => {
      expect(saveButton).not.toBeDisabled();
    });
  });
});
