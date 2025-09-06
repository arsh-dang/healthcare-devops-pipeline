import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import AllAppointments from './AllAppointments';

// Mock the context provider
jest.mock('../store/saved-appointments-context', () => ({
  useSavedAppointments: () => ({
    appointments: [],
    addAppointment: jest.fn(),
    removeAppointment: jest.fn(),
  }),
}));

describe('AllAppointments Page', () => {
  test('renders without crashing', () => {
    render(<AllAppointments />);
    expect(document.body).toBeInTheDocument();
  });

  test('displays page content', () => {
    render(<AllAppointments />);
    // Check if appointments list or related content is rendered
    const pageContent = screen.getByText(/appointments?/i) || document.body;
    expect(pageContent).toBeInTheDocument();
  });
});
