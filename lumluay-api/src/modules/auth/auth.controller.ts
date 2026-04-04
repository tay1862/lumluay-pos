import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  Req,
  UseGuards,
  Get,
  Patch,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { FastifyRequest } from 'fastify';
import { AuthService } from './auth.service';
import { LoginDto, LoginPinDto, RefreshTokenDto, ChangePasswordDto } from './dto/auth.dto';
import { CurrentUser } from '@/common/decorators/user.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { users } from '@/database/schema';

// ─────────────────────────────────────────────────────────────────────────────
// Auth Controller (18.3.3 — stricter rate limits on auth endpoints)
// ─────────────────────────────────────────────────────────────────────────────
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /** 5 login attempts per minute per IP */
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  login(
    @Body() dto: LoginDto,
    @Req() req: FastifyRequest,
  ) {
    const ip = req.ip;
    return this.authService.login(dto, ip);
  }

  /** 10 PIN attempts per minute — no JWT required (employee switch use-case) */
  @Post('login/pin')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 10 } })
  loginPin(
    @Body() dto: LoginPinDto,
    @Req() req: FastifyRequest,
  ) {
    return this.authService.loginWithPin(dto, req.ip);
  }

  /** 20 refresh attempts per minute per device */
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 20 } })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  logout(@CurrentUser() user: typeof users.$inferSelect & { sessionId?: string }) {
    return this.authService.logout(user.sessionId ?? '');
  }

  @Post('logout/all')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  logoutAll(@CurrentUser() user: typeof users.$inferSelect) {
    return this.authService.logoutAll(user.id);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: typeof users.$inferSelect) {
    return user;
  }
}
