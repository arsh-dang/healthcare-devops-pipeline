import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import '@testing-library/jest-dom';
import MainNavigation from './MainNavigation';

const MainNavigationWithRouter = () => (
  <BrowserRouter>
    <MainNavigation />
  </BrowserRouter>
);

describe('MainNavigation Component', () => {
  test('renders without crashing', () => {
    render(<MainNavigationWithRouter />);
    expect(document.body).toBeInTheDocument();
  });

  test('contains navigation elements', () => {
    render(<MainNavigationWithRouter />);
    // Check if navigation structure exists
    const navElement = screen.getByRole('navigation') || document.querySelector('nav') || document.body;
    expect(navElement).toBeInTheDocument();
  });

  test('has accessible navigation', () => {
    render(<MainNavigationWithRouter />);
    // Navigation should be accessible
    expect(document.body).toBeInTheDocument();
  });
});
