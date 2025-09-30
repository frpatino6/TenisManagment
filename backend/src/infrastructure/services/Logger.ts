import { randomUUID } from 'crypto';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export interface LogFields {
  [key: string]: unknown;
}

export class Logger {
  constructor(private readonly defaultFields: LogFields = {}) {}

  child(extra: LogFields): Logger {
    return new Logger({ ...this.defaultFields, ...extra });
  }

  private write(level: LogLevel, msg: string, fields?: LogFields): void {
    const record = {
      level,
      msg,
      time: new Date().toISOString(),
      ...this.defaultFields,
      ...(fields || {})
    };
    // eslint-disable-next-line no-console
    console[level === 'debug' ? 'log' : level](JSON.stringify(record));
  }

  debug(msg: string, fields?: LogFields): void { this.write('debug', msg, fields); }
  info(msg: string, fields?: LogFields): void { this.write('info', msg, fields); }
  warn(msg: string, fields?: LogFields): void { this.write('warn', msg, fields); }
  error(msg: string, fields?: LogFields): void { this.write('error', msg, fields); }
}

export function createRequestId(): string {
  return randomUUID();
}

