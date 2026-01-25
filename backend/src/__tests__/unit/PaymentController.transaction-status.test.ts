import { describe, it, expect, jest } from '@jest/globals';
import { PaymentController } from '../../application/controllers/PaymentController';
import { TransactionModel } from '../../infrastructure/database/models/TransactionModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';

// Mock BalanceService
jest.mock('../../application/services/BalanceService', () => {
  return {
    BalanceService: jest.fn().mockImplementation(() => ({
      syncBalance: jest.fn().mockResolvedValue(0),
      getBalance: jest.fn().mockResolvedValue(0),
      calculateBalance: jest.fn().mockResolvedValue(0),
    })),
  };
});

describe('PaymentController.getTransactionStatus', () => {
  const paymentGateway = {
    getTransactionStatus: jest.fn(),
  } as any;

  const controller = new PaymentController(paymentGateway);

  const buildRes = () => {
    const res: any = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
  };

  it('returns status from gateway', async () => {
    const req: any = {
      tenantId: 'tenant-1',
      query: { transactionId: 'trx-123' },
    };
    const res = buildRes();

    jest.spyOn(TenantModel, 'findById').mockResolvedValueOnce({ _id: 't' } as any);
    paymentGateway.getTransactionStatus.mockResolvedValueOnce({
      status: 'DECLINED',
      reference: 'TRX-001',
      externalId: 'ext-1',
      amount: 50000,
      currency: 'COP',
      success: false,
      customerEmail: 'user@example.com',
      paymentMethodType: 'CARD',
      metadata: {},
    });
    jest
      .spyOn(TransactionModel, 'findOne')
      .mockResolvedValueOnce(null as any)
      .mockResolvedValueOnce(null as any);

    await controller.getTransactionStatus(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      status: 'DECLINED',
      reference: 'TRX-001',
      customerEmail: 'user@example.com',
      paymentMethodType: 'CARD',
    });
  });

  it('updates transaction on approved status', async () => {
    const req: any = {
      tenantId: 'tenant-1',
      query: { transactionId: 'trx-123' },
    };
    const res = buildRes();

    jest.spyOn(TenantModel, 'findById').mockResolvedValueOnce({ _id: 't' } as any);
    paymentGateway.getTransactionStatus.mockResolvedValueOnce({
      status: 'APPROVED',
      reference: 'TRX-002',
      externalId: 'ext-2',
      amount: 50000,
      currency: 'COP',
      success: true,
      customerEmail: 'payer@example.com',
      paymentMethodType: 'PSE',
      metadata: {},
    });

    const transaction = {
      tenantId: 't',
      studentId: 's',
      status: 'PENDING',
      metadata: {},
      save: jest.fn(),
    } as any;

    jest.spyOn(TransactionModel, 'findOne')
      .mockResolvedValueOnce(transaction)
      .mockResolvedValueOnce(null as any);
    jest.spyOn(PaymentModel, 'findOne').mockResolvedValueOnce(null as any);
    jest.spyOn(PaymentModel.prototype, 'save').mockResolvedValueOnce({} as any);
    jest.spyOn(StudentTenantModel, 'findOneAndUpdate').mockResolvedValueOnce({} as any);

    await controller.getTransactionStatus(req, res);

    expect(transaction.customerEmail).toBe('payer@example.com');
    expect(transaction.paymentMethodType).toBe('PSE');
    expect(transaction.save).toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(200);
  });

  it('returns status for reference without calling gateway', async () => {
    const req: any = {
      tenantId: 'tenant-1',
      query: { reference: 'TRX-REF-1' },
    };
    const res = buildRes();

    jest.spyOn(TenantModel, 'findById').mockResolvedValueOnce({ _id: 't' } as any);
    jest.spyOn(TransactionModel, 'findOne').mockResolvedValueOnce({
      status: 'APPROVED',
      reference: 'TRX-REF-1',
    } as any);

    await controller.getTransactionStatus(req, res);

    expect(paymentGateway.getTransactionStatus).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      status: 'APPROVED',
      reference: 'TRX-REF-1',
    });
  });
});
