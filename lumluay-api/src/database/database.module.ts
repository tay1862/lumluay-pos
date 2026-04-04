import { Module, Global, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

export const DATABASE = 'DATABASE';
export const InjectDrizzle = () => Inject(DATABASE);

@Global()
@Module({
  providers: [
    {
      provide: DATABASE,
      useFactory: (configService: ConfigService) => {
        const url = configService.get<string>('database.url')!;
        const client = postgres(url, {
          max: configService.get<number>('database.poolMax', 10),
          idle_timeout: 30,
          connect_timeout: 10,
          onnotice: () => {},
        });
        const db = drizzle(client, { schema });
        console.log('✅ Database connected');
        return db;
      },
      inject: [ConfigService],
    },
  ],
  exports: [DATABASE],
})
export class DatabaseModule {}
