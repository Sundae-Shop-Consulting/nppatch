import { LightningElement } from "lwc";

export default class AdminHomeResources extends LightningElement {
    resources = [
        {
            key: "docs",
            title: "Documentation",
            icon: "standard:knowledge",
            description: "Guides, tutorials, and reference documentation for NPPatch.",
            linkLabel: "Visit Documentation",
            url: "https://nppatch.readthedocs.io",
        },
        {
            key: "web",
            title: "Website",
            icon: "standard:home",
            description: "News, updates, and information about the NPPatch project.",
            linkLabel: "Visit nppatch.com",
            url: "https://nppatch.com",
        },
        {
            key: "github",
            title: "GitHub",
            icon: "standard:custom",
            description: "Source code, issue tracker, and release notes.",
            linkLabel: "View on GitHub",
            url: "https://github.com/Sundae-Shop-Consulting/nppatch",
        },
    ];
}
