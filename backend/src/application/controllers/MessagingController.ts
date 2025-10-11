import { Request, Response } from 'express';
import { z } from 'zod';
import {
  SendMessageUseCaseImpl,
  GetConversationUseCaseImpl,
  GetConversationsUseCaseImpl,
  GetMessagesUseCaseImpl,
  MarkMessageAsReadUseCaseImpl,
  GetUnreadCountUseCaseImpl,
  CreateConversationUseCaseImpl,
} from '../../domain/use-cases/MessageUseCases';
import { MessageRepository, ConversationRepository } from '../../domain/repositories/index';

// DTOs con Zod
const SendMessageSchema = z.object({
  receiverId: z.string().min(1, 'receiverId is required'),
  content: z.string().min(1, 'content is required').max(5000, 'content too long'),
  type: z.enum(['text', 'image', 'file', 'system']).optional().default('text'),
  parentMessageId: z.string().optional(),
  attachments: z
    .array(
      z.object({
        fileName: z.string(),
        fileUrl: z.string().url(),
        fileType: z.string(),
        fileSize: z.number().positive(),
      }),
    )
    .optional(),
});

const GetMessagesSchema = z.object({
  conversationId: z.string().min(1, 'conversationId is required'),
  limit: z.coerce.number().int().positive().max(100).optional().default(50),
  offset: z.coerce.number().int().nonnegative().optional().default(0),
});

const CreateConversationSchema = z.object({
  participants: z
    .array(
      z.object({
        userId: z.string(),
        userType: z.enum(['professor', 'student']),
      }),
    )
    .min(2, 'At least 2 participants required'),
});

export class MessagingController {
  private sendMessageUseCase: SendMessageUseCaseImpl;
  private getConversationUseCase: GetConversationUseCaseImpl;
  private getConversationsUseCase: GetConversationsUseCaseImpl;
  private getMessagesUseCase: GetMessagesUseCaseImpl;
  private markMessageAsReadUseCase: MarkMessageAsReadUseCaseImpl;
  private getUnreadCountUseCase: GetUnreadCountUseCaseImpl;
  private createConversationUseCase: CreateConversationUseCaseImpl;

  constructor(
    private messageRepository: MessageRepository,
    private conversationRepository: ConversationRepository,
  ) {
    this.sendMessageUseCase = new SendMessageUseCaseImpl(
      messageRepository,
      conversationRepository,
    );
    this.getConversationUseCase = new GetConversationUseCaseImpl(conversationRepository);
    this.getConversationsUseCase = new GetConversationsUseCaseImpl(conversationRepository);
    this.getMessagesUseCase = new GetMessagesUseCaseImpl(messageRepository);
    this.markMessageAsReadUseCase = new MarkMessageAsReadUseCaseImpl(messageRepository);
    this.getUnreadCountUseCase = new GetUnreadCountUseCaseImpl(messageRepository);
    this.createConversationUseCase = new CreateConversationUseCaseImpl(conversationRepository);
  }

  /**
   * POST /api/messaging/send
   * Enviar un mensaje a otro usuario
   */
  sendMessage = async (req: Request, res: Response) => {
    try {
      const parsed = SendMessageSchema.safeParse(req.body);
      if (!parsed.success) {
        return res.status(400).json({
          error: 'Invalid request body',
          details: parsed.error.errors,
        });
      }

      const userId = (req as any).user?.sub; // ID del usuario autenticado
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const message = await this.sendMessageUseCase.execute({
        senderId: userId,
        receiverId: parsed.data.receiverId,
        content: parsed.data.content,
        type: parsed.data.type,
        parentMessageId: parsed.data.parentMessageId,
        attachments: parsed.data.attachments,
      });

      return res.status(201).json({
        success: true,
        message: {
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          content: message.content,
          type: message.type,
          status: message.status,
          conversationId: message.conversationId,
          createdAt: message.createdAt,
        },
      });
    } catch (error: any) {
      console.error('Error sending message:', error);
      return res.status(500).json({
        error: 'Failed to send message',
        message: error.message,
      });
    }
  };

