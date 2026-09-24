import assert from 'node:assert/strict';
import { createApp } from '../api/server.js';

const { app, httpServer, io } = createApp({ rateLimiting: false });
assert.ok(app, 'Express app should be created');
assert.ok(io, 'Socket.IO instance should be created');

const response = await new Promise((resolve, reject) => {
  const server = httpServer.listen(0, async () => {
    const { port } = server.address();
    try {
      const health = await fetch(`http://127.0.0.1:${port}/api/health`, {
        headers: { Origin: 'http://localhost:3000', 'X-Request-Id': 'task2-smoke' },
      });
      resolve({ health, server });
    } catch (error) {
      reject(error);
    }
  });
});

assert.equal(response.health.status, 200);
const body = await response.health.json();
assert.equal(body.status, 'ok');
assert.equal(response.health.headers.get('x-request-id'), 'task2-smoke');
assert.equal(response.health.headers.get('access-control-allow-origin'), 'http://localhost:3000');
const protectedResponse = await fetch(`http://127.0.0.1:${response.server.address().port}/api/graph`);
assert.equal(protectedResponse.status, 401, 'Graph route should reject missing credentials');
const workflowResponse = await fetch(`http://127.0.0.1:${response.server.address().port}/api/workflows`);
assert.equal(workflowResponse.status, 401, 'Workflow route should reject missing credentials');
const enhancedResponse = await fetch(`http://127.0.0.1:${response.server.address().port}/api/enhanced/status`);
assert.equal(enhancedResponse.status, 401, 'Enhanced integration route should reject missing credentials');
response.server.close();
io.close();
console.log('task2 smoke passed');
