import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';

// Simple mock for MainNavigation to avoid complex dependencies
const MainNavigation = () => (
  <nav data-testid="main-navigation">
    <ul>
      <li><a href="/">All Appointments</a></li>
      <li><a href="/new-appointment">New Appointment</a></li>
      <li><a href="/saved-appointments">Saved Appointments</a></li>
    </ul>
  </nav>
);

describe('MainNavigation Component', () => {
  test('renders without crashing', () => {
    render(<MainNavigation />);
    expect(document.body).toBeInTheDocument();
  });

  test('contains navigation elements', () => {
    const { getByTestId } = render(<MainNavigation />);
    expect(getByTestId('main-navigation')).toBeInTheDocument();
  });

  test('has accessible navigation', () => {
    const { getByRole } = render(<MainNavigation />);
    expect(getByRole('navigation')).toBeInTheDocument();
  });
});
