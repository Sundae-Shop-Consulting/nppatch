// http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
const HTTP_CODES = Object.freeze({
    OK: 200,
    Created: 201,
    Bad_Request: 400,
    Request_Timeout: 408,
});

const PAYMENT_METHOD_CREDIT_CARD = "Credit Card";
const PAYMENT_METHOD_ACH = "ACH";
const GIFT_STATUSES = {
    READY_TO_PROCESS: "Ready to Process",
    IMPORTED: "Imported",
    DRY_RUN_VALIDATED: "Dry Run - Validated",
    DRY_RUN_ERROR: "Dry Run - Error",
    FAILED: "Failed",
    PROCESSING: "Processing",
};

const CLICKED_UP = "clicked-up";
const CLICKED_DOWN = "clicked-down";
const DOWN = "down";
const UP = "up";

export {
    HTTP_CODES,
    GIFT_STATUSES,
    PAYMENT_METHOD_CREDIT_CARD,
    PAYMENT_METHOD_ACH,
    CLICKED_UP,
    CLICKED_DOWN,
    DOWN,
    UP,
};
