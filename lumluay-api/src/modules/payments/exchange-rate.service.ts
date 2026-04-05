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

  private baseCurrencyKey(tenantId: string) {
    return `exchange:base:${tenantId}`;
  }

  async getBaseCurrency(tenantId: string): Promise<string> {
    const key = this.baseCurrencyKey(tenantId);
    const cached = await this.redis.get(key);
    if (cached) return cached;

    const data = await this.settingsService.getCurrencies(tenantId);
    const base = (data.defaultCurrency ?? 'LAK').toUpperCase();
    await this.redis.set(key, base, 'EX', 600);
    return base;
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
    await this.redis.del(this.baseCurrencyKey(tenantId));
  }

  /**
   * Convert an amount in a given currency to the tenant's base currency.
   * Exchange rates are stored as: 1 base = N foreign.
   * E.g. base=LAK, rates={ THB: 600, USD: 21000 } means 1 THB = 600 LAK.
   */
  async toBase(
    tenantId: string,
    amount: number,
    currency: string,
    explicitRate?: number,
  ): Promise<{ baseAmount: number; rate: number; baseCurrency: string }> {
    const c = currency.toUpperCase();
    const baseCurrency = await this.getBaseCurrency(tenantId);

    if (c === baseCurrency) {
      return { baseAmount: amount, rate: 1, baseCurrency };
    }

    const rates = await this.getRates(tenantId);
    // Rate represents: 1 foreign currency = N base currency
    // E.g. if base=LAK and rates.THB=600, then 1 THB = 600 LAK
    const rate = explicitRate ?? Number(rates[c] ?? 1);
    const baseAmount = rate > 0 ? amount * rate : amount;

    return {
      baseAmount: Math.round(baseAmount * 100) / 100,
      rate,
      baseCurrency,
    };
  }

  /**
   * Convert an amount in the base currency to a foreign currency.
   */
  async fromBase(
    tenantId: string,
    baseAmount: number,
    targetCurrency: string,
  ): Promise<{ foreignAmount: number; rate: number; baseCurrency: string }> {
    const t = targetCurrency.toUpperCase();
    const baseCurrency = await this.getBaseCurrency(tenantId);

    if (t === baseCurrency) {
      return { foreignAmount: baseAmount, rate: 1, baseCurrency };
    }

    const rates = await this.getRates(tenantId);
    const rate = Number(rates[t] ?? 1);
    const foreignAmount = rate > 0 ? baseAmount / rate : baseAmount;

    return {
      foreignAmount: Math.round(foreignAmount * 100) / 100,
      rate,
      baseCurrency,
    };
  }
}
