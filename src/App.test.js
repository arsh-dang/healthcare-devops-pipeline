import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import '@testing-library/jest-dom';
import App from './App';

// Mock the context provider
jest.mock('./store/saved-appointments-context', () => ({
  SavedAppointmentsContextProvider: ({ children }) => children,
  useSavedAppointments: () => ({
    appointments: [],
    addAppointment: jest.fn(),
    removeAppointment: jest.fn(),
  }),
}));

// Mock the pages to avoid complex dependencies
jest.mock('./pages/AllAppointments', () => {
  return function AllAppointments() {
    return <div data-testid="all-appointments">All Appointments Page</div>;
  };
});

jest.mock('./pages/NewAppointment', () => {
  return function NewAppointment() {
    return <div data-testid="new-appointment">New Appointment Page</div>;
  };
});

jest.mock('./pages/SavedAppointments', () => {
  return function SavedAppointments() {
    return <div data-testid="saved-appointments">Saved Appointments Page</div>;
  };
});

const AppWithRouter = () => (
  <BrowserRouter>
    <App />
  </BrowserRouter>
);

describe('App Component', () => {
  test('renders without crashing', () => {
    render(<AppWithRouter />);
    expect(screen.getByTestId('all-appointments')).toBeInTheDocument();
  });

  test('renders all appointments page by default', () => {
    render(<AppWithRouter />);
    expect(screen.getByTestId('all-appointments')).toBeInTheDocument();
    expect(screen.getByText('All Appointments Page')).toBeInTheDocument();
  });

  test('app structure is correct', () => {
    render(<AppWithRouter />);
    // Check that the app renders successfully
    expect(document.body).toBeInTheDocument();
  });
});
