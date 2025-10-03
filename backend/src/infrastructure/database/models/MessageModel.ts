import { Schema, model, Types } from 'mongoose';

export interface MessageAttachmentDocument {
  _id: Types.ObjectId;
  fileName: string;
  fileUrl: string;
  fileType: string;
  fileSize: number;
}

export interface MessageDocument {
  _id: Types.ObjectId;
  senderId: Types.ObjectId;
  receiverId: Types.ObjectId;
  content: string;
  type: 'text' | 'image' | 'file' | 'system';
  status: 'sent' | 'delivered' | 'read';
  conversationId: Types.ObjectId;
  parentMessageId?: Types.ObjectId; // Para mensajes de respuesta
  attachments?: MessageAttachmentDocument[];
  readAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const MessageAttachmentSchema = new Schema<MessageAttachmentDocument>({
  fileName: { type: String, required: true },
  fileUrl: { type: String, required: true },
  fileType: { type: String, required: true },
  fileSize: { type: Number, required: true },
});

const MessageSchema = new Schema<MessageDocument>(
  {
    senderId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true, index: true },
    receiverId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true, index: true },
    content: { type: String, required: true },
    type: { 
      type: String, 
      enum: ['text', 'image', 'file', 'system'], 
      default: 'text' 
    },
    status: { 
      type: String, 
      enum: ['sent', 'delivered', 'read'], 
      default: 'sent' 
    },
    conversationId: { type: Schema.Types.ObjectId, ref: 'Conversation', required: true, index: true },
    parentMessageId: { type: Schema.Types.ObjectId, ref: 'Message', index: true },
    attachments: [MessageAttachmentSchema],
    readAt: { type: Date },
  },
  { timestamps: true },
);

// Índices para optimizar consultas
MessageSchema.index({ conversationId: 1, createdAt: -1 });
MessageSchema.index({ senderId: 1, createdAt: -1 });
MessageSchema.index({ receiverId: 1, status: 1 });
MessageSchema.index({ conversationId: 1, senderId: 1, createdAt: -1 });

export const MessageModel = model<MessageDocument>('Message', MessageSchema);
