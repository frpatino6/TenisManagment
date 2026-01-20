import { describe, it, expect, jest } from '@jest/globals';
import { PaymentController } from '../../application/controllers/PaymentController';
import { TransactionModel } from '../../infrastructure/database/models/TransactionModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';

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
    jest.spyOn(StudentModel, 'findByIdAndUpdate').mockResolvedValueOnce({} as any);

    await controller.getTransactionStatus(req, res);

    expect(transaction.save).toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(200);
  });
});
