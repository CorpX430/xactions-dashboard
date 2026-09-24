// Copyright (c) 2024-2026 nich (@nichxbt). Licensed under the Apache License, Version 2.0.
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
let clerkBackend;

function clerkConfigured() {
  return Boolean(process.env.CLERK_SECRET_KEY);
}

async function getClerkBackend() {
  if (!clerkBackend) {
    try {
      clerkBackend = await import('@clerk/backend');
    } catch (error) {
      const wrapped = new Error('Clerk authentication is configured but @clerk/backend is not installed');
      wrapped.cause = error;
      throw wrapped;
    }
  }
  return clerkBackend;
}

function safeUsername(clerkUser) {
  const preferred = clerkUser.username || clerkUser.firstName || clerkUser.emailAddress?.split('@')[0];
  const normalized = String(preferred || `clerk_${clerkUser.id.slice(-12)}`)
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .slice(0, 30);
  return normalized.length >= 3 ? normalized : `user_${clerkUser.id.slice(-12)}`;
}

function clerkClaimsToUser(claims) {
  const id = claims.sub;
  const email = claims.email || claims.email_address || claims.primary_email_address || null;
  return {
    clerkId: id,
    email,
    username: String(claims.username || (email ? email.split('@')[0] : `clerk_${id.slice(-12)}`))
      .toLowerCase()
      .replace(/[^a-z0-9_]/g, '_')
      .slice(0, 30),
  };
}

async function provisionClerkUser(claims) {
  const mapped = clerkClaimsToUser(claims);
  const existing = await prisma.user.findUnique({ where: { clerkId: mapped.clerkId } });
  if (existing) return existing;

  const clerk = await getClerkBackend();
  let profile = claims;
  if (clerk.createClerkClient) {
    try {
      const client = createClerkClientSafe(clerk);
      profile = await client.users.getUser(mapped.clerkId);
    } catch (error) {
      console.warn(`⚠️ Clerk profile lookup failed for ${mapped.clerkId}:`, error.message);
    }
  }

  const email = profile.primaryEmailAddress?.emailAddress || profile.emailAddresses?.[0]?.emailAddress || mapped.email;
  const baseUsername = safeUsername({ ...profile, id: mapped.clerkId, emailAddress: email });
  let username = baseUsername;
  for (let suffix = 1; suffix < 100; suffix += 1) {
    const collision = await prisma.user.findUnique({ where: { username } });
    if (!collision) break;
    username = `${baseUsername.slice(0, 30 - String(suffix).length - 1)}_${suffix}`;
  }

  return prisma.user.create({
    data: {
      clerkId: mapped.clerkId,
      email,
      username,
      authMethod: 'clerk',
      subscription: {
        create: { tier: 'free', status: 'active', startDate: new Date() },
      },
    },
    include: { subscription: true },
  });
}

function createClerkClientSafe(clerk) {
  if (typeof clerk.createClerkClient === 'function') {
    return clerk.createClerkClient({ secretKey: process.env.CLERK_SECRET_KEY });
  }
  if (typeof clerk.clerkClient === 'function') return clerk.clerkClient();
  return null;
}

async function resolveClerkUser(token) {
  const clerk = await getClerkBackend();
  if (typeof clerk.verifyToken !== 'function') throw new Error('Installed @clerk/backend does not expose verifyToken');
  const claims = await clerk.verifyToken(token, { secretKey: process.env.CLERK_SECRET_KEY });
  if (!claims?.sub) throw new Error('Clerk token has no subject');
  return provisionClerkUser(claims);
}

async function resolveLocalUser(token) {
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  if (!decoded?.userId) throw new Error('Token has no user id');
  return prisma.user.findUnique({ where: { id: decoded.userId }, include: { subscription: true } });
}

export async function resolveUserFromToken(token) {
  if (!token) return null;
  if (clerkConfigured()) {
    try {
      return await resolveClerkUser(token);
    } catch (error) {
      // During migration, accept existing local JWTs even when Clerk is enabled.
      if (process.env.AUTH_ALLOW_LOCAL_JWT !== 'false' && process.env.JWT_SECRET) {
        return resolveLocalUser(token);
      }
      throw error;
    }
  }
  return resolveLocalUser(token);
}

export function isClerkConfigured() {
  return clerkConfigured();
}

export { prisma };
