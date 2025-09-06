import React, { useContext } from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { SavedAppointmentsProvider } from './saved-appointments-context';
import SavedAppointmentsContext from './saved-appointments-context';

// Test component to test the context
function TestComponent() {
  const {
    savedAppointments,
    totalSavedAppointments,
    saveAppointment,
    removeAppointment,
    isAppointmentSaved
  } = useContext(SavedAppointmentsContext);

  const testAppointment = {
    id: '1',
    title: 'Test Appointment',
    description: 'Test Description',
    doctor: 'Dr. Test',
    clinicName: 'Test Clinic',
    dateTime: '2024-12-25T10:00:00'
  };

  return (
    <div>
      <div data-testid="total-count">{totalSavedAppointments}</div>
      <div data-testid="saved-appointments">
        {savedAppointments.map(appointment => (
          <div key={appointment.id} data-testid={`appointment-${appointment.id}`}>
            {appointment.title}
          </div>
        ))}
      </div>
      <button 
        data-testid="save-button" 
        onClick={() => saveAppointment(testAppointment)}
      >
        Save Appointment
      </button>
      <button 
        data-testid="remove-button" 
        onClick={() => removeAppointment('1')}
      >
        Remove Appointment
      </button>
      <div data-testid="is-saved">
        {isAppointmentSaved('1') ? 'Saved' : 'Not Saved'}
      </div>
    </div>
  );
}

// Component to test context default values
function TestContextDefaults() {
  const context = useContext(SavedAppointmentsContext);
  
  return (
    <div>
      <div data-testid="default-saved">{context.savedAppointments.length}</div>
      <div data-testid="default-total">{context.totalSavedAppointments}</div>
      <button onClick={() => context.saveAppointment({})}>Save</button>
      <button onClick={() => context.removeAppointment('test')}>Remove</button>
      <div>{context.isAppointmentSaved('test') ? 'Found' : 'Not Found'}</div>
    </div>
  );
}

