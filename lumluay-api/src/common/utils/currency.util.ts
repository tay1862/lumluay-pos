/** Supported currency codes */
export type CurrencyCode = 'THB' | 'LAK' | 'USD' | string;

interface CurrencyMeta {
  symbol: string;
  decimals: number;
  symbolPosition: 'before' | 'after';
}

const CURRENCIES: Record<string, CurrencyMeta> = {
  THB: { symbol: '฿', decimals: 2, symbolPosition: 'before' },
  LAK: { symbol: '₭', decimals: 0, symbolPosition: 'after' },
  USD: { symbol: '$', decimals: 2, symbolPosition: 'before' },
  EUR: { symbol: '€', decimals: 2, symbolPosition: 'before' },
};

function getMeta(currency: string): CurrencyMeta {
  return CURRENCIES[currency.toUpperCase()] ?? { symbol: currency, decimals: 2, symbolPosition: 'before' };
}

/** Format a numeric amount as a currency string */
export function formatCurrency(
  amount: number,
  currency: CurrencyCode = 'LAK',
  options?: { showSymbol?: boolean },
): string {
  const meta = getMeta(currency);
  const showSymbol = options?.showSymbol ?? true;
  const fixed = amount.toFixed(meta.decimals);
  const [intPart, decPart] = fixed.split('.');
  const formatted =
    intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ',') +
    (meta.decimals > 0 && decPart ? `.${decPart}` : '');

  if (!showSymbol) return formatted;
  return meta.symbolPosition === 'before'
    ? `${meta.symbol}${formatted}`
    : `${formatted}${meta.symbol}`;
}

/** Convert an amount between two currencies using an exchange rate map */
export function convertCurrency(
  amount: number,
  fromCurrency: string,
  toCurrency: string,
  rates: Record<string, number>,
): number {
  if (fromCurrency === toCurrency) return amount;
  const fromRate = rates[fromCurrency] ?? 1;
  const toRate = rates[toCurrency] ?? 1;
  // Convert via the supplied base-currency rate map.
  return (amount / fromRate) * toRate;
}

/** Round to currency's decimal places */
export function roundToCurrency(amount: number, currency: CurrencyCode): number {
  const meta = getMeta(currency);
  return parseFloat(amount.toFixed(meta.decimals));
}
