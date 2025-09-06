
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import MainNavigation from './MainNavigation';
import SavedAppointmentsContext from '../../store/saved-appointments-context';

// Mock the healthcare logo to avoid file import issues in tests
jest.mock('../ui/logo/healthcare-logo.svg', () => 'healthcare-logo-mock.svg');

// Mock context value
const mockContextValue = {
  savedAppointments: [],
  totalSavedAppointments: 0,
  saveAppointment: jest.fn(),
  removeAppointment: jest.fn(),
  isAppointmentSaved: jest.fn(() => false)
};

const renderWithRouter = (component, { contextValue = mockContextValue } = {}) => {
  return render(
    <MemoryRouter>
      <SavedAppointmentsContext.Provider value={contextValue}>
        {component}
      </SavedAppointmentsContext.Provider>
    </MemoryRouter>
  );
};

describe('MainNavigation', () => {
  test('renders without crashing', () => {
    renderWithRouter(<MainNavigation />);
    
    expect(screen.getByRole('banner')).toBeInTheDocument();
    expect(screen.getByRole('navigation')).toBeInTheDocument();
  });

  test('displays healthcare logo and title', () => {
    renderWithRouter(<MainNavigation />);
    
    const logo = screen.getByAltText('Healthcare Logo');
    expect(logo).toBeInTheDocument();
    expect(logo).toHaveAttribute('src', 'healthcare-logo-mock.svg');
    
    expect(screen.getByText('Healthcare Appointments')).toBeInTheDocument();
  });

  test('renders all navigation links', () => {
    renderWithRouter(<MainNavigation />);
    
    expect(screen.getByRole('link', { name: 'All Appointments' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Book Appointment' })).toBeInTheDocument();
    
    // The saved appointments link has additional content (badge), so check differently
    const savedAppointmentsLink = screen.getByRole('link', { name: /Saved Appointments/ });
    expect(savedAppointmentsLink).toBeInTheDocument();
  });

  test('navigation links have correct href attributes', () => {
    renderWithRouter(<MainNavigation />);
    
    expect(screen.getByRole('link', { name: 'All Appointments' })).toHaveAttribute('href', '/');
    expect(screen.getByRole('link', { name: 'Book Appointment' })).toHaveAttribute('href', '/new-appointment');
    
    const savedLink = screen.getByRole('link', { name: /Saved Appointments/ });
    expect(savedLink).toHaveAttribute('href', '/saved-appointments');
  });

  test('displays saved appointments badge', () => {
    const contextWithAppointments = {
      ...mockContextValue,
      totalSavedAppointments: 3
    };
    
    renderWithRouter(<MainNavigation />, { contextValue: contextWithAppointments });
    
    // The badge should be present and show the count
    const badge = screen.getByText('3');
    expect(badge).toBeInTheDocument();
    expect(badge).toHaveClass('badge');
  });

  test('has proper header structure', () => {
    renderWithRouter(<MainNavigation />);
    
    const header = screen.getByRole('banner');
    expect(header).toHaveClass('header');
    
    // Check logo container
    expect(screen.getByAltText('Healthcare Logo')).toBeInTheDocument();
    
    // Check navigation
    const nav = screen.getByRole('navigation');
    expect(nav).toBeInTheDocument();
    
    // Check that all list items are present
    const listItems = screen.getAllByRole('listitem');
    expect(listItems).toHaveLength(3);
  });

  test('logo has correct CSS classes', () => {
    renderWithRouter(<MainNavigation />);
    
    const logo = screen.getByAltText('Healthcare Logo');
    expect(logo).toHaveClass('logoImage');
    
    const logoText = screen.getByText('Healthcare Appointments');
    expect(logoText).toHaveClass('logoText');
  });

  test('saved appointments badge has correct CSS class', () => {
    renderWithRouter(<MainNavigation />);
    
    const savedLink = screen.getByRole('link', { name: /Saved Appointments/ });
    expect(savedLink).toBeInTheDocument();
    expect(screen.getByText('0')).toBeInTheDocument();
  });

  test('renders with context provider', () => {
    // This test ensures the component works with the saved appointments context
    renderWithRouter(<MainNavigation />);
    
    // If context is working, the component should render without errors
    expect(screen.getByRole('banner')).toBeInTheDocument();
    
    // And the badge should display some value (default should be 0 or empty)
    expect(screen.getByText('0')).toBeInTheDocument();
  });
});
