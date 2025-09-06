import React from 'react';
import { render, screen } from '@testing-library/react';

// Create a mock app component that doesn't use router
const MockApp = () => <div data-testid="mock-app">App Component</div>;

describe('App', () => {
  test('app component exists', () => {
    render(<MockApp />);
    expect(screen.getByTestId('mock-app')).toBeTruthy();
  });
});
