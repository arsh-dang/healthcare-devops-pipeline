import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import App from './App';
import { SavedAppointmentsProvider } from './store/saved-appointments-context';

// Mock all page components
jest.mock('./pages/AllAppointments', () => {
  return function MockAllAppointments() {
    return <div data-testid="all-appointments">All Appointments Page</div>;
  };
});

jest.mock('./pages/NewAppointment', () => {
  return function MockNewAppointment() {
    return <div data-testid="new-appointment">New Appointment Page</div>;
  };
});

jest.mock('./pages/SavedAppointments', () => {
  return function MockSavedAppointments() {
    return <div data-testid="saved-appointments">Saved Appointments Page</div>;
  };
});

// Mock Layout component
function MockLayout({ children }) {
  return (
    <div data-testid="layout">
      <div>Layout Component</div>
      {children}
    </div>
  );
}

MockLayout.propTypes = {
  children: PropTypes.node,
};

jest.mock('./components/layout/Layout', () => {
  return MockLayout;
});

const renderWithRouter = (component, { route = '/' } = {}) => {
  return render(
    <MemoryRouter initialEntries={[route]}>
      <SavedAppointmentsProvider>
        {component}
      </SavedAppointmentsProvider>
    </MemoryRouter>
  );
};

describe('App', () => {
  test('renders without crashing', () => {
    renderWithRouter(<App />);
    
    expect(screen.getByTestId('layout')).toBeInTheDocument();
    expect(screen.getByText('Layout Component')).toBeInTheDocument();
  });

  test('renders AllAppointments page on default route', () => {
    renderWithRouter(<App />, { route: '/' });
    expect(screen.getByTestId('all-appointments')).toBeInTheDocument();
  });

  test('renders NewAppointment page on /new-appointment route', () => {
    renderWithRouter(<App />, { route: '/new-appointment' });
    expect(screen.getByTestId('new-appointment')).toBeInTheDocument();
  });

  test('renders SavedAppointments page on /saved-appointments route', () => {
    renderWithRouter(<App />, { route: '/saved-appointments' });
    expect(screen.getByTestId('saved-appointments')).toBeInTheDocument();
  });

  test('app structure contains routes', () => {
    renderWithRouter(<App />);
    
    const layout = screen.getByTestId('layout');
    expect(layout).toBeInTheDocument();
  });
});