import {
  formatDate,
  formatTime,
  formatDateTime,
  isValidEmail,
  isValidPhone,
  generateAppointmentId
} from './helpers';

describe('helpers utilities', () => {
  describe('formatDate', () => {
    test('formats valid date string', () => {
      const result = formatDate('2024-12-25');
      expect(result).toContain('Dec');
      expect(result).toContain('25');
      expect(result).toContain('2024');
    });

    test('returns empty string for null input', () => {
      expect(formatDate(null)).toBe('');
    });

    test('returns empty string for invalid date', () => {
      expect(formatDate('invalid-date')).toBe('');
    });

    test('returns empty string for empty string', () => {
      expect(formatDate('')).toBe('');
    });
  });

  describe('formatTime', () => {
    test('formats valid time string', () => {
      const result = formatTime('14:30');
      expect(result).toContain('2:30');
      expect(result).toContain('PM');
    });

    test('formats morning time', () => {
      const result = formatTime('09:15');
      expect(result).toContain('9:15');
      expect(result).toContain('AM');
    });

    test('returns empty string for null input', () => {
      expect(formatTime(null)).toBe('');
    });

    test('returns empty string for invalid time', () => {
      expect(formatTime('invalid-time')).toBe('');
    });

    test('returns empty string for empty string', () => {
      expect(formatTime('')).toBe('');
    });
  });

  describe('formatDateTime', () => {
    test('formats valid datetime string', () => {
      const result = formatDateTime('2024-12-25T14:30:00Z');
      expect(result).toContain('Dec');
      expect(result).toContain('2024');
    });

    test('returns empty string for null input', () => {
      expect(formatDateTime(null)).toBe('');
    });

    test('returns empty string for invalid datetime', () => {
      expect(formatDateTime('invalid-datetime')).toBe('');
    });

    test('returns empty string for empty string', () => {
      expect(formatDateTime('')).toBe('');
    });
  });

  describe('isValidEmail', () => {
    test('validates correct email', () => {
      expect(isValidEmail('test@example.com')).toBe(true);
    });

    test('validates email with subdomain', () => {
      expect(isValidEmail('user@mail.example.com')).toBe(true);
    });

    test('rejects email without @', () => {
      expect(isValidEmail('testexample.com')).toBe(false);
    });

    test('rejects email without domain', () => {
      expect(isValidEmail('test@')).toBe(false);
    });

    test('rejects email without username', () => {
      expect(isValidEmail('@example.com')).toBe(false);
    });

    test('rejects null input', () => {
      expect(isValidEmail(null)).toBe(false);
    });

    test('rejects empty string', () => {
      expect(isValidEmail('')).toBe(false);
    });

    test('rejects non-string input', () => {
      expect(isValidEmail(123)).toBe(false);
    });
  });

  describe('isValidPhone', () => {
    test('validates 10-digit phone number', () => {
      expect(isValidPhone('1234567890')).toBe(true);
    });

    test('validates phone with formatting', () => {
      expect(isValidPhone('(123) 456-7890')).toBe(true);
    });

    test('validates phone with dots', () => {
      expect(isValidPhone('123.456.7890')).toBe(true);
    });

    test('validates phone with spaces', () => {
      expect(isValidPhone('123 456 7890')).toBe(true);
    });

    test('rejects phone with less than 10 digits', () => {
      expect(isValidPhone('123456789')).toBe(false);
    });

    test('rejects phone with more than 10 digits', () => {
      expect(isValidPhone('12345678901')).toBe(false);
    });

    test('rejects null input', () => {
      expect(isValidPhone(null)).toBe(false);
    });

    test('rejects empty string', () => {
      expect(isValidPhone('')).toBe(false);
    });

    test('rejects non-string input', () => {
      expect(isValidPhone(123)).toBe(false);
    });
  });

  describe('generateAppointmentId', () => {
    test('generates a string id', () => {
      const id = generateAppointmentId();
      expect(typeof id).toBe('string');
    });

    test('generates unique ids', () => {
      const id1 = generateAppointmentId();
      const id2 = generateAppointmentId();
      expect(id1).not.toBe(id2);
    });

    test('generates id with reasonable length', () => {
      const id = generateAppointmentId();
      expect(id.length).toBeGreaterThan(10);
    });
  });
});
