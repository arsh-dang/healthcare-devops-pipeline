import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import MainNavigation from './MainNavigation';
import SavedAppointmentsContextProvider from '../../store/saved-appointments-context';

// Mock the healthcare logo to avoid file import issues in tests
jest.mock('../ui/logo/healthcare-logo.svg', () => 'healthcare-logo-mock.svg');

const renderWithRouter = (component, { initialState = null } = {}) => {
  if (initialState) {
    // If we need to test with specific context state, we'd create a custom provider
    return render(
      <MemoryRouter>
        <SavedAppointmentsContextProvider>
          {component}
        </SavedAppointmentsContextProvider>
      </MemoryRouter>
    );
  }
  
  return render(
    <MemoryRouter>
      <SavedAppointmentsContextProvider>
        {component}
      </SavedAppointmentsContextProvider>
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
    renderWithRouter(<MainNavigation />);
    
    // The badge should be present (even if count is 0)
    const badge = document.querySelector('.badge');
    expect(badge).toBeInTheDocument();
  });

  test('has proper header structure', () => {
    renderWithRouter(<MainNavigation />);
    
    const header = screen.getByRole('banner');
    expect(header).toHaveClass('header');
    
    // Check logo container
    const logoContainer = header.querySelector('.logoContainer');
    expect(logoContainer).toBeInTheDocument();
    
    // Check navigation
    const nav = screen.getByRole('navigation');
    expect(nav).toBeInTheDocument();
    
    // Check navigation list
    const navList = nav.querySelector('ul');
    expect(navList).toBeInTheDocument();
    
    // Check that all list items are present
    const listItems = nav.querySelectorAll('li');
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
    
    const badge = document.querySelector('.badge');
    expect(badge).toHaveClass('badge');
  });

  test('renders with context provider', () => {
    // This test ensures the component works with the saved appointments context
    renderWithRouter(<MainNavigation />);
    
    // If context is working, the component should render without errors
    expect(screen.getByRole('banner')).toBeInTheDocument();
    
    // And the badge should display some value (default should be 0 or empty)
    const badge = document.querySelector('.badge');
    expect(badge).toBeInTheDocument();
  });
});
