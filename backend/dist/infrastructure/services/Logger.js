"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Logger = void 0;
exports.createRequestId = createRequestId;
const crypto_1 = require("crypto");
class Logger {
    constructor(defaultFields = {}) {
        this.defaultFields = defaultFields;
    }
    child(extra) {
        return new Logger({ ...this.defaultFields, ...extra });
    }
    write(level, msg, fields) {
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
    debug(msg, fields) { this.write('debug', msg, fields); }
    info(msg, fields) { this.write('info', msg, fields); }
    warn(msg, fields) { this.write('warn', msg, fields); }
    error(msg, fields) { this.write('error', msg, fields); }
}
exports.Logger = Logger;
function createRequestId() {
    return (0, crypto_1.randomUUID)();
}
//# sourceMappingURL=Logger.js.map