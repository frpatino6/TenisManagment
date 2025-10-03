"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rateLimitAnalytics = exports.sanitizeQueryParams = exports.validateAnalyticsQuery = exports.validateSort = exports.validatePagination = exports.validateDateRange = exports.validatePaymentStatus = exports.validateBookingStatus = exports.validateServiceType = exports.validatePeriod = void 0;
/**
 * Validation middleware for analytics endpoints
 * Ensures all query parameters are valid and within acceptable ranges
 */
// Valid periods for analytics
const VALID_PERIODS = ['week', 'month', 'quarter', 'year'];
// Valid service types
const VALID_SERVICE_TYPES = ['individual_class', 'group_class', 'court_rental'];
// Valid booking statuses
const VALID_STATUSES = ['pending', 'confirmed', 'cancelled', 'completed'];
// Valid payment statuses
const VALID_PAYMENT_STATUSES = ['pending', 'paid', 'cancelled'];
/**
 * Validates period parameter
 */
const validatePeriod = (req, res, next) => {
    const { period } = req.query;
    if (period && typeof period === 'string') {
        if (!VALID_PERIODS.includes(period)) {
            return res.status(400).json({
                error: 'Período inválido',
                message: `El período debe ser uno de: ${VALID_PERIODS.join(', ')}`,
                validPeriods: VALID_PERIODS,
                received: period,
            });
        }
    }
    next();
};
exports.validatePeriod = validatePeriod;
/**
 * Validates service type parameter
 */
const validateServiceType = (req, res, next) => {
    const { serviceType } = req.query;
    if (serviceType && typeof serviceType === 'string') {
        if (!VALID_SERVICE_TYPES.includes(serviceType)) {
            return res.status(400).json({
                error: 'Tipo de servicio inválido',
                message: `El tipo de servicio debe ser uno de: ${VALID_SERVICE_TYPES.join(', ')}`,
                validServiceTypes: VALID_SERVICE_TYPES,
                received: serviceType,
            });
        }
    }
    next();
};
exports.validateServiceType = validateServiceType;
/**
 * Validates status parameter (for bookings)
 */
const validateBookingStatus = (req, res, next) => {
    const { status } = req.query;
    if (status && typeof status === 'string') {
        if (!VALID_STATUSES.includes(status)) {
            return res.status(400).json({
                error: 'Estado de reserva inválido',
                message: `El estado debe ser uno de: ${VALID_STATUSES.join(', ')}`,
                validStatuses: VALID_STATUSES,
                received: status,
            });
        }
    }
    next();
};
exports.validateBookingStatus = validateBookingStatus;
/**
 * Validates payment status parameter
 */
const validatePaymentStatus = (req, res, next) => {
    const { paymentStatus } = req.query;
    if (paymentStatus && typeof paymentStatus === 'string') {
        if (!VALID_PAYMENT_STATUSES.includes(paymentStatus)) {
            return res.status(400).json({
                error: 'Estado de pago inválido',
                message: `El estado de pago debe ser uno de: ${VALID_PAYMENT_STATUSES.join(', ')}`,
                validPaymentStatuses: VALID_PAYMENT_STATUSES,
                received: paymentStatus,
            });
        }
    }
    next();
};
exports.validatePaymentStatus = validatePaymentStatus;
/**
 * Validates date range parameters
 */
const validateDateRange = (req, res, next) => {
    const { startDate, endDate } = req.query;
    if (startDate && typeof startDate === 'string') {
        const start = new Date(startDate);
        if (isNaN(start.getTime())) {
            return res.status(400).json({
                error: 'Fecha de inicio inválida',
                message: 'La fecha de inicio debe estar en formato ISO 8601 (YYYY-MM-DD)',
                received: startDate,
                expectedFormat: 'YYYY-MM-DD',
            });
        }
        // Check if start date is not too far in the past (more than 2 years)
        const twoYearsAgo = new Date();
        twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);
        if (start < twoYearsAgo) {
            return res.status(400).json({
                error: 'Fecha de inicio muy antigua',
                message: 'La fecha de inicio no puede ser anterior a 2 años',
                received: startDate,
                minimumDate: twoYearsAgo.toISOString().split('T')[0],
            });
        }
    }
    if (endDate && typeof endDate === 'string') {
        const end = new Date(endDate);
        if (isNaN(end.getTime())) {
            return res.status(400).json({
                error: 'Fecha de fin inválida',
                message: 'La fecha de fin debe estar en formato ISO 8601 (YYYY-MM-DD)',
                received: endDate,
                expectedFormat: 'YYYY-MM-DD',
            });
        }
        // Check if end date is not in the future
        const now = new Date();
        if (end > now) {
            return res.status(400).json({
                error: 'Fecha de fin en el futuro',
                message: 'La fecha de fin no puede ser posterior a hoy',
                received: endDate,
                maximumDate: now.toISOString().split('T')[0],
            });
        }
    }
    // Check if start date is before end date
    if (startDate && endDate && typeof startDate === 'string' && typeof endDate === 'string') {
        const start = new Date(startDate);
        const end = new Date(endDate);
        if (start >= end) {
            return res.status(400).json({
                error: 'Rango de fechas inválido',
                message: 'La fecha de inicio debe ser anterior a la fecha de fin',
                startDate,
                endDate,
            });
        }
        // Check if date range is not too large (more than 1 year)
        const oneYear = 365 * 24 * 60 * 60 * 1000; // milliseconds
        if (end.getTime() - start.getTime() > oneYear) {
            return res.status(400).json({
                error: 'Rango de fechas muy amplio',
                message: 'El rango de fechas no puede ser mayor a 1 año',
                startDate,
                endDate,
                maximumRange: '1 año',
            });
        }
    }
    next();
};
exports.validateDateRange = validateDateRange;
/**
 * Validates limit and offset parameters for pagination
 */
