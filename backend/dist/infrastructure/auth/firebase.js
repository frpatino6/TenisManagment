"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const firebase_admin_1 = __importDefault(require("firebase-admin"));
const config_1 = require("../config");
if (config_1.config.firebase.enabled) {
    try {
        const serviceAccount = {
            projectId: config_1.config.firebase.projectId,
            privateKey: config_1.config.firebase.privateKey.replace(/\\n/g, '\n'),
            clientEmail: config_1.config.firebase.clientEmail,
        };
        if (!firebase_admin_1.default.apps.length) {
            firebase_admin_1.default.initializeApp({
                credential: firebase_admin_1.default.credential.cert(serviceAccount),
                projectId: config_1.config.firebase.projectId,
            });
        }
    }
    catch (error) {
        throw new Error('Firebase initialization failed');
    }
}
exports.default = firebase_admin_1.default;
//# sourceMappingURL=firebase.js.map