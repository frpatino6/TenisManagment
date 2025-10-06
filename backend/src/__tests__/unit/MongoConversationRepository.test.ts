/**
 * Tests unitarios para MongoConversationRepository
 * TS-014: Testing de Repositorios - Messaging
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { MongoConversationRepository } from '../../infrastructure/repositories/MongoRepositories';
import { ConversationModel } from '../../infrastructure/database/models/ConversationModel';
import { Types } from 'mongoose';

// Mock de ConversationModel
jest.mock('../../infrastructure/database/models/ConversationModel', () => ({
  ConversationModel: {
    create: jest.fn(),
    findById: jest.fn(),
    find: jest.fn(),
    findOne: jest.fn(),
    findByIdAndUpdate: jest.fn(),
  },
}));

describe('MongoConversationRepository', () => {
  let repository: MongoConversationRepository;
  let mockConversationModel: jest.Mocked<typeof ConversationModel>;

  beforeEach(() => {
    jest.clearAllMocks();
    repository = new MongoConversationRepository();
    mockConversationModel = ConversationModel as jest.Mocked<typeof ConversationModel>;
  });

  describe('create', () => {
    it('should create a new conversation successfully', async () => {
      // Arrange
      const conversationData = {
        participants: [
          {
            userId: '507f1f77bcf86cd799439011',
            userType: 'student' as const,
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          },
          {
            userId: '507f1f77bcf86cd799439012',
            userType: 'professor' as const,
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          }
        ],
        lastMessage: undefined,
        lastMessageAt: undefined,
      };

      const mockCreatedConversation = {
        _id: new Types.ObjectId('507f1f77bcf86cd799439013'),
        participants: [
          {
            userId: new Types.ObjectId('507f1f77bcf86cd799439011'),
            userType: 'student',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          },
          {
            userId: new Types.ObjectId('507f1f77bcf86cd799439012'),
            userType: 'professor',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          }
        ],
        lastMessage: undefined,
        lastMessageAt: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
      };

      mockConversationModel.create.mockResolvedValue(mockCreatedConversation as any);

      // Act
      const result = await repository.create(conversationData);

      // Assert
      expect(mockConversationModel.create).toHaveBeenCalledWith({
        ...conversationData,
        participants: conversationData.participants.map(p => ({
          ...p,
          userId: new Types.ObjectId(p.userId),
          joinedAt: expect.any(Date),
        })),
      });

      expect(result).toEqual({
        id: '507f1f77bcf86cd799439013',
        participants: [
          {
            userId: '507f1f77bcf86cd799439011',
            userType: 'student',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          },
          {
            userId: '507f1f77bcf86cd799439012',
            userType: 'professor',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          }
        ],
        lastMessage: undefined,
        lastMessageAt: undefined,
        createdAt: mockCreatedConversation.createdAt,
        updatedAt: mockCreatedConversation.updatedAt,
      });
    });
  });

  describe('findById', () => {
    it('should find a conversation by ID', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      const mockConversation = {
        _id: new Types.ObjectId(conversationId),
        participants: [
          {
            userId: new Types.ObjectId('507f1f77bcf86cd799439011'),
            userType: 'student',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          }
        ],
        lastMessage: new Types.ObjectId('507f1f77bcf86cd799439014'),
        lastMessageAt: new Date('2023-01-01T01:00:00Z'),
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
      };

      mockConversationModel.findById.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockConversation as any)
      } as any);

      // Act
      const result = await repository.findById(conversationId);

      // Assert
      expect(mockConversationModel.findById).toHaveBeenCalledWith(conversationId);
      expect(result).toEqual({
        id: conversationId,
        participants: [
          {
            userId: '507f1f77bcf86cd799439011',
            userType: 'student',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          }
        ],
        lastMessage: {
          id: '507f1f77bcf86cd799439014',
          senderId: '',
          receiverId: '',
          content: '',
          type: 'text',
          status: 'sent',
          conversationId: conversationId,
          createdAt: expect.any(Date),
        },
        lastMessageAt: new Date('2023-01-01T01:00:00Z'),
        createdAt: mockConversation.createdAt,
        updatedAt: mockConversation.updatedAt,
      });
    });

    it('should return null when conversation not found', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      mockConversationModel.findById.mockReturnValue({
        lean: jest.fn().mockResolvedValue(null as any)
      } as any);

      // Act
      const result = await repository.findById(conversationId);

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('findByParticipant', () => {
    it('should find conversations by participant user ID', async () => {
      // Arrange
      const userId = '507f1f77bcf86cd799439011';
      const mockConversations = [
        {
          _id: new Types.ObjectId('507f1f77bcf86cd799439013'),
          participants: [
            {
              userId: new Types.ObjectId(userId),
              userType: 'student',
              joinedAt: new Date('2023-01-01T00:00:00Z'),
              leftAt: undefined,
              isActive: true,
            }
          ],
          lastMessage: undefined,
          lastMessageAt: new Date('2023-01-01T01:00:00Z'),
          createdAt: new Date('2023-01-01T00:00:00Z'),
          updatedAt: new Date('2023-01-01T00:00:00Z'),
        }
      ];

      const mockQuery = {
        sort: jest.fn().mockReturnThis(),
        lean: jest.fn().mockResolvedValue(mockConversations as any)
      };

      mockConversationModel.find.mockReturnValue(mockQuery as any);

      // Act
      const result = await repository.findByParticipant(userId);

      // Assert
      expect(mockConversationModel.find).toHaveBeenCalledWith({
        'participants.userId': new Types.ObjectId(userId),
        'participants.isActive': true
      });
      expect(mockQuery.sort).toHaveBeenCalledWith({ lastMessageAt: -1 });
      expect(result).toHaveLength(1);
    });

    it('should return empty array when no conversations found', async () => {
      // Arrange
      const userId = '507f1f77bcf86cd799439011';
      const mockQuery = {
        sort: jest.fn().mockReturnThis(),
        lean: jest.fn().mockResolvedValue([] as any)
      };

      mockConversationModel.find.mockReturnValue(mockQuery as any);

      // Act
      const result = await repository.findByParticipant(userId);

      // Assert
      expect(result).toEqual([]);
    });
  });

  describe('findByParticipants', () => {
    it('should find conversation between two specific participants', async () => {
      // Arrange
      const userId1 = '507f1f77bcf86cd799439011';
      const userId2 = '507f1f77bcf86cd799439012';
      const mockConversation = {
        _id: new Types.ObjectId('507f1f77bcf86cd799439013'),
        participants: [
          {
            userId: new Types.ObjectId(userId1),
            userType: 'student',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          },
          {
            userId: new Types.ObjectId(userId2),
            userType: 'professor',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: undefined,
            isActive: true,
          }
        ],
        lastMessage: undefined,
        lastMessageAt: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
      };

      mockConversationModel.findOne.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockConversation as any)
      } as any);

      // Act
      const result = await repository.findByParticipants(userId1, userId2);

      // Assert
      expect(mockConversationModel.findOne).toHaveBeenCalledWith({
        'participants.userId': {
          $all: [new Types.ObjectId(userId1), new Types.ObjectId(userId2)]
        },
        'participants.isActive': true
      });
      expect(result).toBeDefined();
      expect(result?.id).toBe('507f1f77bcf86cd799439013');
    });

    it('should return null when no conversation found between participants', async () => {
      // Arrange
      const userId1 = '507f1f77bcf86cd799439011';
      const userId2 = '507f1f77bcf86cd799439012';
      mockConversationModel.findOne.mockReturnValue({
        lean: jest.fn().mockResolvedValue(null as any)
      } as any);

      // Act
      const result = await repository.findByParticipants(userId1, userId2);

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('updateLastMessage', () => {
    it('should update last message in conversation', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      const message = {
        id: '507f1f77bcf86cd799439014',
        senderId: '507f1f77bcf86cd799439011',
        receiverId: '507f1f77bcf86cd799439012',
        content: 'Hello',
        type: 'text' as const,
        status: 'sent' as const,
        conversationId: conversationId,
        parentMessageId: undefined,
        attachments: undefined,
        createdAt: new Date('2023-01-01T01:00:00Z'),
        updatedAt: new Date('2023-01-01T01:00:00Z'),
        readAt: undefined,
      };

      const mockUpdatedConversation = {
        _id: new Types.ObjectId(conversationId),
        participants: [],
        lastMessage: new Types.ObjectId(message.id),
        lastMessageAt: message.createdAt,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T01:00:00Z'),
      };

      mockConversationModel.findByIdAndUpdate.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockUpdatedConversation as any)
      } as any);

      // Act
      const result = await repository.updateLastMessage(conversationId, message);

      // Assert
      expect(mockConversationModel.findByIdAndUpdate).toHaveBeenCalledWith(
        conversationId,
        {
          lastMessage: new Types.ObjectId(message.id),
          lastMessageAt: message.createdAt
        },
        { new: true }
      );
      expect(result).toBeDefined();
    });
  });

  describe('addParticipant', () => {
    it('should add a new participant to conversation', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      const participant = {
        userId: '507f1f77bcf86cd799439015',
        userType: 'student' as const,
        joinedAt: new Date('2023-01-01T00:00:00Z'),
        leftAt: undefined,
        isActive: true,
      };

      const mockUpdatedConversation = {
        _id: new Types.ObjectId(conversationId),
        participants: [
          {
            userId: new Types.ObjectId(participant.userId),
            userType: participant.userType,
            joinedAt: expect.any(Date),
            leftAt: undefined,
            isActive: true,
          }
        ],
        lastMessage: undefined,
        lastMessageAt: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
      };

      mockConversationModel.findByIdAndUpdate.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockUpdatedConversation as any)
      } as any);

      // Act
      const result = await repository.addParticipant(conversationId, participant);

      // Assert
      expect(mockConversationModel.findByIdAndUpdate).toHaveBeenCalledWith(
        conversationId,
        {
          $push: {
            participants: {
              ...participant,
              userId: new Types.ObjectId(participant.userId),
              joinedAt: expect.any(Date),
              isActive: true
            }
          }
        },
        { new: true }
      );
      expect(result).toBeDefined();
    });
  });

  describe('removeParticipant', () => {
    it('should remove a participant from conversation', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      const userId = '507f1f77bcf86cd799439011';

      const mockUpdatedConversation = {
        _id: new Types.ObjectId(conversationId),
        participants: [
          {
            userId: new Types.ObjectId(userId),
            userType: 'student',
            joinedAt: new Date('2023-01-01T00:00:00Z'),
            leftAt: expect.any(Date),
            isActive: false,
          }
        ],
        lastMessage: undefined,
        lastMessageAt: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T01:00:00Z'),
      };

      mockConversationModel.findByIdAndUpdate.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockUpdatedConversation as any)
      } as any);

      // Act
      const result = await repository.removeParticipant(conversationId, userId);

      // Assert
      expect(mockConversationModel.findByIdAndUpdate).toHaveBeenCalledWith(
        conversationId,
        {
          $set: {
            'participants.$[elem].isActive': false,
            'participants.$[elem].leftAt': expect.any(Date)
          }
        },
        {
          arrayFilters: [{ 'elem.userId': new Types.ObjectId(userId) }],
          new: true
        }
      );
      expect(result).toBeDefined();
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty conversations list', async () => {
      // Arrange
      const userId = '507f1f77bcf86cd799439011';
      const mockQuery = {
        sort: jest.fn().mockReturnThis(),
        lean: jest.fn().mockResolvedValue([] as any)
      };

      mockConversationModel.find.mockReturnValue(mockQuery as any);

      // Act
      const result = await repository.findByParticipant(userId);

      // Assert
      expect(result).toEqual([]);
    });

    it('should handle conversation with no last message', async () => {
      // Arrange
      const conversationId = '507f1f77bcf86cd799439013';
      const mockConversation = {
        _id: new Types.ObjectId(conversationId),
        participants: [],
        lastMessage: undefined,
        lastMessageAt: undefined,
        createdAt: new Date('2023-01-01T00:00:00Z'),
        updatedAt: new Date('2023-01-01T00:00:00Z'),
      };

      mockConversationModel.findById.mockReturnValue({
        lean: jest.fn().mockResolvedValue(mockConversation as any)
      } as any);

      // Act
      const result = await repository.findById(conversationId);

      // Assert
      expect(result?.lastMessage).toBeUndefined();
    });

    it('should handle invalid ObjectId gracefully', async () => {
      // Arrange
      const invalidId = 'invalid-id';
      mockConversationModel.findById.mockReturnValue({
        lean: jest.fn().mockResolvedValue(null as any)
      } as any);

      // Act
      const result = await repository.findById(invalidId);

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('Performance Tests', () => {
    it('should handle large number of conversations efficiently', async () => {
      // Arrange
      const userId = '507f1f77bcf86cd799439011';
      const largeConversationList = Array.from({ length: 1000 }, (_, i) => ({
        _id: new Types.ObjectId(),
        participants: [
          {
            userId: new Types.ObjectId(userId),
            userType: 'student',
            joinedAt: new Date(),
            leftAt: undefined,
            isActive: true,
          }
        ],
        lastMessage: undefined,
        lastMessageAt: new Date(),
        createdAt: new Date(),
        updatedAt: new Date(),
      }));

      const mockQuery = {
        sort: jest.fn().mockReturnThis(),
        lean: jest.fn().mockResolvedValue(largeConversationList as any)
      };

      mockConversationModel.find.mockReturnValue(mockQuery as any);

      // Act
      const startTime = Date.now();
      const result = await repository.findByParticipant(userId);
      const endTime = Date.now();

      // Assert
      expect(result).toHaveLength(1000);
      expect(endTime - startTime).toBeLessThan(1000); // Should complete within 1 second
    });
  });
});
