
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import AppointmentItem from './AppointmentItem';

// Mock fetch globally
global.fetch = jest.fn();
global.confirm = jest.fn();
global.alert = jest.fn();

// Mock SavedAppointmentsContext
const mockSavedAppointmentsContext = {
  isAppointmentSaved: jest.fn(),
  saveAppointment: jest.fn(),
  removeAppointment: jest.fn(),
};

jest.mock('react', () => ({
  ...jest.requireActual('react'),
  useContext: () => mockSavedAppointmentsContext,
}));

const mockAppointment = {
  id: '1',
  title: 'Checkup',
  description: 'Regular checkup',
  image: 'test-image.jpg',
  address: '123 Main St',
  doctor: 'Dr. Smith',
  doctorSpecialty: 'General Medicine',
  clinicName: 'General Clinic',
  dateTime: '2024-12-25T10:00:00Z'
};

describe('AppointmentItem', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    fetch.mockClear();
    global.confirm.mockClear();
    global.alert.mockClear();
    mockSavedAppointmentsContext.isAppointmentSaved.mockReturnValue(false);
  });

  test('renders appointment information correctly', () => {
    render(<AppointmentItem {...mockAppointment} />);
    
    expect(screen.getByText('Checkup')).toBeInTheDocument();
    expect(screen.getByText('General Clinic')).toBeInTheDocument();
    expect(screen.getByText('123 Main St')).toBeInTheDocument();
    expect(screen.getByText(/Dr. Smith/)).toBeInTheDocument();
    expect(screen.getByText(/General Medicine/)).toBeInTheDocument();
    expect(screen.getByText('Regular checkup')).toBeInTheDocument();
  });

  test('renders formatted date and time', () => {
    render(<AppointmentItem {...mockAppointment} />);
    
    expect(screen.getByText(/Appointment:/)).toBeInTheDocument();
  });

  test('renders without date and time', () => {
    const appointmentWithoutDateTime = { ...mockAppointment, dateTime: null };
    render(<AppointmentItem {...appointmentWithoutDateTime} />);
    
    expect(screen.queryByText(/Appointment:/)).not.toBeInTheDocument();
  });

  test('displays "Save Appointment" button when not saved', () => {
    mockSavedAppointmentsContext.isAppointmentSaved.mockReturnValue(false);
    render(<AppointmentItem {...mockAppointment} />);
    
    expect(screen.getByText('Save Appointment')).toBeInTheDocument();
  });

  test('displays "Remove from Saved" button when saved', () => {
    mockSavedAppointmentsContext.isAppointmentSaved.mockReturnValue(true);
    render(<AppointmentItem {...mockAppointment} />);
    
    expect(screen.getByText('Remove from Saved')).toBeInTheDocument();
  });

  test('saves appointment when save button is clicked', () => {
    mockSavedAppointmentsContext.isAppointmentSaved.mockReturnValue(false);
    render(<AppointmentItem {...mockAppointment} />);
    
    const saveButton = screen.getByText('Save Appointment');
    fireEvent.click(saveButton);
    
    expect(mockSavedAppointmentsContext.saveAppointment).toHaveBeenCalledWith(mockAppointment);
  });

  test('removes appointment when remove button is clicked', () => {
    mockSavedAppointmentsContext.isAppointmentSaved.mockReturnValue(true);
    render(<AppointmentItem {...mockAppointment} />);
    
    const removeButton = screen.getByText('Remove from Saved');
    fireEvent.click(removeButton);
    
    expect(mockSavedAppointmentsContext.removeAppointment).toHaveBeenCalledWith('1');
  });

  test('shows delete confirmation dialog', () => {
    global.confirm.mockReturnValue(false);
    render(<AppointmentItem {...mockAppointment} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    expect(global.confirm).toHaveBeenCalledWith(
      'Are you sure you want to delete this appointment? This action cannot be undone.'
    );
  });

  test('deletes appointment when confirmed', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true }),
    });
    
    const onDeleteMock = jest.fn();
    render(<AppointmentItem {...mockAppointment} onDelete={onDeleteMock} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(fetch).toHaveBeenCalledWith('/api/appointments/1', {
        method: 'DELETE',
      });
    });
    
    await waitFor(() => {
      expect(onDeleteMock).toHaveBeenCalledWith('1');
    });
  });

  test('shows deleting state during deletion', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockImplementationOnce(() => 
      new Promise(resolve => 
        setTimeout(() => resolve({
          ok: true,
          json: async () => ({ success: true }),
        }), 100)
      )
    );
    
    render(<AppointmentItem {...mockAppointment} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    expect(screen.getByText('Deleting...')).toBeInTheDocument();
  });

  test('handles delete error', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockRejectedValueOnce(new Error('Network error'));
    
    render(<AppointmentItem {...mockAppointment} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(global.alert).toHaveBeenCalledWith('Failed to delete appointment. Please try again.');
    });
  });

  test('handles non-ok delete response', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockResolvedValueOnce({
      ok: false,
      status: 500,
    });
    
    render(<AppointmentItem {...mockAppointment} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(global.alert).toHaveBeenCalledWith('Failed to delete appointment. Please try again.');
    });
  });

  test('removes saved appointment when deleting a saved appointment', async () => {
    global.confirm.mockReturnValue(true);
    mockSavedAppointmentsContext.isAppointmentSaved.mockReturnValue(true);
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true }),
    });
    
    const onDeleteMock = jest.fn();
    render(<AppointmentItem {...mockAppointment} onDelete={onDeleteMock} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(mockSavedAppointmentsContext.removeAppointment).toHaveBeenCalledWith('1');
    });
    
    await waitFor(() => {
      expect(onDeleteMock).toHaveBeenCalledWith('1');
    });
  });

  test('does not delete when confirmation is cancelled', () => {
    global.confirm.mockReturnValue(false);
    render(<AppointmentItem {...mockAppointment} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    expect(fetch).not.toHaveBeenCalled();
  });

  test('disables buttons during deletion', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockImplementationOnce(() => 
      new Promise(resolve => 
        setTimeout(() => resolve({
          ok: true,
          json: async () => ({ success: true }),
        }), 100)
      )
    );
    
    render(<AppointmentItem {...mockAppointment} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    const saveButton = screen.getByText('Save Appointment');
    
    fireEvent.click(deleteButton);
    
    expect(saveButton).toBeDisabled();
    expect(screen.getByText('Deleting...')).toBeDisabled();
  });

  test('renders doctor without specialty', () => {
    const appointmentWithoutSpecialty = { 
      ...mockAppointment, 
      doctorSpecialty: null 
    };
    render(<AppointmentItem {...appointmentWithoutSpecialty} />);
    
    expect(screen.getByText(/Dr. Smith/)).toBeInTheDocument();
    expect(screen.queryByText(/General Medicine/)).not.toBeInTheDocument();
  });

  test('handles invalid date format gracefully', () => {
    const appointmentWithInvalidDate = { 
      ...mockAppointment, 
      dateTime: 'invalid-date' 
    };
    render(<AppointmentItem {...appointmentWithInvalidDate} />);
    
    // Should still render without crashing
    expect(screen.getByText('Checkup')).toBeInTheDocument();
  });

  test('calls onDelete prop when provided', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true }),
    });
    
    const onDeleteMock = jest.fn();
    render(<AppointmentItem {...mockAppointment} onDelete={onDeleteMock} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(onDeleteMock).toHaveBeenCalledWith('1');
    });
  });

  test('works without onDelete prop', async () => {
    global.confirm.mockReturnValue(true);
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true }),
    });
    
    render(<AppointmentItem {...mockAppointment} />);
    
    const deleteButton = screen.getByText('Delete Appointment');
    fireEvent.click(deleteButton);
    
    await waitFor(() => {
      expect(fetch).toHaveBeenCalled();
    });
  });

  test('renders image with correct alt text', () => {
    render(<AppointmentItem {...mockAppointment} />);
    
    const image = screen.getByAltText('General Clinic');
    expect(image).toHaveAttribute('src', 'test-image.jpg');
  });

  test('renders with correct test id', () => {
    render(<AppointmentItem {...mockAppointment} />);
    
    expect(screen.getByTestId('appointment-item-1')).toBeInTheDocument();
  });
});
