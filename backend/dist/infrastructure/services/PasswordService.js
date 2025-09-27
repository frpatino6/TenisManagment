import bcrypt from 'bcryptjs';
export class BcryptPasswordService {
    async hash(password) {
        const salt = await bcrypt.genSalt(10);
        return bcrypt.hash(password, salt);
    }
    async compare(password, hash) {
        return bcrypt.compare(password, hash);
    }
}
//# sourceMappingURL=PasswordService.js.map