const validatePagination = (req, res, next) => {
    const { limit, offset } = req.query;
    if (limit && typeof limit === 'string') {
        const limitNum = parseInt(limit, 10);
        if (isNaN(limitNum) || limitNum < 1 || limitNum > 1000) {
            return res.status(400).json({
                error: 'Límite inválido',
                message: 'El límite debe ser un número entre 1 y 1000',
                received: limit,
                validRange: '1-1000',
            });
        }
    }
    if (offset && typeof offset === 'string') {
        const offsetNum = parseInt(offset, 10);
        if (isNaN(offsetNum) || offsetNum < 0) {
            return res.status(400).json({
                error: 'Offset inválido',
                message: 'El offset debe ser un número mayor o igual a 0',
                received: offset,
                validRange: '>= 0',
            });
        }
    }
    next();
};
exports.validatePagination = validatePagination;
/**
 * Validates sort parameters
 */
const validateSort = (req, res, next) => {
    const { sortBy, sortOrder } = req.query;
    if (sortBy && typeof sortBy === 'string') {
        const validSortFields = ['date', 'amount', 'status', 'serviceType', 'createdAt'];
        if (!validSortFields.includes(sortBy)) {
            return res.status(400).json({
                error: 'Campo de ordenamiento inválido',
                message: `El campo de ordenamiento debe ser uno de: ${validSortFields.join(', ')}`,
                validSortFields,
                received: sortBy,
            });
        }
    }
    if (sortOrder && typeof sortOrder === 'string') {
        if (!['asc', 'desc'].includes(sortOrder.toLowerCase())) {
            return res.status(400).json({
                error: 'Orden de clasificación inválido',
                message: 'El orden debe ser "asc" o "desc"',
                validOrders: ['asc', 'desc'],
                received: sortOrder,
            });
        }
    }
    next();
};
exports.validateSort = validateSort;
/**
 * Comprehensive validation for analytics endpoints
 */
const validateAnalyticsQuery = (req, res, next) => {
    // Validate all query parameters
    const validationErrors = [];
    // Check for unknown parameters
    const validParams = [
        'period', 'serviceType', 'status', 'paymentStatus',
        'startDate', 'endDate', 'limit', 'offset', 'sortBy', 'sortOrder'
    ];
    const queryParams = Object.keys(req.query);
    const unknownParams = queryParams.filter(param => !validParams.includes(param));
    if (unknownParams.length > 0) {
        validationErrors.push(`Parámetros desconocidos: ${unknownParams.join(', ')}`);
    }
    // Check for required parameters based on endpoint
    const path = req.path;
    if (path.includes('/overview') && !req.query.period) {
        // Period is optional for overview, default to 'month'
        req.query.period = 'month';
    }
    if (validationErrors.length > 0) {
        return res.status(400).json({
            error: 'Parámetros de consulta inválidos',
            message: 'Se encontraron errores en los parámetros de la consulta',
            errors: validationErrors,
            validParameters: validParams,
        });
    }
    next();
};
exports.validateAnalyticsQuery = validateAnalyticsQuery;
/**
 * Sanitizes query parameters to prevent injection attacks
 */
const sanitizeQueryParams = (req, res, next) => {
    const sanitizedQuery = {};
    for (const [key, value] of Object.entries(req.query)) {
        if (typeof value === 'string') {
            // Remove any potentially dangerous characters
            sanitizedQuery[key] = value.replace(/[<>\"'%;()&+]/g, '');
        }
        else {
            sanitizedQuery[key] = value;
        }
    }
    req.query = sanitizedQuery;
    next();
};
exports.sanitizeQueryParams = sanitizeQueryParams;
/**
 * Rate limiting for analytics endpoints
 */
const requestCounts = new Map();
const rateLimitAnalytics = (req, res, next) => {
    const clientId = req.ip || 'unknown';
    const now = Date.now();
    const windowMs = 60 * 1000; // 1 minute
    const maxRequests = 30; // 30 requests per minute
    const clientData = requestCounts.get(clientId);
    if (!clientData || now > clientData.resetTime) {
        // Reset or initialize
        requestCounts.set(clientId, {
            count: 1,
            resetTime: now + windowMs,
        });
        next();
    }
    else if (clientData.count < maxRequests) {
        // Increment count
        clientData.count++;
        next();
    }
    else {
        // Rate limit exceeded
        return res.status(429).json({
            error: 'Límite de solicitudes excedido',
            message: `Máximo ${maxRequests} solicitudes por minuto`,
            retryAfter: Math.ceil((clientData.resetTime - now) / 1000),
        });
    }
};
exports.rateLimitAnalytics = rateLimitAnalytics;
//# sourceMappingURL=analyticsValidation.js.map