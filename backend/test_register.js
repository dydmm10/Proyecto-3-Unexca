const email = `test_${Math.random().toString(36).slice(2, 10)}@example.com`;

fetch('http://localhost:3000/api/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password: 'password123' }),
})
  .then(async (res) => {
    const text = await res.text();
    console.log('STATUS', res.status);
    console.log('EMAIL', email);
    console.log('BODY', text);
  })
  .catch((err) => {
    console.error('ERR', err.message);
    process.exit(1);
  });
