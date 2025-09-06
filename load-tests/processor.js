module.exports = {
  $randomFullName,
  $randomLastName,
  $randomFutureDate
};

function $randomFullName(context, events, done) {
  const firstNames = ['John', 'Jane', 'Alice', 'Bob', 'Charlie', 'Diana', 'Edward', 'Fiona'];
  const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis'];
  
  const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
  const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
  
  return done(null, `${firstName} ${lastName}`);
}

function $randomLastName(context, events, done) {
  const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis'];
  const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
  
  return done(null, lastName);
}

function $randomFutureDate(context, events, done) {
  const now = new Date();
  const futureDate = new Date(now.getTime() + Math.random() * 30 * 24 * 60 * 60 * 1000); // Random date within 30 days
  
  return done(null, futureDate.toISOString());
}
