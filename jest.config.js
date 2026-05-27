const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");
module.exports = {
    ...jestConfig,
    setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],
    moduleNameMapper: {
        "^mock-lightning/(.*)$": "<rootDir>/force-app/test/jest-mocks/lightning/$1",
    },
};
