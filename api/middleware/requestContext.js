import crypto from 'crypto';

export function requestContext(req, res, next) {
  const forwarded = req.headers['x-request-id'];
  req.id = typeof forwarded === 'string' && forwarded.length <= 128
    ? forwarded
    : crypto.randomUUID();
  res.setHeader('x-request-id', req.id);
  next();
}
