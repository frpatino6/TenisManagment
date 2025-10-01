"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateBody = validateBody;
function validateBody(schema) {
    return (req, res, next) => {
        try {
            // zod-like interface expected
            if (typeof schema.safeParse === 'function') {
                const result = schema.safeParse(req.body);
                if (!result.success) {
                    const details = (result.error?.issues || []).map((i) => ({
                        path: i.path.join('.'),
                        message: i.message,
                    }));
                    return res.status(400).json({ error: 'Invalid request body', details });
                }
                req.body = result.data;
            }
            else {
                req.body = schema.parse(req.body);
            }
            next();
        }
        catch (error) {
            return res.status(400).json({ error: 'Invalid request body' });
        }
    };
}
//# sourceMappingURL=validation.js.map