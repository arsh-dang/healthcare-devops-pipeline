
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import Layout from './Layout';
import SavedAppointmentsProvider from '../../store/saved-appointments-context';

jest.mock('./MainNavigation', () => {
  return function MockMainNavigation() {
    return <nav data-testid="main-navigation">Navigation</nav>;
  };
});

describe('Layout', () => {
  test('renders navigation and children', () => {
    render(
      <BrowserRouter>
        <SavedAppointmentsProvider>
          <Layout>
            <div data-testid="test-content">Test Content</div>
          </Layout>
        </SavedAppointmentsProvider>
      </BrowserRouter>
    );

    expect(screen.getByTestId('main-navigation')).toBeInTheDocument();
    expect(screen.getByTestId('test-content')).toBeInTheDocument();
  });

  test('applies CSS class to main element', () => {
    render(
      <BrowserRouter>
        <SavedAppointmentsProvider>
          <Layout>
            <div>Content</div>
          </Layout>
        </SavedAppointmentsProvider>
      </BrowserRouter>
    );

    const mainElement = screen.getByRole('main');
    expect(mainElement).toHaveClass('main');
  });

  test('renders with empty children', () => {
    render(
      <BrowserRouter>
        <SavedAppointmentsProvider>
          <Layout />
        </SavedAppointmentsProvider>
      </BrowserRouter>
    );

    expect(screen.getByTestId('main-navigation')).toBeInTheDocument();
    expect(screen.getByRole('main')).toBeInTheDocument();
  });
});