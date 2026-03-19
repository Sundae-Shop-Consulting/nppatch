const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");
module.exports = {
    ...jestConfig,
    testMatch: ["**/__tests__/**/?(*.)+(spec|test).[jt]s?(x)"],
    testPathIgnorePatterns: ["<rootDir>/node_modules/", "<rootDir>/test/specs/"],
    reporters: ["default"],
    setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],
};
