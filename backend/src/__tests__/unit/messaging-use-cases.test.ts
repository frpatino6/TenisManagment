/**
 * Tests unitarios para Messaging Use Cases
 * TEN-62: TS-006 - Testing de Use Cases - Messaging
 */

import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import {
  SendMessageUseCaseImpl,
  GetConversationUseCaseImpl,
  GetConversationsUseCaseImpl,
  GetMessagesUseCaseImpl,
  MarkMessageAsReadUseCaseImpl,
  GetUnreadCountUseCaseImpl,
  CreateConversationUseCaseImpl
} from '../../domain/use-cases/MessageUseCases';
import { TestDataFactory } from '../utils/test-helpers';

describe('Messaging Use Cases', () => {
  
  describe('SendMessageUseCase', () => {
    let useCase: SendMessageUseCaseImpl;
    let mockMessageRepo: any;
    let mockConversationRepo: any;

    beforeEach(() => {
      mockMessageRepo = {
        create: jest.fn(),
        findByConversation: jest.fn(),
        markAsRead: jest.fn(),
        getUnreadCount: jest.fn()
      };

      mockConversationRepo = {
        findByParticipants: jest.fn(),
        create: jest.fn(),
        updateLastMessage: jest.fn()
      };

      useCase = new SendMessageUseCaseImpl(mockMessageRepo, mockConversationRepo);
    });

    it('should send message in existing conversation', async () => {
      const conversation = { id: 'conv-1', participants: [] };
      const message = TestDataFactory.createMessage();

      mockConversationRepo.findByParticipants.mockResolvedValue(conversation);
      mockMessageRepo.create.mockResolvedValue(message);

      const result = await useCase.execute({
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        content: 'Hello'
      });

      expect(mockConversationRepo.findByParticipants).toHaveBeenCalled();
      expect(mockMessageRepo.create).toHaveBeenCalled();
      expect(mockConversationRepo.updateLastMessage).toHaveBeenCalled();
      expect(result).toEqual(message);
    });

    it('should create new conversation if not exists', async () => {
      const newConversation = { id: 'conv-new', participants: [] };
      const message = TestDataFactory.createMessage();

      mockConversationRepo.findByParticipants.mockResolvedValue(null);
      mockConversationRepo.create.mockResolvedValue(newConversation);
      mockMessageRepo.create.mockResolvedValue(message);

      await useCase.execute({
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        content: 'First message'
      });

      expect(mockConversationRepo.create).toHaveBeenCalled();
      expect(mockMessageRepo.create).toHaveBeenCalled();
    });

    it('should default to text type', async () => {
      mockConversationRepo.findByParticipants.mockResolvedValue({ id: 'conv-1' });
      mockMessageRepo.create.mockResolvedValue(TestDataFactory.createMessage());

      await useCase.execute({
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        content: 'Test'
      });

      const createCall = mockMessageRepo.create.mock.calls[0][0];
      expect(createCall.type).toBe('text');
    });
  });

  describe('GetConversationUseCase', () => {
    let useCase: GetConversationUseCaseImpl;
    let mockConversationRepo: any;

    beforeEach(() => {
      mockConversationRepo = {
        findByParticipants: jest.fn()
      };

      useCase = new GetConversationUseCaseImpl(mockConversationRepo);
    });

    it('should get existing conversation', async () => {
      const conversation = { id: 'conv-1', participants: [] };
      mockConversationRepo.findByParticipants.mockResolvedValue(conversation);

      const result = await useCase.execute({
        userId1: 'user-1',
        userId2: 'user-2'
      });

      expect(result).toEqual(conversation);
    });

    it('should return null if conversation not found', async () => {
      mockConversationRepo.findByParticipants.mockResolvedValue(null);

      const result = await useCase.execute({
        userId1: 'user-1',
        userId2: 'user-2'
      });

      expect(result).toBeNull();
    });
  });

  describe('GetConversationsUseCase', () => {
    let useCase: GetConversationsUseCaseImpl;
    let mockConversationRepo: any;

    beforeEach(() => {
      mockConversationRepo = {
        findByParticipant: jest.fn()
      };

      useCase = new GetConversationsUseCaseImpl(mockConversationRepo);
    });

    it('should get all conversations for user', async () => {
      const conversations = [
        { id: 'conv-1', participants: [] },
        { id: 'conv-2', participants: [] }
      ];
      mockConversationRepo.findByParticipant.mockResolvedValue(conversations);

      const result = await useCase.execute('user-1');

      expect(result).toHaveLength(2);
    });

    it('should return empty array if no conversations', async () => {
      mockConversationRepo.findByParticipant.mockResolvedValue([]);

      const result = await useCase.execute('user-1');

      expect(result).toEqual([]);
    });
  });

  describe('GetMessagesUseCase', () => {
    let useCase: GetMessagesUseCaseImpl;
    let mockMessageRepo: any;

    beforeEach(() => {
      mockMessageRepo = {
        findByConversation: jest.fn()
      };

      useCase = new GetMessagesUseCaseImpl(mockMessageRepo);
    });

    it('should get messages for conversation', async () => {
      const messages = [
        TestDataFactory.createMessage(),
        TestDataFactory.createMessage({ id: 'msg-2' })
      ];
      mockMessageRepo.findByConversation.mockResolvedValue(messages);

      const result = await useCase.execute({ conversationId: 'conv-1' });

      expect(result).toHaveLength(2);
    });

    it('should handle limit and offset', async () => {
      mockMessageRepo.findByConversation.mockResolvedValue([]);

      await useCase.execute({
        conversationId: 'conv-1',
        limit: 20,
        offset: 10
      });

      expect(mockMessageRepo.findByConversation).toHaveBeenCalledWith('conv-1', 20, 10);
    });
  });

  describe('MarkMessageAsReadUseCase', () => {
    let useCase: MarkMessageAsReadUseCaseImpl;
    let mockMessageRepo: any;

    beforeEach(() => {
      mockMessageRepo = {
        markAsRead: jest.fn()
      };

      useCase = new MarkMessageAsReadUseCaseImpl(mockMessageRepo);
    });

    it('should mark message as read', async () => {
      const message = TestDataFactory.createMessage({ isRead: true });
      mockMessageRepo.markAsRead.mockResolvedValue(message);

      const result = await useCase.execute('msg-1');

      expect(mockMessageRepo.markAsRead).toHaveBeenCalledWith('msg-1');
      expect(result).toEqual(message);
    });

    it('should return null if message not found', async () => {
      mockMessageRepo.markAsRead.mockResolvedValue(null);

      const result = await useCase.execute('nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('GetUnreadCountUseCase', () => {
    let useCase: GetUnreadCountUseCaseImpl;
    let mockMessageRepo: any;

    beforeEach(() => {
      mockMessageRepo = {
        getUnreadCount: jest.fn()
      };

      useCase = new GetUnreadCountUseCaseImpl(mockMessageRepo);
    });

    it('should return unread count', async () => {
      mockMessageRepo.getUnreadCount.mockResolvedValue(5);

      const result = await useCase.execute('user-1');

      expect(result).toBe(5);
    });

    it('should return zero if no unread messages', async () => {
      mockMessageRepo.getUnreadCount.mockResolvedValue(0);

      const result = await useCase.execute('user-1');

      expect(result).toBe(0);
    });
  });

  describe('CreateConversationUseCase', () => {
    let useCase: CreateConversationUseCaseImpl;
    let mockConversationRepo: any;

    beforeEach(() => {
      mockConversationRepo = {
        create: jest.fn()
      };

      useCase = new CreateConversationUseCaseImpl(mockConversationRepo);
    });

    it('should create conversation with participants', async () => {
      const conversation = { id: 'conv-new', participants: [] };
      mockConversationRepo.create.mockResolvedValue(conversation);

      const result = await useCase.execute({
        participants: [
          { userId: 'prof-1', userType: 'professor' },
          { userId: 'student-1', userType: 'student' }
        ]
      });

      expect(result).toEqual(conversation);
      expect(mockConversationRepo.create).toHaveBeenCalled();
    });
  });
});

