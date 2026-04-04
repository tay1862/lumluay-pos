import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';

const PIN_ROUNDS = 10;
const BCRYPT_ROUNDS = 12;

/** Hash a PIN (4-6 digits) using bcrypt */
export async function hashPin(pin: string): Promise<string> {
  return bcrypt.hash(pin, PIN_ROUNDS);
}

/** Verify a plain PIN against its bcrypt hash */
export async function verifyPin(pin: string, hash: string): Promise<boolean> {
  return bcrypt.compare(pin, hash);
}

/** Hash a password using bcrypt */
export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

/** Verify a plain password against its bcrypt hash */
export async function verifyPassword(
  password: string,
  hash: string,
): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

/** Generate a cryptographically secure random token (hex) */
export function generateToken(bytes = 32): string {
  return crypto.randomBytes(bytes).toString('hex');
}

/** Generate a short readable code (uppercase, alphanumeric) */
export function generateCode(length = 8): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from(crypto.randomBytes(length))
    .map((b) => chars[b % chars.length])
    .join('');
}
