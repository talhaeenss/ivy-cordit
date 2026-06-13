import { Server as SocketIOServer, Socket } from 'socket.io';
import { Server as HTTPServer } from 'http';
import jwt from 'jsonwebtoken';
import Room from '../models/room';
import Message from '../models/message';
import { logger } from './logger';
import { config } from '../config';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  username?: string;
}

interface JoinRoomData {
  roomId: string;
}

interface SendMessageData {
  roomId: string;
  text: string;
}

export const initializeSocket = (httpServer: HTTPServer) => {
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: config.allowedOrigins,
      methods: ['GET', 'POST'],
      credentials: true,
    },
  });

  // Authentication middleware
  io.use(async (socket: AuthenticatedSocket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        return next(new Error('Authentication error: No token provided'));
      }

      const decoded = jwt.verify(token, config.jwtSecret) as { username: string; role: string };

      // Get user from DB to ensure session is valid and get correct ID
      const User = (await import('../models/user')).default;
      const user = await User.findOne({
        username: { $regex: new RegExp(`^${decoded.username}$`, 'i') },
        isDeleted: false
      });

      if (!user) {
        return next(new Error('Authentication error: User not found'));
      }

      socket.userId = user._id.toString();
      socket.username = user.username;

      next();
    } catch (err) {
      logger.error('Socket authentication error:', err);
      next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket: AuthenticatedSocket) => {
    logger.info(`User connected: ${socket.username} (${socket.id})`);

    // Join room
    socket.on('join_room', async (data: JoinRoomData) => {
      try {
        const { roomId } = data;
        const room = await Room.findOne({ _id: roomId, isDeleted: false });

        if (!room) {
          socket.emit('error', { message: 'Room not found' });
          return;
        }

        socket.join(roomId);

        // Add to activeUsers if not already there
        const alreadyIn = room.activeUsers.some(u => u.username.toLowerCase() === socket.username?.toLowerCase());
        if (!alreadyIn) {
          const User = (await import('../models/user')).default;
          const user = await User.findOne({ username: socket.username });

          if (user) {
            room.activeUsers.push({
              userId: user._id,
              username: socket.username!,
              joinedAt: new Date(),
              isVoiceActive: false,
              livekitParticipantId: `user_${socket.username}_${Date.now()}`
            });
            await room.save();
          }
        }

        logger.info(`${socket.username} joined room: ${room.name}`);

        socket.emit('joined_room', { roomId, roomName: room.name });
        io.to(roomId).emit('user_joined', { username: socket.username, timestamp: new Date() });
      } catch (error) {
        logger.error('Error in join_room:', error);
      }
    });

    // Send message
    socket.on('send_message', async (data: SendMessageData) => {
      try {
        const { roomId, text } = data;

        if (!text || text.trim().length === 0) return;

        const room = await Room.findOne({ _id: roomId, isDeleted: false });
        if (!room) {
          socket.emit('error', { message: 'Room not found' });
          return;
        }

        // We trust the socket connection and join_room state
        const User = (await import('../models/user')).default;
        const user = await User.findOne({ username: socket.username });
        if (!user) {
          socket.emit('error', { message: 'User verification failed' });
          return;
        }

        const message = new Message({
          roomId,
          userId: user._id,
          username: socket.username,
          text: text.trim(),
          messageType: 'text',
        });

        await message.save();

        const payload = {
          _id: message._id,
          roomId: message.roomId.toString(),
          userId: message.userId.toString(),
          username: message.username,
          text: message.text,
          messageType: message.messageType,
          createdAt: message.createdAt,
        };

        io.to(roomId).emit('new_message', payload);
        logger.info(`Message broadcasted from ${socket.username} in ${roomId}`);
      } catch (error) {
        logger.error('Error in send_message:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Leave room
    socket.on('leave_room', (data: JoinRoomData) => {
      const { roomId } = data;
      socket.leave(roomId);
      io.to(roomId).emit('user_left', { username: socket.username, timestamp: new Date() });
    });

    // Typing
    socket.on('typing_start', (roomId: string) => {
      socket.to(roomId).emit('user_typing', { username: socket.username, roomId });
    });

    socket.on('typing_stop', (roomId: string) => {
      socket.to(roomId).emit('user_typing', { username: null, roomId });
    });

    socket.on('disconnect', () => {
      logger.info(`User disconnected: ${socket.username}`);
    });
  });

  return io;
};
