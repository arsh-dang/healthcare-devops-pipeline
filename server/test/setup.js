// Jest setup file for proper cleanup
const mongoose = require('mongoose');

// Ensure all connections are closed after tests
afterAll(async () => {
  // Close all mongoose connections
  if (mongoose.connection.readyState !== 0) {
    await mongoose.connection.close();
  }

  // Force disconnect to ensure clean exit
  await mongoose.disconnect();

  // Clear any remaining timers
  if (typeof jest !== 'undefined') {
    jest.clearAllTimers();
  }
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err); // eslint-disable-line no-console
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason); // eslint-disable-line no-console
  process.exit(1);
});
