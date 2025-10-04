import { MessageRepository, ConversationRepository } from '../repositories/index';
import {
  SendMessageUseCase,
  GetConversationUseCase,
  GetConversationsUseCase,
  GetMessagesUseCase,
  MarkMessageAsReadUseCase,
  GetUnreadCountUseCase,
  CreateConversationUseCase,
} from './index';
import { Message, Conversation } from '../entities/Message';

export class SendMessageUseCaseImpl implements SendMessageUseCase {
  constructor(
    private messageRepository: MessageRepository,
    private conversationRepository: ConversationRepository,
  ) {}

  async execute(args: {
    senderId: string;
    receiverId: string;
    content: string;
    type?: 'text' | 'image' | 'file' | 'system';
    parentMessageId?: string;
    attachments?: Message['attachments'];
  }): Promise<Message> {
    // Buscar o crear conversación entre los usuarios
    let conversation = await this.conversationRepository.findByParticipants(
      args.senderId,
      args.receiverId
    );

    if (!conversation) {
      // Crear nueva conversación
      conversation = await this.conversationRepository.create({
        participants: [
          { userId: args.senderId, userType: 'professor', joinedAt: new Date(), isActive: true },
          { userId: args.receiverId, userType: 'student', joinedAt: new Date(), isActive: true },
        ],
      });
    }

    // Crear mensaje
    const message = await this.messageRepository.create({
      senderId: args.senderId,
      receiverId: args.receiverId,
      content: args.content,
      type: args.type || 'text',
      status: 'sent',
      conversationId: conversation.id,
      parentMessageId: args.parentMessageId,
      attachments: args.attachments,
    });

    // Actualizar última mensaje de la conversación
    await this.conversationRepository.updateLastMessage(conversation.id, message);

    return message;
  }
}

export class GetConversationUseCaseImpl implements GetConversationUseCase {
  constructor(private conversationRepository: ConversationRepository) {}

  async execute(args: {
    userId1: string;
    userId2: string;
  }): Promise<Conversation | null> {
    return await this.conversationRepository.findByParticipants(args.userId1, args.userId2);
  }
}

export class GetConversationsUseCaseImpl implements GetConversationsUseCase {
  constructor(private conversationRepository: ConversationRepository) {}

  async execute(userId: string): Promise<Conversation[]> {
    return await this.conversationRepository.findByParticipant(userId);
  }
}

export class GetMessagesUseCaseImpl implements GetMessagesUseCase {
  constructor(private messageRepository: MessageRepository) {}

  async execute(args: {
    conversationId: string;
    limit?: number;
    offset?: number;
  }): Promise<Message[]> {
    return await this.messageRepository.findByConversation(
      args.conversationId,
      args.limit,
      args.offset
    );
  }
}

export class MarkMessageAsReadUseCaseImpl implements MarkMessageAsReadUseCase {
  constructor(private messageRepository: MessageRepository) {}

  async execute(messageId: string): Promise<Message | null> {
    return await this.messageRepository.markAsRead(messageId);
  }
}

export class GetUnreadCountUseCaseImpl implements GetUnreadCountUseCase {
  constructor(private messageRepository: MessageRepository) {}

  async execute(userId: string): Promise<number> {
    return await this.messageRepository.getUnreadCount(userId);
  }
}

export class CreateConversationUseCaseImpl implements CreateConversationUseCase {
  constructor(private conversationRepository: ConversationRepository) {}

  async execute(args: {
    participants: Array<{
      userId: string;
      userType: 'professor' | 'student';
    }>;
  }): Promise<Conversation> {
    return await this.conversationRepository.create({
      participants: args.participants.map(p => ({
        userId: p.userId,
        userType: p.userType,
        joinedAt: new Date(),
        isActive: true,
      })),
    });
  }
}