describe('SavedAppointmentsContext', () => {
  const renderWithProvider = (component) => {
    return render(
      <SavedAppointmentsProvider>
        {component}
      </SavedAppointmentsProvider>
    );
  };

  test('provides initial empty state', () => {
    renderWithProvider(<TestComponent />);
    
    expect(screen.getByTestId('total-count')).toHaveTextContent('0');
    expect(screen.getByTestId('is-saved')).toHaveTextContent('Not Saved');
  });

  test('context provides default functions when used outside provider', () => {
    // Test context default values by using context without provider
    render(<TestContextDefaults />);
    
    expect(screen.getByTestId('default-saved')).toHaveTextContent('0');
    expect(screen.getByTestId('default-total')).toHaveTextContent('0');
  });

  test('default context functions can be called without errors', () => {
    // Create a component that calls the default context functions
    const TestDefaultFunctions = () => {
      const context = useContext(SavedAppointmentsContext);
      
      const handleCallDefaults = () => {
        // Call all default context functions to achieve 100% coverage
        context.saveAppointment({ id: 'test', title: 'Test' });
        context.removeAppointment('test');
        const isFound = context.isAppointmentSaved('test');
        return isFound;
      };
      
      return (
        <div>
          <div data-testid="default-saved">{context.savedAppointments.length}</div>
          <div data-testid="default-total">{context.totalSavedAppointments}</div>
          <button onClick={handleCallDefaults} data-testid="call-defaults">
            Call Defaults
          </button>
        </div>
      );
    };

    // Render without provider to use default context functions
    render(<TestDefaultFunctions />);
    
    expect(screen.getByTestId('default-saved')).toHaveTextContent('0');
    expect(screen.getByTestId('default-total')).toHaveTextContent('0');
    
    // Call the default functions
    const callButton = screen.getByTestId('call-defaults');
    fireEvent.click(callButton);
    
    // Should still show defaults since these are no-op functions
    expect(screen.getByTestId('default-saved')).toHaveTextContent('0');
    expect(screen.getByTestId('default-total')).toHaveTextContent('0');
  });

  test('saves appointment correctly', () => {
    renderWithProvider(<TestComponent />);
    
    const saveButton = screen.getByTestId('save-button');
    fireEvent.click(saveButton);
    
    expect(screen.getByTestId('total-count')).toHaveTextContent('1');
    expect(screen.getByTestId('appointment-1')).toHaveTextContent('Test Appointment');
    expect(screen.getByTestId('is-saved')).toHaveTextContent('Saved');
  });

  test('removes appointment correctly', () => {
    renderWithProvider(<TestComponent />);
    
    // First save an appointment
    const saveButton = screen.getByTestId('save-button');
    fireEvent.click(saveButton);
    
    expect(screen.getByTestId('total-count')).toHaveTextContent('1');
    expect(screen.getByTestId('is-saved')).toHaveTextContent('Saved');
    
    // Then remove it
    const removeButton = screen.getByTestId('remove-button');
    fireEvent.click(removeButton);
    
    expect(screen.getByTestId('total-count')).toHaveTextContent('0');
    expect(screen.getByTestId('is-saved')).toHaveTextContent('Not Saved');
  });

  test('tracks multiple appointments', () => {
    renderWithProvider(<TestComponent />);
    
    // Save the same appointment multiple times to test array handling
    const saveButton = screen.getByTestId('save-button');
    fireEvent.click(saveButton);
    
    expect(screen.getByTestId('total-count')).toHaveTextContent('1');
    
    // Test that clicking save again on the same appointment doesn't duplicate it
    fireEvent.click(saveButton);
    
    // Should still be 1 since context now prevents duplicates
    expect(screen.getByTestId('total-count')).toHaveTextContent('1');
  });

  test('checks if appointment is saved correctly', () => {
    renderWithProvider(<TestComponent />);
    
    // Initially not saved
    expect(screen.getByTestId('is-saved')).toHaveTextContent('Not Saved');
    
    // Save appointment
    const saveButton = screen.getByTestId('save-button');
    fireEvent.click(saveButton);
    
    // Now should be saved
    expect(screen.getByTestId('is-saved')).toHaveTextContent('Saved');
  });

  test('handles empty appointment removal', () => {
    renderWithProvider(<TestComponent />);
    
    // Try to remove when no appointments exist
    const removeButton = screen.getByTestId('remove-button');
    fireEvent.click(removeButton);
    
    expect(screen.getByTestId('total-count')).toHaveTextContent('0');
    expect(screen.getByTestId('is-saved')).toHaveTextContent('Not Saved');
  });

  test('provider renders children correctly', () => {
    renderWithProvider(
      <div data-testid="child-content">Child Content</div>
    );
    
    expect(screen.getByTestId('child-content')).toHaveTextContent('Child Content');
  });

  test('prevents duplicate appointments when saving the same appointment twice', () => {
    renderWithProvider(<TestComponent />);
    
    const saveButton = screen.getByTestId('save-button');
    
    // Save appointment first time
    fireEvent.click(saveButton);
    expect(screen.getByTestId('total-count')).toHaveTextContent('1');
    
    // Save same appointment again
    fireEvent.click(saveButton);
    expect(screen.getByTestId('total-count')).toHaveTextContent('1'); // Should still be 1
    
    // Verify the existing appointment logic was triggered
    expect(screen.getByTestId('appointment-1')).toBeInTheDocument();
  });

  test('multiple appointments with different IDs', () => {
    const TestComponentMultiple = () => {
      const { savedAppointments, totalSavedAppointments, saveAppointment } = useContext(SavedAppointmentsContext);

      const appointment1 = { id: '1', title: 'Appointment 1' };
      const appointment2 = { id: '2', title: 'Appointment 2' };

      return (
        <div>
          <div data-testid="total-count">{totalSavedAppointments}</div>
          <button onClick={() => saveAppointment(appointment1)} data-testid="save-1">Save 1</button>
          <button onClick={() => saveAppointment(appointment2)} data-testid="save-2">Save 2</button>
          {savedAppointments.map(app => (
            <div key={app.id} data-testid={`appointment-${app.id}`}>{app.title}</div>
          ))}
        </div>
      );
    };

    renderWithProvider(<TestComponentMultiple />);
    
    // Save two different appointments
    fireEvent.click(screen.getByTestId('save-1'));
    fireEvent.click(screen.getByTestId('save-2'));
    
    expect(screen.getByTestId('total-count')).toHaveTextContent('2');
    expect(screen.getByTestId('appointment-1')).toBeInTheDocument();
    expect(screen.getByTestId('appointment-2')).toBeInTheDocument();
  });
});
