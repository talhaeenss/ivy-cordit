'use client';

import { useEffect, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import { useStore } from './store';
import type { Message } from './types';

// Socket.io connects to backend public URL (for browser access)
// Uses NEXT_PUBLIC_BACKEND_URL from environment
const SOCKET_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3000';

let globalSocket: Socket | null = null;

const getSocket = (token: string) => {
  if (!globalSocket || !globalSocket.connected) {
    globalSocket = io(SOCKET_URL, {
      auth: { token },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5,
    });
  }
  return globalSocket;
};

export const useSocket = () => {
  const socketRef = useRef<Socket | null>(null);
  const {
    user,
    currentRoom,
    addMessage,
    setConnected,
    addTypingUser,
    removeTypingUser,
  } = useStore();

  useEffect(() => {
    if (!user?.token) return;

    const socket = getSocket(user.token);
    socketRef.current = socket;

    const handleConnect = () => {
      console.log('Socket connected');
      setConnected(true);
    };

    const handleDisconnect = () => {
      console.log('Socket disconnected');
      setConnected(false);
    };

    const handleNewMessage = (message: Message) => {
      console.log('Received new message:', message);
      addMessage(message);
    };

    const handleUserTyping = (data: { username: string; isTyping: boolean }) => {
      if (data.isTyping) {
        addTypingUser(data.username);
        setTimeout(() => removeTypingUser(data.username), 3000);
      } else {
        removeTypingUser(data.username);
      }
    };

    const handleError = (error: { message: string }) => {
      console.error('Socket error:', error.message);
    };

    // Remove old listeners
    socket.off('connect', handleConnect);
    socket.off('disconnect', handleDisconnect);
    socket.off('new_message', handleNewMessage);
    socket.off('user_typing', handleUserTyping);
    socket.off('error', handleError);

    // Add new listeners
    socket.on('connect', handleConnect);
    socket.on('disconnect', handleDisconnect);
    socket.on('new_message', handleNewMessage);
    socket.on('user_typing', handleUserTyping);
    socket.on('error', handleError);

    return () => {
      socket.off('connect', handleConnect);
      socket.off('disconnect', handleDisconnect);
      socket.off('new_message', handleNewMessage);
      socket.off('user_typing', handleUserTyping);
      socket.off('error', handleError);
    };
  }, [user, addMessage, setConnected, addTypingUser, removeTypingUser]);

  useEffect(() => {
    if (currentRoom && socketRef.current?.connected) {
      console.log('Joining room:', currentRoom._id);
      socketRef.current.emit('join_room', { roomId: currentRoom._id });

      return () => {
        console.log('Leaving room:', currentRoom._id);
        socketRef.current?.emit('leave_room', { roomId: currentRoom._id });
      };
    } else {
      console.log('Cannot join room:', { hasRoom: !!currentRoom, connected: socketRef.current?.connected });
    }
  }, [currentRoom]);

  const sendMessage = (text: string) => {
    if (socketRef.current && currentRoom) {
      console.log('Sending message:', { roomId: currentRoom._id, text, connected: socketRef.current.connected });
      socketRef.current.emit('send_message', { roomId: currentRoom._id, text });
    } else {
      console.error('Cannot send message:', { hasSocket: !!socketRef.current, hasRoom: !!currentRoom });
    }
  };

  const startTyping = () => {
    if (socketRef.current && currentRoom) {
      socketRef.current.emit('typing_start', { roomId: currentRoom._id });
    }
  };

  const stopTyping = () => {
    if (socketRef.current && currentRoom) {
      socketRef.current.emit('typing_stop', { roomId: currentRoom._id });
    }
  };

  return { sendMessage, startTyping, stopTyping, socket: socketRef.current };
};

export const disconnectSocket = () => {
  if (globalSocket) {
    globalSocket.disconnect();
    globalSocket = null;
  }
};
