export type MessageType = 'text' | 'image' | 'file' | 'system';
export type MessageStatus = 'sent' | 'delivered' | 'read';

export interface Message {
  id: string;
  senderId: string;
  receiverId: string;
  content: string;
  type: MessageType;
  status: MessageStatus;
  conversationId: string;
  parentMessageId?: string; // Para mensajes de respuesta
  attachments?: MessageAttachment[];
  createdAt: Date;
  updatedAt?: Date;
  readAt?: Date;
}

export interface MessageAttachment {
  id: string;
  fileName: string;
  fileUrl: string;
  fileType: string;
  fileSize: number;
}

export interface Conversation {
  id: string;
  participants: ConversationParticipant[];
  lastMessage?: Message;
  lastMessageAt?: Date;
  createdAt: Date;
  updatedAt?: Date;
}

export interface ConversationParticipant {
  userId: string;
  userType: 'professor' | 'student';
  joinedAt: Date;
  leftAt?: Date;
  isActive: boolean;
}