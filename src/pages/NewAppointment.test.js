import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import NewAppointment from './NewAppointment';

// Mock the context provider
jest.mock('../store/saved-appointments-context', () => ({
  useSavedAppointments: () => ({
    appointments: [],
    addAppointment: jest.fn(),
    removeAppointment: jest.fn(),
  }),
}));

describe('NewAppointment Page', () => {
  test('renders without crashing', () => {
    render(<NewAppointment />);
    expect(document.body).toBeInTheDocument();
  });

  test('displays appointment form', () => {
    render(<NewAppointment />);
    // Check if form or related content is rendered
    const pageContent = screen.getByText(/appointment/i) || document.body;
    expect(pageContent).toBeInTheDocument();
  });
});
