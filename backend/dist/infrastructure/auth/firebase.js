"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const firebase_admin_1 = __importDefault(require("firebase-admin"));
const config_1 = require("../config");
if (config_1.config.firebase.enabled) {
    const serviceAccount = {
        type: 'service_account',
        project_id: config_1.config.firebase.projectId,
        private_key_id: 'key_id',
        private_key: config_1.config.firebase.privateKey.replace(/\\n/g, '\n'),
        client_email: config_1.config.firebase.clientEmail,
        client_id: 'client_id',
        auth_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_uri: 'https://oauth2.googleapis.com/token',
        auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
        client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${config_1.config.firebase.clientEmail}`,
    };
    if (!firebase_admin_1.default.apps.length) {
        firebase_admin_1.default.initializeApp({
            credential: firebase_admin_1.default.credential.cert(serviceAccount),
            projectId: config_1.config.firebase.projectId,
        });
    }
    else {
    }
}
exports.default = firebase_admin_1.default;
//# sourceMappingURL=firebase.js.map