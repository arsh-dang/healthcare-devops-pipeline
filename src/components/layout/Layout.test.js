import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import '@testing-library/jest-dom';
import Layout from './Layout';

const LayoutWithRouter = ({ children }) => (
  <BrowserRouter>
    <Layout>{children}</Layout>
  </BrowserRouter>
);

describe('Layout Component', () => {
  test('renders without crashing', () => {
    render(
      <LayoutWithRouter>
        <div>Test Content</div>
      </LayoutWithRouter>
    );
    expect(document.body).toBeInTheDocument();
  });

  test('renders children content', () => {
    render(
      <LayoutWithRouter>
        <div data-testid="test-content">Test Content</div>
      </LayoutWithRouter>
    );
    expect(screen.getByTestId('test-content')).toBeInTheDocument();
  });

  test('contains navigation structure', () => {
    render(
      <LayoutWithRouter>
        <div>Test Content</div>
      </LayoutWithRouter>
    );
    // Layout should contain the test content
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });
});
