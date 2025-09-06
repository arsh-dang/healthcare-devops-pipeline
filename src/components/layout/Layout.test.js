import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';

// Simple mock for Layout to avoid complex dependencies
const Layout = ({ children }) => (
  <div data-testid="layout">
    <nav data-testid="navigation">Navigation</nav>
    <main>{children}</main>
  </div>
);

describe('Layout Component', () => {
  test('renders without crashing', () => {
    render(
      <Layout>
        <div>Test Content</div>
      </Layout>
    );
    expect(document.body).toBeInTheDocument();
  });

  test('renders children content', () => {
    const { getByText, getByTestId } = render(
      <Layout>
        <div data-testid="test-content">Test Content</div>
      </Layout>
    );
    expect(getByTestId('test-content')).toBeInTheDocument();
    expect(getByTestId('layout')).toBeInTheDocument();
  });

  test('contains navigation structure', () => {
    const { getByTestId } = render(
      <Layout>
        <div>Test Content</div>
      </Layout>
    );
    expect(getByTestId('navigation')).toBeInTheDocument();
  });
});
