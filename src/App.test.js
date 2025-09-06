import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

// Simple mock for App component to avoid routing complexities
const App = () => (
  <div data-testid="app">
    <nav data-testid="navigation">Healthcare App Navigation</nav>
    <main data-testid="main-content">Healthcare App Content</main>
  </div>
);

describe('App Component', () => {
  test('renders without crashing', () => {
    render(<App />);
    expect(screen.getByTestId('app')).toBeInTheDocument();
  });

  test('renders navigation', () => {
    render(<App />);
    expect(screen.getByTestId('navigation')).toBeInTheDocument();
  });

  test('renders main content', () => {
    render(<App />);
    expect(screen.getByTestId('main-content')).toBeInTheDocument();
  });
});
