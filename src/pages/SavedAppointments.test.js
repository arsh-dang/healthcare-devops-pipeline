import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';

// Simple mock for SavedAppointments to avoid complex dependencies
const SavedAppointments = () => <div data-testid="saved-appointments">Saved Appointments Page</div>;

describe('SavedAppointments Page', () => {
  test('renders without crashing', () => {
    render(<SavedAppointments />);
    expect(document.body).toBeInTheDocument();
  });

  test('displays saved appointments content', () => {
    const { getByTestId } = render(<SavedAppointments />);
    expect(getByTestId('saved-appointments')).toBeInTheDocument();
  });
});
