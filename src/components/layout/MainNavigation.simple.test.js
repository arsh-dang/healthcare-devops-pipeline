
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import MainNavigation from './MainNavigation';
import { SavedAppointmentsProvider } from '../../store/saved-appointments-context';

// Mock the healthcare logo to avoid file import issues in tests
jest.mock('../ui/logo/healthcare-logo.svg', () => 'healthcare-logo-mock.svg');

const renderWithRouter = (component) => {
  return render(
    <MemoryRouter>
      <SavedAppointmentsProvider>
        {component}
      </SavedAppointmentsProvider>
    </MemoryRouter>
  );
};

describe('MainNavigation', () => {
  test('renders header and navigation structure', () => {
    renderWithRouter(<MainNavigation />);
    
    const header = screen.getByRole('banner');
    expect(header).toBeInTheDocument();
    expect(header).toHaveClass('header');
    
    const nav = screen.getByRole('navigation');
    expect(nav).toBeInTheDocument();
  });

  test('displays healthcare logo and title', () => {
    renderWithRouter(<MainNavigation />);
    
    const logo = screen.getByAltText('Healthcare Logo');
    expect(logo).toBeInTheDocument();
    expect(logo).toHaveAttribute('src', 'healthcare-logo-mock.svg');
    expect(logo).toHaveClass('logoImage');
    
    const title = screen.getByText('Healthcare Appointments');
    expect(title).toBeInTheDocument();
    expect(title).toHaveClass('logoText');
  });

  test('renders all navigation links with correct attributes', () => {
    renderWithRouter(<MainNavigation />);
    
    const allAppointmentsLink = screen.getByRole('link', { name: 'All Appointments' });
    expect(allAppointmentsLink).toBeInTheDocument();
    expect(allAppointmentsLink).toHaveAttribute('href', '/');
    
    const bookAppointmentLink = screen.getByRole('link', { name: 'Book Appointment' });
    expect(bookAppointmentLink).toBeInTheDocument();
    expect(bookAppointmentLink).toHaveAttribute('href', '/new-appointment');
    
    const savedAppointmentsLink = screen.getByRole('link', { name: /Saved Appointments/ });
    expect(savedAppointmentsLink).toBeInTheDocument();
    expect(savedAppointmentsLink).toHaveAttribute('href', '/saved-appointments');
  });

  test('displays saved appointments badge', () => {
    renderWithRouter(<MainNavigation />);
    
    const savedLink = screen.getByRole('link', { name: /Saved Appointments/ });
    expect(savedLink).toBeInTheDocument();
    expect(screen.getByText('0')).toBeInTheDocument();
  });

  test('has correct navigation structure', () => {
    renderWithRouter(<MainNavigation />);
    
    const nav = screen.getByRole('navigation');
    expect(nav).toBeInTheDocument();
    
    const listItems = screen.getAllByRole('listitem');
    expect(listItems).toHaveLength(3);
  });

  test('logo container has correct structure', () => {
    renderWithRouter(<MainNavigation />);
    
    const header = screen.getByRole('banner');
    expect(header).toBeInTheDocument();
    expect(screen.getByAltText('Healthcare Logo')).toBeInTheDocument();
  });
});
