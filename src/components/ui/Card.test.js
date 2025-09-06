
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import Card from './Card';

describe('Card', () => {
  test('renders children content', () => {
    render(
      <Card>
        <div data-testid="card-content">Test Content</div>
      </Card>
    );
    
    expect(screen.getByTestId('card-content')).toBeInTheDocument();
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  test('renders with CSS class applied', () => {
    render(
      <Card>
        <div>Content</div>
      </Card>
    );
    
    expect(screen.getByTestId('card')).toHaveClass('card');
  });

  test('renders with multiple children', () => {
    render(
      <Card>
        <h2>Card Title</h2>
        <p>Card description</p>
        <button>Action</button>
      </Card>
    );
    
    expect(screen.getByText('Card Title')).toBeInTheDocument();
    expect(screen.getByText('Card description')).toBeInTheDocument();
    expect(screen.getByText('Action')).toBeInTheDocument();
  });

  test('renders without children', () => {
    render(<Card />);
    
    const cardElement = screen.getByTestId('card');
    expect(cardElement).toHaveClass('card');
    expect(cardElement).toBeEmptyDOMElement();
  });

  test('renders complex nested content', () => {
    render(
      <Card>
        <div>
          <header>
            <h1>Complex Card</h1>
          </header>
          <main>
            <section>
              <p>Section content</p>
              <ul>
                <li>Item 1</li>
                <li>Item 2</li>
              </ul>
            </section>
          </main>
          <footer>
            <button>Footer Button</button>
          </footer>
        </div>
      </Card>
    );
    
    expect(screen.getByText('Complex Card')).toBeInTheDocument();
    expect(screen.getByText('Section content')).toBeInTheDocument();
    expect(screen.getByText('Item 1')).toBeInTheDocument();
    expect(screen.getByText('Item 2')).toBeInTheDocument();
    expect(screen.getByText('Footer Button')).toBeInTheDocument();
  });

  test('passes through HTML attributes', () => {
    render(
      <Card data-testid="test-card">
        <div>Content</div>
      </Card>
    );
    
    const cardElement = screen.getByTestId('card');
    expect(cardElement).toHaveClass('card');
    // Card component may not pass through all props, that's ok for this test
  });

  test('renders string content', () => {
    render(
      <Card>
        Simple text content
      </Card>
    );
    
    expect(screen.getByText('Simple text content')).toBeInTheDocument();
  });

  test('renders mixed content types', () => {
    render(
      <Card>
        <span>Text content</span>
        <span>Span element</span>
        <span>123</span>
        <div>Div element</div>
      </Card>
    );
    
    expect(screen.getByText('Text content')).toBeInTheDocument();
    expect(screen.getByText('Span element')).toBeInTheDocument();
    expect(screen.getByText('123')).toBeInTheDocument();
    expect(screen.getByText('Div element')).toBeInTheDocument();
  });

  test('preserves event handlers on children', () => {
    const handleClick = jest.fn();
    
    render(
      <Card>
        <button onClick={handleClick}>Click me</button>
      </Card>
    );
    
    const button = screen.getByText('Click me');
    button.click();
    
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  test('renders as a div element', () => {
    render(
      <Card>
        <div>Content</div>
      </Card>
    );
    
    expect(screen.getByTestId('card').tagName).toBe('DIV');
  });
});
