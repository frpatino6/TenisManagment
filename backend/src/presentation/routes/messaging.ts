import { Router } from 'express';
import { MessagingController } from '../../application/controllers/MessagingController';
import { MongoMessageRepository } from '../../infrastructure/repositories/MessageRepository';
import { MongoConversationRepository } from '../../infrastructure/repositories/ConversationRepository';
import { authMiddleware } from '../../application/middleware/auth';
import rateLimit from 'express-rate-limit';
import { config } from '../../infrastructure/config';

const router = Router();

// Repositories
const messageRepository = new MongoMessageRepository();
const conversationRepository = new MongoConversationRepository();

// Controller
const controller = new MessagingController(messageRepository, conversationRepository);

// Rate limiter for messaging endpoints
const messagingLimiter = rateLimit({
  windowMs: config.http.rateLimit.windowMs,
  max: config.http.rateLimit.max,
  message: 'Too many requests from this IP, please try again later.',
});

// Apply authentication and rate limiting to all routes
router.use(authMiddleware);
router.use(messagingLimiter);

/**
 * @route   POST /api/messaging/send
 * @desc    Send a message to another user
 * @access  Authenticated
 */
router.post('/send', controller.sendMessage);

/**
 * @route   GET /api/messaging/conversations
 * @desc    Get all conversations for authenticated user
 * @access  Authenticated
 */
router.get('/conversations', controller.getConversations);

/**
 * @route   GET /api/messaging/conversations/:conversationId/messages
 * @desc    Get messages from a specific conversation
 * @access  Authenticated
 */
router.get('/conversations/:conversationId/messages', controller.getMessages);

/**
 * @route   GET /api/messaging/conversation/:otherUserId
 * @desc    Get conversation between authenticated user and another user
 * @access  Authenticated
 */
router.get('/conversation/:otherUserId', controller.getConversation);

/**
 * @route   PATCH /api/messaging/messages/:messageId/read
 * @desc    Mark a message as read
 * @access  Authenticated
 */
router.patch('/messages/:messageId/read', controller.markAsRead);

/**
 * @route   GET /api/messaging/unread-count
 * @desc    Get count of unread messages for authenticated user
 * @access  Authenticated
 */
router.get('/unread-count', controller.getUnreadCount);

/**
 * @route   POST /api/messaging/conversations
 * @desc    Create a new conversation
 * @access  Authenticated
 */
router.post('/conversations', controller.createConversation);

export default router;

