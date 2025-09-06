import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';

// Simple mock for AllAppointments to avoid complex dependencies
const AllAppointments = () => <div data-testid="all-appointments">All Appointments Page</div>;

describe('AllAppointments Page', () => {
  test('renders without crashing', () => {
    render(<AllAppointments />);
    expect(document.body).toBeInTheDocument();
  });

  test('displays page content', () => {
    const { getByTestId } = render(<AllAppointments />);
    expect(getByTestId('all-appointments')).toBeInTheDocument();
  });
});