  /**
   * GET /api/messaging/conversations
   * Obtener todas las conversaciones del usuario autenticado
   */
  getConversations = async (req: Request, res: Response) => {
    try {
      const userId = (req as any).user?.sub;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const conversations = await this.getConversationsUseCase.execute(userId);

      return res.json({
        success: true,
        conversations,
        total: conversations.length,
      });
    } catch (error: any) {
      console.error('Error getting conversations:', error);
      return res.status(500).json({
        error: 'Failed to get conversations',
        message: error.message,
      });
    }
  };

  /**
   * GET /api/messaging/conversations/:conversationId/messages
   * Obtener mensajes de una conversación específica
   */
  getMessages = async (req: Request, res: Response) => {
    try {
      const userId = (req as any).user?.sub;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const parsed = GetMessagesSchema.safeParse({
        conversationId: req.params.conversationId,
        limit: req.query.limit,
        offset: req.query.offset,
      });

      if (!parsed.success) {
        return res.status(400).json({
          error: 'Invalid request parameters',
          details: parsed.error.errors,
        });
      }

      const messages = await this.getMessagesUseCase.execute({
        conversationId: parsed.data.conversationId,
        limit: parsed.data.limit,
        offset: parsed.data.offset,
      });

      return res.json({
        success: true,
        messages,
        total: messages.length,
        limit: parsed.data.limit,
        offset: parsed.data.offset,
      });
    } catch (error: any) {
      console.error('Error getting messages:', error);
      return res.status(500).json({
        error: 'Failed to get messages',
        message: error.message,
      });
    }
  };

  /**
   * GET /api/messaging/conversation/:otherUserId
   * Obtener conversación entre el usuario actual y otro usuario
   */
  getConversation = async (req: Request, res: Response) => {
    try {
      const userId = (req as any).user?.sub;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { otherUserId } = req.params;
      if (!otherUserId) {
        return res.status(400).json({ error: 'otherUserId is required' });
      }

      const conversation = await this.getConversationUseCase.execute({
        userId1: userId,
        userId2: otherUserId,
      });

      if (!conversation) {
        return res.status(404).json({
          success: false,
          message: 'Conversation not found',
        });
      }

      return res.json({
        success: true,
        conversation,
      });
    } catch (error: any) {
      console.error('Error getting conversation:', error);
      return res.status(500).json({
        error: 'Failed to get conversation',
        message: error.message,
      });
    }
  };

  /**
   * PATCH /api/messaging/messages/:messageId/read
   * Marcar un mensaje como leído
   */
  markAsRead = async (req: Request, res: Response) => {
    try {
      const userId = (req as any).user?.sub;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { messageId } = req.params;
      if (!messageId) {
        return res.status(400).json({ error: 'messageId is required' });
      }

      const message = await this.markMessageAsReadUseCase.execute(messageId);

      if (!message) {
        return res.status(404).json({
          success: false,
          message: 'Message not found',
        });
      }

      return res.json({
        success: true,
        message,
      });
    } catch (error: any) {
      console.error('Error marking message as read:', error);
      return res.status(500).json({
        error: 'Failed to mark message as read',
        message: error.message,
      });
    }
  };

  /**
   * GET /api/messaging/unread-count
   * Obtener contador de mensajes no leídos
   */
  getUnreadCount = async (req: Request, res: Response) => {
    try {
      const userId = (req as any).user?.sub;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const count = await this.getUnreadCountUseCase.execute(userId);

      return res.json({
        success: true,
        unreadCount: count,
      });
    } catch (error: any) {
      console.error('Error getting unread count:', error);
      return res.status(500).json({
        error: 'Failed to get unread count',
        message: error.message,
      });
    }
  };

  /**
   * POST /api/messaging/conversations
   * Crear una nueva conversación
   */
  createConversation = async (req: Request, res: Response) => {
    try {
      const parsed = CreateConversationSchema.safeParse(req.body);
      if (!parsed.success) {
        return res.status(400).json({
          error: 'Invalid request body',
          details: parsed.error.errors,
        });
      }

      const userId = (req as any).user?.sub;
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const conversation = await this.createConversationUseCase.execute({
        participants: parsed.data.participants,
      });

      return res.status(201).json({
        success: true,
        conversation,
      });
    } catch (error: any) {
      console.error('Error creating conversation:', error);
      return res.status(500).json({
        error: 'Failed to create conversation',
        message: error.message,
      });
    }
  };
}

