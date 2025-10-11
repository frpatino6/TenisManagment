import { Types } from 'mongoose';
import { MessageRepository } from '../../domain/repositories/index';
import { Message } from '../../domain/entities/Message';
import { MessageModel } from '../database/models/MessageModel';

export class MongoMessageRepository implements MessageRepository {
  async create(message: Omit<Message, 'id' | 'createdAt' | 'updatedAt'>): Promise<Message> {
    const doc = await MessageModel.create({
      senderId: new Types.ObjectId(message.senderId),
      receiverId: new Types.ObjectId(message.receiverId),
      content: message.content,
      type: message.type,
      status: message.status,
      conversationId: new Types.ObjectId(message.conversationId),
      parentMessageId: message.parentMessageId
        ? new Types.ObjectId(message.parentMessageId)
        : undefined,
      attachments: message.attachments,
      readAt: message.readAt,
    });

    return this.mapToEntity(doc);
  }

  async findById(id: string): Promise<Message | null> {
    const doc = await MessageModel.findById(id).lean();
    return doc ? this.mapToEntity(doc) : null;
  }

  async findByConversation(
    conversationId: string,
    limit: number = 50,
    offset: number = 0,
  ): Promise<Message[]> {
    const docs = await MessageModel.find({ conversationId: new Types.ObjectId(conversationId) })
      .sort({ createdAt: -1 })
      .skip(offset)
      .limit(limit)
      .lean();

    return docs.map((doc) => this.mapToEntity(doc));
  }

  async markAsRead(messageId: string): Promise<Message | null> {
    const doc = await MessageModel.findByIdAndUpdate(
      messageId,
      {
        status: 'read',
        readAt: new Date(),
      },
      { new: true },
    ).lean();

    return doc ? this.mapToEntity(doc) : null;
  }

  async markAsDelivered(messageId: string): Promise<Message | null> {
    const doc = await MessageModel.findByIdAndUpdate(
      messageId,
      { status: 'delivered' },
      { new: true },
    ).lean();

    return doc ? this.mapToEntity(doc) : null;
  }

  async getUnreadCount(userId: string): Promise<number> {
    return await MessageModel.countDocuments({
      receiverId: new Types.ObjectId(userId),
      status: { $in: ['sent', 'delivered'] },
    });
  }

  async delete(id: string): Promise<void> {
    await MessageModel.findByIdAndDelete(id);
  }

  private mapToEntity(doc: any): Message {
    return {
      id: doc._id.toString(),
      senderId: doc.senderId.toString(),
      receiverId: doc.receiverId.toString(),
      content: doc.content,
      type: doc.type,
      status: doc.status,
      conversationId: doc.conversationId.toString(),
      parentMessageId: doc.parentMessageId?.toString(),
      attachments: doc.attachments?.map((att: any) => ({
        id: att._id.toString(),
        fileName: att.fileName,
        fileUrl: att.fileUrl,
        fileType: att.fileType,
        fileSize: att.fileSize,
      })),
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      readAt: doc.readAt,
    };
  }
}

