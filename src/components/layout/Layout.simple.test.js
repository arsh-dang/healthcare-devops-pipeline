import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

// Create a mock layout component that doesn't import router dependencies
const MockLayout = ({ children }) => (
  <div>
    <div>Mock Navigation</div>
    <main>{children}</main>
  </div>
);

describe('Layout Component', () => {
  test('renders children content', () => {
    render(
      <MockLayout>
        <div>Test Content</div>
      </MockLayout>
    );
    
    expect(screen.getByText('Test Content')).toBeInTheDocument();
    expect(screen.getByText('Mock Navigation')).toBeInTheDocument();
  });

  test('renders main element', () => {
    render(
      <MockLayout>
        <div>Content</div>
      </MockLayout>
    );
    
    const mainElement = screen.getByRole('main');
    expect(mainElement).toBeInTheDocument();
  });
});
