import { Injectable, Inject } from '@nestjs/common';
import { REDIS_CLIENT } from '@/config/redis.module';
import Redis from 'ioredis';
import { SettingsService } from '@/modules/settings/settings.service';

@Injectable()
export class ExchangeRateService {
  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly settingsService: SettingsService,
  ) {}

  private cacheKey(tenantId: string) {
    return `exchange:rates:${tenantId}`;
  }

  async getRates(tenantId: string): Promise<Record<string, number>> {
    const key = this.cacheKey(tenantId);
    const cached = await this.redis.get(key);
    if (cached) {
      try {
        return JSON.parse(cached) as Record<string, number>;
      } catch {
        // fall through
      }
    }

    const data = await this.settingsService.getCurrencies(tenantId);
    const rates = data.exchangeRates ?? {};
    await this.redis.set(key, JSON.stringify(rates), 'EX', 600);
    return rates;
  }

  async invalidate(tenantId: string): Promise<void> {
    await this.redis.del(this.cacheKey(tenantId));
  }

  async toBase(
    tenantId: string,
    amount: number,
    currency: string,
    explicitRate?: number,
  ): Promise<{ baseAmount: number; rate: number }> {
    const c = currency.toUpperCase();
    if (c === 'THB') {
      return { baseAmount: amount, rate: 1 };
    }

    const rates = await this.getRates(tenantId);
    const rate = explicitRate ?? Number(rates[c] ?? 1);
    const baseAmount = rate > 0 ? amount / rate : amount;

    return {
      baseAmount: Math.round(baseAmount * 100) / 100,
      rate,
    };
  }
}
