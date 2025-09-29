"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateBody = validateBody;
function validateBody(schema) {
    return (req, res, next) => {
        try {
            // zod-like interface expected
            req.body = schema.parse(req.body);
            next();
        }
        catch (error) {
            return res.status(400).json({ error: 'Invalid request body' });
        }
    };
}
//# sourceMappingURL=validation.js.map