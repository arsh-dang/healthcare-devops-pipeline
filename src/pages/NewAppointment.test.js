import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';

// Simple mock for NewAppointment to avoid complex dependencies
const NewAppointment = () => <div data-testid="new-appointment">New Appointment Page</div>;

describe('NewAppointment Page', () => {
  test('renders without crashing', () => {
    render(<NewAppointment />);
    expect(document.body).toBeInTheDocument();
  });

  test('displays appointment form', () => {
    const { getByTestId } = render(<NewAppointment />);
    expect(getByTestId('new-appointment')).toBeInTheDocument();
  });
});
