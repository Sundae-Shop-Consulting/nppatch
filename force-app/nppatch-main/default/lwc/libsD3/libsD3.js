/* global d3 */
/* eslint-disable consistent-return */
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import NPPATCH_STATIC_RESOURCES from "@salesforce/resourceUrl/NPPatchStaticResources";

class LibsD3 {
    isInitialized = false;
    d3;

    init = (context) => {
        if (this.isInitialized) {
            return;
        }
        this.isInitialized = true;

        return new Promise((resolve, reject) => {
            loadScript(context, NPPATCH_STATIC_RESOURCES + "/d3/d3.min.js")
                .then(() => {
                    this.d3 = d3;
                    resolve();
                })
                .catch((error) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error loading static resource",
                            message: error.message,
                            variant: "error",
                        })
                    );
                    reject();
                });
        });
    };
}

export default new LibsD3();
