"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteAccount = exports.createProfile = exports.computePersonalBests = exports.aggregateStats = exports.parentApproval = exports.parentalConsent = exports.onUserDelete = exports.onUserCreate = void 0;
const admin = require("firebase-admin");
admin.initializeApp();
var userLifecycle_1 = require("./auth/userLifecycle");
Object.defineProperty(exports, "onUserCreate", { enumerable: true, get: function () { return userLifecycle_1.onUserCreate; } });
Object.defineProperty(exports, "onUserDelete", { enumerable: true, get: function () { return userLifecycle_1.onUserDelete; } });
var parentalConsent_1 = require("./auth/parentalConsent");
Object.defineProperty(exports, "parentalConsent", { enumerable: true, get: function () { return parentalConsent_1.parentalConsent; } });
Object.defineProperty(exports, "parentApproval", { enumerable: true, get: function () { return parentalConsent_1.parentApproval; } });
var aggregateStats_1 = require("./stats/aggregateStats");
Object.defineProperty(exports, "aggregateStats", { enumerable: true, get: function () { return aggregateStats_1.aggregateStats; } });
var personalBests_1 = require("./stats/personalBests");
Object.defineProperty(exports, "computePersonalBests", { enumerable: true, get: function () { return personalBests_1.computePersonalBests; } });
var profileManagement_1 = require("./users/profileManagement");
Object.defineProperty(exports, "createProfile", { enumerable: true, get: function () { return profileManagement_1.createProfile; } });
Object.defineProperty(exports, "deleteAccount", { enumerable: true, get: function () { return profileManagement_1.deleteAccount; } });
//# sourceMappingURL=index.js.map