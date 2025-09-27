import { container, TYPES } from '../../infrastructure/di/container.js';
export class ProfessorController {
    constructor() {
        this.publish = container.get(TYPES.PublishScheduleUseCase);
        this.availability = container.get(TYPES.ManageCourtAvailabilityUseCase);
        this.income = container.get(TYPES.TrackIncomeUseCase);
        this.services = container.get(TYPES.ManageServicesUseCase);
        this.schedules = container.get(TYPES.ScheduleRepository);
        this.getSchedule = async (req, res) => {
            try {
                const professorId = String(req.query.professorId);
                const from = req.query.from ? new Date(String(req.query.from)) : undefined;
                const to = req.query.to ? new Date(String(req.query.to)) : undefined;
                if (!professorId)
                    return res.status(400).json({ error: 'professorId is required' });
                const items = await this.schedules.findAvailableByProfessor(professorId, from, to);
                return res.json({ items });
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.createSchedule = async (req, res) => {
            try {
                const created = await this.publish.execute(req.body);
                return res.status(201).json(created);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.updateSchedule = async (req, res) => {
            const updated = await this.availability.setAvailability(req.params.id, Boolean(req.body?.isAvailable));
            if (!updated)
                return res.status(404).json({ error: 'Not found' });
            return res.json(updated);
        };
        this.deleteSchedule = async (req, res) => {
            try {
                await this.schedules.delete(req.params.id);
                return res.status(204).send();
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.incomeReport = async (req, res) => {
            const from = new Date(String(req.query.from));
            const to = new Date(String(req.query.to));
            const result = await this.income.execute(String(req.query.professorId), from, to);
            return res.json(result);
        };
        this.createService = async (req, res) => {
            const created = await this.services.create(req.body);
            return res.status(201).json(created);
        };
        this.updateService = async (req, res) => {
            const updated = await this.services.update(req.params.id, req.body);
            if (!updated)
                return res.status(404).json({ error: 'Not found' });
            return res.json(updated);
        };
    }
}
//# sourceMappingURL=ProfessorController.js.map