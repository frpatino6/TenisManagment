/**
 * Tests unitarios para MongoMessageRepository
 * TS-014: Testing de Repositorios - Messaging
 */

import { MongoMessageRepository } from '../../infrastructure/repositories/MongoRepositories';
import { MessageModel } from '../../infrastructure/database/models/MessageModel';
import { Types } from 'mongoose';

// Mock de MessageModel
jest.mock('../../infrastructure/database/models/MessageModel', () => ({
  MessageModel: {
    create: jest.fn(),
    findById: jest.fn(),
    find: jest.fn(),
    findByIdAndUpdate: jest.fn(),
    countDocuments: jest.fn(),
    findByIdAndDelete: jest.fn(),
  },
}));

describe('MongoMessageRepository', () => {
  let repository: MongoMessageRepository;
  let mockMessageModel: jest.Mocked<typeof MessageModel>;

  beforeEach(() => {
    jest.clearAllMocks();
    repository = new MongoMessageRepository();
    mockMessageModel = MessageModel as jest.Mocked<typeof MessageModel>;
  });

  describe('create', () => {
    it('should create a new message successfully', async () => {
      // Arrange
      const messageData = {
        senderId: '507f1f77bcf86cd799439011',
        receiverId: '507f1f77bcf86cd799439012',
        content: 'Hello, how are you?',
        type: 'text' as const,
        status: 'sent' as const,
        conversationId: '507f1f77bcf86cd799439013',
        parentMessageId: undefined,
        attachments: undefined,
      };

      const mockCreatedMessage = {
        _id: new Types.ObjectId('507f1f77bcf86cd799439014'),
        senderId: new Types.ObjectId(messageData.senderId),
        receiverId: new Types.ObjectId(messageData.receiverId),
        content: messageData.content,
        type: messageData.type,
        status: messageData.status,
        conversationId: new Types.ObjectId(messageData.conversationId),
        parentMessageId: undefined,
        attachments: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
        readAt: undefined,
      };

      mockMessageModel.create.mockResolvedValue(mockCreatedMessage as any);

      // Act
      const result = await repository.create(messageData);

      // Assert
      expect(mockMessageModel.create).toHaveBeenCalledWith({
        ...messageData,
        senderId: new Types.ObjectId(messageData.senderId),
        receiverId: new Types.ObjectId(messageData.receiverId),
        conversationId: new Types.ObjectId(messageData.conversationId),
        parentMessageId: undefined,
      });

      expect(result).toEqual({
        id: '507f1f77bcf86cd799439014',
        senderId: messageData.senderId,
        receiverId: messageData.receiverId,
        content: messageData.content,
        type: messageData.type,
        status: messageData.status,
        conversationId: messageData.conversationId,
        parentMessageId: undefined,
        attachments: undefined,
        createdAt: mockCreatedMessage.createdAt,
        updatedAt: mockCreatedMessage.updatedAt,
        readAt: undefined,
      });
    });

    it('should create a message with parent message ID', async () => {
      // Arrange
      const messageData = {
        senderId: '507f1f77bcf86cd799439011',
        receiverId: '507f1f77bcf86cd799439012',
        content: 'This is a reply',
        type: 'text' as const,
        status: 'sent' as const,
        conversationId: '507f1f77bcf86cd799439013',
        parentMessageId: '507f1f77bcf86cd799439015',
        attachments: undefined,
      };

      const mockCreatedMessage = {
        _id: new Types.ObjectId('507f1f77bcf86cd799439014'),
        senderId: new Types.ObjectId(messageData.senderId),
        receiverId: new Types.ObjectId(messageData.receiverId),
        content: messageData.content,
        type: messageData.type,
        status: messageData.status,
        conversationId: new Types.ObjectId(messageData.conversationId),
        parentMessageId: new Types.ObjectId(messageData.parentMessageId),
        attachments: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
        readAt: undefined,
      };

      mockMessageModel.create.mockResolvedValue(mockCreatedMessage as any);

      // Act
      const result = await repository.create(messageData);

      // Assert
      expect(mockMessageModel.create).toHaveBeenCalledWith({
        ...messageData,
        senderId: new Types.ObjectId(messageData.senderId),
        receiverId: new Types.ObjectId(messageData.receiverId),
        conversationId: new Types.ObjectId(messageData.conversationId),
        parentMessageId: new Types.ObjectId(messageData.parentMessageId),
      });

      expect(result.parentMessageId).toBe(messageData.parentMessageId);
    });

    it('should create a message with attachments', async () => {
      // Arrange
      const messageData = {
        senderId: '507f1f77bcf86cd799439011',
        receiverId: '507f1f77bcf86cd799439012',
        content: 'Check this file',
        type: 'text' as const,
        status: 'sent' as const,
        conversationId: '507f1f77bcf86cd799439013',
        parentMessageId: undefined,
        attachments: [
          {
            id: '507f1f77bcf86cd799439016',
            fileName: 'document.pdf',
            fileUrl: 'https://example.com/document.pdf',
            fileType: 'application/pdf',
            fileSize: 1024,
          }
        ],
      };

      const mockCreatedMessage = {
        _id: new Types.ObjectId('507f1f77bcf86cd799439014'),
        senderId: new Types.ObjectId(messageData.senderId),
        receiverId: new Types.ObjectId(messageData.receiverId),
        content: messageData.content,
        type: messageData.type,
        status: messageData.status,
        conversationId: new Types.ObjectId(messageData.conversationId),
        parentMessageId: undefined,
        attachments: [
          {
            _id: new Types.ObjectId('507f1f77bcf86cd799439016'),
            fileName: 'document.pdf',
            fileUrl: 'https://example.com/document.pdf',
            fileType: 'application/pdf',
            fileSize: 1024,
          }
        ],
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
        readAt: undefined,
      };

      mockMessageModel.create.mockResolvedValue(mockCreatedMessage as any);

      // Act
      const result = await repository.create(messageData);

      // Assert
      expect(result.attachments).toHaveLength(1);
      expect(result.attachments![0]).toEqual({
        id: '507f1f77bcf86cd799439016',
        fileName: 'document.pdf',
        fileUrl: 'https://example.com/document.pdf',
        fileType: 'application/pdf',
        fileSize: 1024,
      });
    });
  });

  describe('findById', () => {
    it('should find a message by ID', async () => {
      // Arrange
      const messageId = '507f1f77bcf86cd799439014';
      const mockMessage = {
        _id: new Types.ObjectId(messageId),
        senderId: new Types.ObjectId('507f1f77bcf86cd799439011'),
        receiverId: new Types.ObjectId('507f1f77bcf86cd799439012'),
        content: 'Hello, how are you?',
        type: 'text',
        status: 'sent',
        conversationId: new Types.ObjectId('507f1f77bcf86cd799439013'),
        parentMessageId: undefined,
        attachments: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
        readAt: undefined,
      };

      mockMessageModel.findById.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockMessage)
      } as any);

      // Act
      const result = await repository.findById(messageId);

      // Assert
      expect(mockMessageModel.findById).toHaveBeenCalledWith(messageId);
      expect(result).toEqual({
        id: messageId,
        senderId: '507f1f77bcf86cd799439011',
        receiverId: '507f1f77bcf86cd799439012',
        content: 'Hello, how are you?',
        type: 'text',
        status: 'sent',
        conversationId: '507f1f77bcf86cd799439013',
        parentMessageId: undefined,
        attachments: undefined,
        createdAt: mockMessage.createdAt,
        updatedAt: mockMessage.updatedAt,
        readAt: undefined,
      });
    });

    it('should return null when message not found', async () => {
      // Arrange
      const messageId = '507f1f77bcf86cd799439014';
      mockMessageModel.findById.mockReturnValue({
        lean: jest.fn().mockResolvedValue(null)
      } as any);

      // Act
      const result = await repository.findById(messageId);

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('findByConversation', () => {
    it('should find messages by conversation ID with default pagination', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      const mockMessages = [
        {
          _id: new Types.ObjectId('507f1f77bcf86cd799439014'),
          senderId: new Types.ObjectId('507f1f77bcf86cd799439011'),
          receiverId: new Types.ObjectId('507f1f77bcf86cd799439012'),
          content: 'Message 1',
          type: 'text',
          status: 'sent',
          conversationId: new Types.ObjectId(conversationId),
          parentMessageId: undefined,
          attachments: undefined,
          createdAt: new Date('2023-01-01T00:00:00Z'),
          updatedAt: new Date('2023-01-01T00:00:00Z'),
          readAt: undefined,
        },
        {
          _id: new Types.ObjectId('507f1f77bcf86cd799439015'),
          senderId: new Types.ObjectId('507f1f77bcf86cd799439012'),
          receiverId: new Types.ObjectId('507f1f77bcf86cd799439011'),
          content: 'Message 2',
          type: 'text',
          status: 'sent',
          conversationId: new Types.ObjectId(conversationId),
          parentMessageId: undefined,
          attachments: undefined,
          createdAt: new Date('2023-01-01T01:00:00Z'),
          updatedAt: new Date('2023-01-01T01:00:00Z'),
          readAt: undefined,
        }
      ];

      const mockQuery = {
        sort: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        lean: jest.fn().mockResolvedValue(mockMessages)
      };

      mockMessageModel.find.mockReturnValue(mockQuery as any);

      // Act
      const result = await repository.findByConversation(conversationId);

      // Assert
      expect(mockMessageModel.find).toHaveBeenCalledWith({
        conversationId: new Types.ObjectId(conversationId)
      });
      expect(mockQuery.sort).toHaveBeenCalledWith({ createdAt: -1 });
      expect(mockQuery.limit).toHaveBeenCalledWith(50);
      expect(mockQuery.skip).toHaveBeenCalledWith(0);
      expect(result).toHaveLength(2);
    });

    it('should find messages with custom pagination', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      const limit = 10;
      const offset = 20;

      const mockQuery = {
        sort: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        lean: jest.fn().mockResolvedValue([])
      };

      mockMessageModel.find.mockReturnValue(mockQuery as any);

      // Act
      await repository.findByConversation(conversationId, limit, offset);

      // Assert
      expect(mockQuery.limit).toHaveBeenCalledWith(limit);
      expect(mockQuery.skip).toHaveBeenCalledWith(offset);
    });
  });

  describe('markAsRead', () => {
    it('should mark a message as read', async () => {
      // Arrange
      const messageId = '507f1f77bcf86cd799439014';
      const mockUpdatedMessage = {
        _id: new Types.ObjectId(messageId),
        senderId: new Types.ObjectId('507f1f77bcf86cd799439011'),
        receiverId: new Types.ObjectId('507f1f77bcf86cd799439012'),
        content: 'Hello, how are you?',
        type: 'text',
        status: 'read',
        conversationId: new Types.ObjectId('507f1f77bcf86cd799439013'),
        parentMessageId: undefined,
        attachments: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
        readAt: new Date('2023-01-01T01:00:00Z'),
      };

      mockMessageModel.findByIdAndUpdate.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockUpdatedMessage)
      } as any);

      // Act
      const result = await repository.markAsRead(messageId);

      // Assert
      expect(mockMessageModel.findByIdAndUpdate).toHaveBeenCalledWith(
        messageId,
        {
          status: 'read',
          readAt: expect.any(Date)
        },
        { new: true }
      );
      expect(result?.status).toBe('read');
      expect(result?.readAt).toBeDefined();
    });

    it('should return null when message not found for marking as read', async () => {
      // Arrange
      const messageId = '507f1f77bcf86cd799439014';
      mockMessageModel.findByIdAndUpdate.mockReturnValue({
        lean: jest.fn().mockResolvedValue(null)
      } as any);

      // Act
      const result = await repository.markAsRead(messageId);

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('markAsDelivered', () => {
    it('should mark a message as delivered', async () => {
      // Arrange
      const messageId = '507f1f77bcf86cd799439014';
      const mockUpdatedMessage = {
        _id: new Types.ObjectId(messageId),
        senderId: new Types.ObjectId('507f1f77bcf86cd799439011'),
        receiverId: new Types.ObjectId('507f1f77bcf86cd799439012'),
        content: 'Hello, how are you?',
        type: 'text',
        status: 'delivered',
        conversationId: new Types.ObjectId('507f1f77bcf86cd799439013'),
        parentMessageId: undefined,
        attachments: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
        readAt: undefined,
      };

      mockMessageModel.findByIdAndUpdate.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockUpdatedMessage)
      } as any);

      // Act
      const result = await repository.markAsDelivered(messageId);

      // Assert
      expect(mockMessageModel.findByIdAndUpdate).toHaveBeenCalledWith(
        messageId,
        { status: 'delivered' },
        { new: true }
      );
      expect(result?.status).toBe('delivered');
    });
  });

  describe('getUnreadCount', () => {
    it('should return unread message count for a user', async () => {
      // Arrange
      const userId = '507f1f77bcf86cd799439011';
      const expectedCount = 5;

      mockMessageModel.countDocuments.mockResolvedValue(expectedCount);

      // Act
      const result = await repository.getUnreadCount(userId);

      // Assert
      expect(mockMessageModel.countDocuments).toHaveBeenCalledWith({
        receiverId: new Types.ObjectId(userId),
        status: { $in: ['sent', 'delivered'] }
      });
      expect(result).toBe(expectedCount);
    });

    it('should return 0 when user has no unread messages', async () => {
      // Arrange
      const userId = '507f1f77bcf86cd799439011';
      mockMessageModel.countDocuments.mockResolvedValue(0);

      // Act
      const result = await repository.getUnreadCount(userId);

      // Assert
      expect(result).toBe(0);
    });
  });

  describe('delete', () => {
    it('should delete a message by ID', async () => {
      // Arrange
      const messageId = '507f1f77bcf86cd799439014';
      mockMessageModel.findByIdAndDelete.mockResolvedValue({} as any);

      // Act
      await repository.delete(messageId);

      // Assert
      expect(mockMessageModel.findByIdAndDelete).toHaveBeenCalledWith(messageId);
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty conversation messages', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      const mockQuery = {
        sort: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        lean: jest.fn().mockResolvedValue([])
      };

      mockMessageModel.find.mockReturnValue(mockQuery as any);

      // Act
      const result = await repository.findByConversation(conversationId);

      // Assert
      expect(result).toEqual([]);
    });

    it('should handle invalid ObjectId gracefully', async () => {
      // Arrange
      const invalidId = 'invalid-id';
      mockMessageModel.findById.mockReturnValue({
        lean: jest.fn().mockResolvedValue(null)
      } as any);

      // Act
      const result = await repository.findById(invalidId);

      // Assert
      expect(result).toBeNull();
    });
  });
});
