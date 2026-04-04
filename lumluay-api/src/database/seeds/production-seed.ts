import { randomUUID } from 'node:crypto';
import { drizzle } from 'drizzle-orm/postgres-js';
import { eq } from 'drizzle-orm';
import postgres from 'postgres';
import bcrypt from 'bcrypt';
import * as schema from '../schema';

async function ensurePlan(
  db: ReturnType<typeof drizzle<typeof schema>>,
  input: {
    name: string;
    slug: string;
    monthlyPrice: string;
    yearlyPrice?: string;
    maxUsers?: string;
    maxProducts?: string;
    maxBranches?: string;
    features?: string[];
  },
) {
  const existing = await db.query.subscriptionPlans.findFirst({
    where: eq(schema.subscriptionPlans.slug, input.slug),
  });
  if (existing) return existing;

  const [created] = await db
    .insert(schema.subscriptionPlans)
    .values({
      name: input.name,
      slug: input.slug,
      monthlyPrice: input.monthlyPrice,
      yearlyPrice: input.yearlyPrice,
      maxUsers: input.maxUsers,
      maxProducts: input.maxProducts,
      maxBranches: input.maxBranches,
      features: input.features ?? [],
      isActive: true,
    })
    .returning();

  return created;
}

export async function seedProduction() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL is required');
  }

  const adminUsername = process.env.SEED_SUPER_ADMIN_USERNAME ?? 'superadmin';
  const adminPassword = process.env.SEED_SUPER_ADMIN_PASSWORD ?? 'ChangeMeNow123!';
  const adminDisplayName = process.env.SEED_SUPER_ADMIN_DISPLAY_NAME ?? 'System Admin';

  const client = postgres(databaseUrl, { max: 1 });
  const db = drizzle(client, { schema });

  try {
    await ensurePlan(db, {
      name: 'Starter',
      slug: 'starter',
      monthlyPrice: '990',
      yearlyPrice: '9900',
      maxUsers: '5',
      maxProducts: '500',
      maxBranches: '1',
      features: ['pos', 'reports', 'inventory'],
    });

    await ensurePlan(db, {
      name: 'Growth',
      slug: 'growth',
      monthlyPrice: '1990',
      yearlyPrice: '19900',
      maxUsers: '20',
      maxProducts: '5000',
      maxBranches: '5',
      features: ['pos', 'reports', 'inventory', 'kds', 'queue'],
    });

    const existingAdmin = await db.query.users.findFirst({
      where: eq(schema.users.username, adminUsername),
    });

    if (!existingAdmin) {
      const passwordHash = await bcrypt.hash(adminPassword, 10);
      await db.insert(schema.users).values({
        id: randomUUID(),
        tenantId: null,
        username: adminUsername,
        passwordHash,
        displayName: adminDisplayName,
        role: 'super_admin',
        isActive: true,
        locale: 'th',
      });
      console.log('[seed] Created super admin account');
    } else {
      console.log('[seed] Super admin already exists, skipped');
    }

    console.log('[seed] Production seed completed');
  } finally {
    await client.end();
  }
}
