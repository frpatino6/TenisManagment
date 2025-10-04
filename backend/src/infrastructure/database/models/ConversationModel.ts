import { Schema, model, Types } from 'mongoose';

export interface ConversationParticipantDocument {
  userId: Types.ObjectId;
  userType: 'professor' | 'student';
  joinedAt: Date;
  leftAt?: Date;
  isActive: boolean;
}

export interface ConversationDocument {
  _id: Types.ObjectId;
  participants: ConversationParticipantDocument[];
  lastMessage?: Types.ObjectId; // Reference to last Message
  lastMessageAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const ConversationParticipantSchema = new Schema<ConversationParticipantDocument>({
  userId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true },
  userType: { type: String, enum: ['professor', 'student'], required: true },
  joinedAt: { type: Date, default: Date.now },
  leftAt: { type: Date },
  isActive: { type: Boolean, default: true },
});

const ConversationSchema = new Schema<ConversationDocument>(
  {
    participants: [ConversationParticipantSchema],
    lastMessage: { type: Schema.Types.ObjectId, ref: 'Message' },
    lastMessageAt: { type: Date },
  },
  { timestamps: true },
);

// Índices para optimizar consultas
ConversationSchema.index({ 'participants.userId': 1, 'participants.isActive': 1 });
ConversationSchema.index({ lastMessageAt: -1 });
ConversationSchema.index({ 
  'participants.userId': 1, 
  'participants.userType': 1,
  'participants.isActive': 1 
});

// Índice compuesto para buscar conversaciones entre dos usuarios específicos
ConversationSchema.index({ 
  'participants.userId': 1,
  'participants.isActive': 1,
  lastMessageAt: -1 
});

export const ConversationModel = model<ConversationDocument>('Conversation', ConversationSchema);
