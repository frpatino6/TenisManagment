import { Types } from 'mongoose';
import { ScheduleModel, ScheduleDocument } from '../../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { Logger } from '../../infrastructure/services/Logger';

const logger = new Logger({ module: 'ScheduleValidationService' });

export class ScheduleValidationService {
  /**
   * Valida si un schedule tiene conflicto con un court_rental booking
   * @param schedule - El Schedule a validar
   * @param tenantId - ID del tenant
   * @returns true si hay conflicto, false si está disponible
   */
  async hasCourtRentalConflict(
    schedule: ScheduleDocument,
    tenantId: Types.ObjectId
  ): Promise<boolean> {
    // Si el schedule no tiene courtId asignado, no puede tener conflicto
    if (!schedule.courtId) {
      return false;
    }

    // Buscar bookings de tipo court_rental que se solapen con el schedule
    const conflictingBooking = await BookingModel.findOne({
      tenantId: tenantId,
      courtId: schedule.courtId,
      serviceType: 'court_rental',
      status: { $in: ['confirmed', 'pending'] },
      // Validar solapamiento temporal
      $or: [
        // Caso 1: Booking se solapa parcialmente con el schedule
        {
          bookingDate: { $lt: schedule.endTime },
          endTime: { $gt: schedule.startTime }
        },
        // Caso 2: Booking sin endTime (duración por defecto 1 hora)
        {
          endTime: { $exists: false },
          bookingDate: {
            $gte: schedule.startTime,
            $lt: schedule.endTime
          }
        },
        // Caso 3: Booking contiene completamente el schedule
        {
          bookingDate: { $lte: schedule.startTime },
          endTime: { $gte: schedule.endTime }
        },
        // Caso 4: Booking está completamente dentro del schedule
        {
          bookingDate: { $gte: schedule.startTime },
          endTime: { $lte: schedule.endTime }
        }
      ]
    });

    if (conflictingBooking) {
      logger.info('Schedule has conflict with court_rental booking', {
        scheduleId: schedule._id.toString(),
        bookingId: conflictingBooking._id.toString(),
        courtId: schedule.courtId.toString()
      });
    }

    return !!conflictingBooking;
  }

  /**
   * Filtra múltiples schedules removiendo los que tienen conflicto con court_rental
   * Versión optimizada que hace una sola query para obtener todos los court_rental bookings
   * @param schedules - Array de schedules a validar (puede ser documentos de Mongoose o objetos planos)
   * @param tenantId - ID del tenant
   * @returns Array de schedules sin conflictos (mismo tipo que el input)
   */
  async filterSchedulesWithoutConflicts<T extends ScheduleDocument>(
    schedules: T[],
    tenantId: Types.ObjectId
  ): Promise<T[]> {
    if (schedules.length === 0) {
      return [];
    }

    // Extraer courtIds únicos de los schedules que tienen cancha asignada
    // Manejar tanto ObjectId como objetos poblados
    const courtIds: string[] = [];
    for (const schedule of schedules) {
      if (!schedule.courtId) {
        continue;
      }

      let courtIdStr: string | null = null;
      
      // Si es un ObjectId directo
      if (schedule.courtId instanceof Types.ObjectId) {
        courtIdStr = schedule.courtId.toString();
      }
      // Si es un objeto poblado (tiene _id)
      else if (typeof schedule.courtId === 'object' && schedule.courtId !== null && '_id' in schedule.courtId) {
        const populatedCourtId = (schedule.courtId as any)._id;
        if (populatedCourtId instanceof Types.ObjectId) {
          courtIdStr = populatedCourtId.toString();
        } else if (typeof populatedCourtId === 'string') {
          courtIdStr = populatedCourtId;
        }
      }
      // Si es un string
      else if (typeof schedule.courtId === 'string') {
        courtIdStr = schedule.courtId;
      }

      // Validar que sea un ObjectId válido (24 caracteres hex)
      if (courtIdStr && /^[0-9a-fA-F]{24}$/.test(courtIdStr)) {
        courtIds.push(courtIdStr);
      }
    }

    const uniqueCourtIds = Array.from(new Set(courtIds));

    if (uniqueCourtIds.length === 0) {
      // Si ningún schedule tiene cancha válida, todos están disponibles
      return schedules;
    }

    // Calcular el rango de tiempo que cubre todos los schedules
    const minStartTime = new Date(Math.min(...schedules.map(s => s.startTime.getTime())));
    const maxEndTime = new Date(Math.max(...schedules.map(s => s.endTime.getTime())));

    // Obtener TODOS los court_rental bookings activos para estas canchas en el rango de tiempo
    const courtRentalBookings = await BookingModel.find({
      tenantId,
      courtId: { $in: uniqueCourtIds.map(id => new Types.ObjectId(id)) },
      serviceType: 'court_rental',
      status: { $in: ['confirmed', 'pending'] },
      $or: [
        // Bookings que se solapan con el rango total
        {
          bookingDate: { $lt: maxEndTime },
          endTime: { $gt: minStartTime }
        },
        // Bookings sin endTime dentro del rango
        {
          endTime: { $exists: false },
          bookingDate: {
            $gte: minStartTime,
            $lt: maxEndTime
          }
        }
      ]
    }).lean();

    // Filtrar schedules en memoria
    return schedules.filter(schedule => {
      // Si el schedule no tiene cancha, no puede tener conflicto
      if (!schedule.courtId) {
        return true;
      }

      const scheduleStart = schedule.startTime;
      const scheduleEnd = schedule.endTime;

      // Extraer el courtId del schedule de forma segura
      let scheduleCourtIdStr: string | null = null;
      if (schedule.courtId instanceof Types.ObjectId) {
        scheduleCourtIdStr = schedule.courtId.toString();
      } else if (typeof schedule.courtId === 'object' && schedule.courtId !== null && '_id' in schedule.courtId) {
        const populatedCourtId = (schedule.courtId as any)._id;
        scheduleCourtIdStr = populatedCourtId instanceof Types.ObjectId 
          ? populatedCourtId.toString() 
          : typeof populatedCourtId === 'string' ? populatedCourtId : null;
      } else if (typeof schedule.courtId === 'string') {
        scheduleCourtIdStr = schedule.courtId;
      }

      if (!scheduleCourtIdStr) {
        return true; // Sin cancha válida, no puede tener conflicto
      }

      // Buscar si hay algún booking que se solape con este schedule
      const hasConflict = courtRentalBookings.some(booking => {
        // Verificar que el booking sea para la misma cancha
        if (!booking.courtId) {
          return false;
        }

        const bookingCourtIdStr = booking.courtId.toString();
        if (bookingCourtIdStr !== scheduleCourtIdStr) {
          return false;
        }

        const bookingStart = booking.bookingDate;
        if (!bookingStart) {
          return false;
        }

        // Si no tiene endTime, asumir duración de 1 hora
        const bookingEnd = booking.endTime || 
          new Date(bookingStart.getTime() + 60 * 60 * 1000);

        // Verificar solapamiento temporal
        // Dos intervalos se solapan si: start1 < end2 && start2 < end1
        return bookingStart < scheduleEnd && bookingEnd > scheduleStart;
      });

      // Incluir solo si NO hay conflicto
      return !hasConflict;
    });
  }
}
