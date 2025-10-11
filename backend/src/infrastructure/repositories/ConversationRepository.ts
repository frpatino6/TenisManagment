import { Types } from 'mongoose';
import { ConversationRepository } from '../../domain/repositories/index';
import { Conversation, Message } from '../../domain/entities/Message';
import { ConversationModel } from '../database/models/ConversationModel';

export class MongoConversationRepository implements ConversationRepository {
  async create(
    conversation: Omit<Conversation, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<Conversation> {
    const doc = await ConversationModel.create({
      participants: conversation.participants.map((p) => ({
        userId: new Types.ObjectId(p.userId),
        userType: p.userType,
        joinedAt: p.joinedAt,
        leftAt: p.leftAt,
        isActive: p.isActive,
      })),
      lastMessage: conversation.lastMessage
        ? new Types.ObjectId(conversation.lastMessage.id)
        : undefined,
      lastMessageAt: conversation.lastMessageAt,
    });

    return this.mapToEntity(doc);
  }

  async findById(id: string): Promise<Conversation | null> {
    const doc = await ConversationModel.findById(id).lean();
    return doc ? this.mapToEntity(doc) : null;
  }

  async findByParticipant(userId: string): Promise<Conversation[]> {
    const docs = await ConversationModel.find({
      'participants.userId': new Types.ObjectId(userId),
      'participants.isActive': true,
    })
      .sort({ lastMessageAt: -1 })
      .lean();

    return docs.map((doc) => this.mapToEntity(doc));
  }

  async findByParticipants(userId1: string, userId2: string): Promise<Conversation | null> {
    const doc = await ConversationModel.findOne({
      'participants.userId': { $all: [new Types.ObjectId(userId1), new Types.ObjectId(userId2)] },
      'participants.isActive': true,
    }).lean();

    return doc ? this.mapToEntity(doc) : null;
  }

  async updateLastMessage(
    conversationId: string,
    message: Message,
  ): Promise<Conversation | null> {
    const doc = await ConversationModel.findByIdAndUpdate(
      conversationId,
      {
        lastMessage: new Types.ObjectId(message.id),
        lastMessageAt: message.createdAt,
      },
      { new: true },
    ).lean();

    return doc ? this.mapToEntity(doc) : null;
  }

  async addParticipant(
    conversationId: string,
    participant: Conversation['participants'][0],
  ): Promise<Conversation | null> {
    const doc = await ConversationModel.findByIdAndUpdate(
      conversationId,
      {
        $push: {
          participants: {
            userId: new Types.ObjectId(participant.userId),
            userType: participant.userType,
            joinedAt: participant.joinedAt,
            isActive: participant.isActive,
          },
        },
      },
      { new: true },
    ).lean();

    return doc ? this.mapToEntity(doc) : null;
  }

  async removeParticipant(conversationId: string, userId: string): Promise<Conversation | null> {
    const doc = await ConversationModel.findOneAndUpdate(
      {
        _id: new Types.ObjectId(conversationId),
        'participants.userId': new Types.ObjectId(userId),
      },
      {
        $set: {
          'participants.$.isActive': false,
          'participants.$.leftAt': new Date(),
        },
      },
      { new: true },
    ).lean();

    return doc ? this.mapToEntity(doc) : null;
  }

  private mapToEntity(doc: any): Conversation {
    return {
      id: doc._id.toString(),
      participants: doc.participants.map((p: any) => ({
        userId: p.userId.toString(),
        userType: p.userType,
        joinedAt: p.joinedAt,
        leftAt: p.leftAt,
        isActive: p.isActive,
      })),
      lastMessage: undefined, // Se popula desde el servicio si se necesita
      lastMessageAt: doc.lastMessageAt,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }
}

