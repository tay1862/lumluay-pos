import {
  Controller, Get, Post, Patch, Delete,
  Body, Param, Query, ParseUUIDPipe, UseGuards, HttpCode, HttpStatus, NotFoundException,
} from '@nestjs/common';
import { ProductsService } from './products.service';
import {
  CreateProductDto,
  UpdateProductDto,
  CreateVariantDto,
  CreateUnitConversionDto,
  UploadProductImageDto,
} from './dto/product.dto';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { ModifierGroupsService } from '@/modules/modifier-groups/modifier-groups.service';

@Controller('products')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ProductsController {
  constructor(
    private readonly productsService: ProductsService,
    private readonly modifierGroupsService: ModifierGroupsService,
  ) {}

  @Get()
  findAll(@TenantId() tenantId: string) {
    return this.productsService.findAll(tenantId);
  }

  @Get('barcode/:code')
  async findByBarcode(
    @TenantId() tenantId: string,
    @Param('code') code: string,
  ) {
    const product = await this.productsService.findByBarcode(tenantId, code);
    if (!product) throw new NotFoundException(`Product with barcode ${code} not found`);
    return product;
  }

  @Get(':id')
  findOne(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.productsService.findOne(tenantId, id);
  }

  @Post()
  @Roles('owner', 'manager')
  create(@TenantId() tenantId: string, @Body() dto: CreateProductDto) {
    return this.productsService.create(tenantId, dto);
  }

  @Patch(':id')
  @Roles('owner', 'manager')
  update(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateProductDto,
  ) {
    return this.productsService.update(tenantId, id, dto);
  }

  @Delete(':id')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.productsService.remove(tenantId, id);
  }

  @Post(':id/variants')
  @Roles('owner', 'manager')
  addVariant(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateVariantDto,
  ) {
    return this.productsService.addVariant(tenantId, id, dto);
  }

  @Delete(':id/variants/:variantId')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeVariant(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('variantId', ParseUUIDPipe) variantId: string,
  ) {
    return this.productsService.removeVariant(tenantId, id, variantId);
  }

  @Get(':id/unit-conversions')
  getUnitConversions(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.productsService.getUnitConversions(tenantId, id);
  }

  @Post(':id/unit-conversions')
  @Roles('owner', 'manager')
  addUnitConversion(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateUnitConversionDto,
  ) {
    return this.productsService.addUnitConversion(tenantId, id, dto);
  }

  @Delete(':id/unit-conversions/:conversionId')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeUnitConversion(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('conversionId', ParseUUIDPipe) conversionId: string,
  ) {
    return this.productsService.removeUnitConversion(tenantId, id, conversionId);
  }

  @Post('upload-image')
  @Roles('owner', 'manager')
  uploadImage(@Body() dto: UploadProductImageDto) {
    return this.productsService.uploadImage(dto);
  }

  // ─── Modifier Groups ───────────────────────────────────────────────────────

  @Get(':id/modifier-groups')
  getModifierGroups(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.modifierGroupsService.getProductModifiers(tenantId, id);
  }

  @Post(':id/modifier-groups/:groupId')
  @Roles('owner', 'manager')
  linkModifierGroup(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) productId: string,
    @Param('groupId', ParseUUIDPipe) groupId: string,
  ) {
    return this.modifierGroupsService.linkGroupToProduct(tenantId, productId, groupId);
  }

  @Delete(':id/modifier-groups/:groupId')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.NO_CONTENT)
  unlinkModifierGroup(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) productId: string,
    @Param('groupId', ParseUUIDPipe) groupId: string,
  ) {
    return this.modifierGroupsService.unlinkGroupFromProduct(tenantId, productId, groupId);
  }
}
