import { LightningElement, api } from "lwc";

import lblHouseholdName from "@salesforce/label/c.lblHouseholdName";
import lblFormalGreeting from "@salesforce/label/c.lblFormalGreeting";
import lblInformalGreeting from "@salesforce/label/c.lblInformalGreeting";
import AutoName from "@salesforce/label/c.AutoName";
import AutoFormalGreeting from "@salesforce/label/c.AutoFormalGreeting";
import AutoInformalGreeting from "@salesforce/label/c.AutoInformalGreeting";

export default class ManageHhDetails extends LightningElement {
    @api householdName = "";
    @api formalGreeting = "";
    @api informalGreeting = "";
    @api isAutoName = false;
    @api isAutoFormalGreeting = false;
    @api isAutoInformalGreeting = false;

    get householdNameLabel() {
        return lblHouseholdName;
    }
    get formalGreetingLabel() {
        return lblFormalGreeting;
    }
    get informalGreetingLabel() {
        return lblInformalGreeting;
    }
    get autoNameLabel() {
        return AutoName;
    }
    get autoFormalLabel() {
        return AutoFormalGreeting;
    }
    get autoInformalLabel() {
        return AutoInformalGreeting;
    }

    handleNameChange(event) {
        this.dispatchEvent(
            new CustomEvent("namechanged", {
                detail: { field: "Name", value: event.target.value },
            })
        );
    }

    handleFormalGreetingChange(event) {
        this.dispatchEvent(
            new CustomEvent("namechanged", {
                detail: {
                    field: "Formal_Greeting__c",
                    value: event.target.value,
                },
            })
        );
    }

    handleInformalGreetingChange(event) {
        this.dispatchEvent(
            new CustomEvent("namechanged", {
                detail: {
                    field: "Informal_Greeting__c",
                    value: event.target.value,
                },
            })
        );
    }

    handleAutoNameChange(event) {
        this.dispatchEvent(
            new CustomEvent("autonamingchanged", {
                detail: {
                    field: "Name",
                    checked: event.target.checked,
                },
            })
        );
    }

    handleAutoFormalChange(event) {
        this.dispatchEvent(
            new CustomEvent("autonamingchanged", {
                detail: {
                    field: "Formal_Greeting__c",
                    checked: event.target.checked,
                },
            })
        );
    }

    handleAutoInformalChange(event) {
        this.dispatchEvent(
            new CustomEvent("autonamingchanged", {
                detail: {
                    field: "Informal_Greeting__c",
                    checked: event.target.checked,
                },
            })
        );
    }
}
