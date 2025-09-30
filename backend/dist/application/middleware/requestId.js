"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requestIdMiddleware = requestIdMiddleware;
const Logger_1 = require("../../infrastructure/services/Logger");
function requestIdMiddleware(req, _res, next) {
    req.requestId = req.headers['x-request-id']?.toString() || (0, Logger_1.createRequestId)();
    next();
}
//# sourceMappingURL=requestId.js.map