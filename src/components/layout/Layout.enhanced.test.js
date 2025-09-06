
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import Layout from './Layout';
import SavedAppointmentsProvider from '../../store/saved-appointments-context';

// Mock MainNavigation component
jest.mock('./MainNavigation', () => {
  return function MockMainNavigation() {
    return <nav data-testid="main-navigation">Navigation</nav>;
  };
});

const renderWithProviders = (children = null) => {
  return render(
    <BrowserRouter>
      <SavedAppointmentsProvider>
        <Layout>{children}</Layout>
      </SavedAppointmentsProvider>
    </BrowserRouter>
  );
};

describe('Layout Component', () => {
  test('renders children content', () => {
    const testContent = <div data-testid="test-content">Test Content</div>;
    
    renderWithProviders(testContent);
    
    expect(screen.getByTestId('test-content')).toBeInTheDocument();
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  test('renders main element', () => {
    renderWithProviders(<div>Content</div>);
    
    const mainElement = screen.getByRole('main');
    expect(mainElement).toBeInTheDocument();
    expect(mainElement).toHaveClass('main');
  });

  test('renders MainNavigation component', () => {
    renderWithProviders();
    
    expect(screen.getByTestId('main-navigation')).toBeInTheDocument();
    expect(screen.getByText('Navigation')).toBeInTheDocument();
  });
});
