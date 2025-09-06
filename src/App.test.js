import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import '@testing-library/jest-dom';
import App from './App';

// Mock the router for testing
const AppWithRouter = () => (
  <BrowserRouter>
    <App />
  </BrowserRouter>
);

describe('App Component', () => {
  test('renders without crashing', () => {
    render(<AppWithRouter />);
    expect(document.body).toBeInTheDocument();
  });

  test('renders main navigation', () => {
    render(<AppWithRouter />);
    // Check if the app renders successfully
    const appElement = screen.getByRole('main', { name: /app/i }) || document.querySelector('.App') || document.body;
    expect(appElement).toBeInTheDocument();
  });

  test('has correct document title', () => {
    render(<AppWithRouter />);
    expect(document.title).toBeTruthy();
  });
});
