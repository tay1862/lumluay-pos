import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Socket, Server } from 'socket.io';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { JwtPayload } from '../auth/strategies/jwt.strategy';

// ─────────────────────────────────────────────────────────────────────────────
// 17.5.1 — Unified WebSocket Gateway
// Covers: kitchen (17.5.3), orders (17.5.2), tables (17.5.4),
//         queue (17.5.5), notifications (17.5.6)
// ─────────────────────────────────────────────────────────────────────────────
@WebSocketGateway({
  cors: {
    origin: true,
    credentials: true,
  },
  namespace: '/',
})
export class KitchenGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(KitchenGateway.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly jwtService: JwtService,
  ) {}

  handleConnection(client: Socket) {
    try {
      const token =
        client.handshake.auth?.token ??
        client.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        this.logger.warn(`Client ${client.id} rejected: no token`);
        client.emit('error', { message: 'Authentication required' });
        client.disconnect(true);
        return;
      }

      const secret = this.configService.get<string>('jwt.secret')!;
      const payload = this.jwtService.verify<JwtPayload>(token, { secret });

      // Store user info on socket for later use
      (client as any).user = payload;
      this.logger.log(`Client connected: ${client.id} (user: ${payload.sub}, tenant: ${payload.tenantId})`);
    } catch (err) {
      this.logger.warn(`Client ${client.id} rejected: invalid token`);
      client.emit('error', { message: 'Invalid token' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  // ── Room Management ────────────────────────────────────────────────────────

  @SubscribeMessage('join:tenant')
  handleJoinTenant(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { tenantId?: string },
  ) {
    if (!payload?.tenantId) return;

    // Verify user can only join their own tenant room
    const user = (client as any).user as JwtPayload | undefined;
    if (!user || user.tenantId !== payload.tenantId) {
      client.emit('error', { message: 'Unauthorized tenant access' });
      return;
    }

    client.join(`tenant:${payload.tenantId}`);
    client.emit('joined', { room: `tenant:${payload.tenantId}` });
  }

  @SubscribeMessage('leave:tenant')
  handleLeaveTenant(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { tenantId?: string },
  ) {
    if (!payload?.tenantId) return;
    client.leave(`tenant:${payload.tenantId}`);
  }

  // ── 17.5.3 Kitchen Emitters ───────────────────────────────────────────────

  emitNewOrder(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('kitchen:new-order', payload);
  }

  emitStatusChanged(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('kitchen:status-changed', payload);
  }

  // ── 17.5.2 Orders Channel ─────────────────────────────────────────────────

  emitOrderCreated(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('order:created', payload);
  }

  emitOrderUpdated(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('order:updated', payload);
  }

  emitOrderStatusChanged(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('order:status-changed', payload);
  }

  emitOrderCompleted(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('order:completed', payload);
  }

  emitOrderVoided(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('order:voided', payload);
  }

  // ── 17.5.4 Tables Channel ─────────────────────────────────────────────────

  emitTableStatusChanged(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('table:status-changed', payload);
  }

  emitTableMerged(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('table:merged', payload);
  }

  // ── 17.5.5 Queue Channel ──────────────────────────────────────────────────

  emitQueueAdded(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('queue:added', payload);
  }

  emitQueueCalled(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('queue:called', payload);
  }

  emitQueueCompleted(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('queue:completed', payload);
  }

  // ── 17.5.6 Notifications Channel ─────────────────────────────────────────

  emitNotification(tenantId: string, payload: Record<string, unknown>) {
    this.server.to(`tenant:${tenantId}`).emit('notification:new', payload);
  }

  emitNotificationRead(tenantId: string, userId: string, notificationId: string) {
    this.server.to(`tenant:${tenantId}`).emit('notification:read', { userId, notificationId });
  }
}
