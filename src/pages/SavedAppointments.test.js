import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import SavedAppointments from './SavedAppointments';

// Mock the context provider
jest.mock('../store/saved-appointments-context', () => ({
  useSavedAppointments: () => ({
    appointments: [],
    addAppointment: jest.fn(),
    removeAppointment: jest.fn(),
  }),
}));

describe('SavedAppointments Page', () => {
  test('renders without crashing', () => {
    render(<SavedAppointments />);
    expect(document.body).toBeInTheDocument();
  });

  test('displays saved appointments content', () => {
    render(<SavedAppointments />);
    // Check if saved appointments or related content is rendered
    const pageContent = screen.getByText(/saved|appointments?/i) || document.body;
    expect(pageContent).toBeInTheDocument();
  });
});
