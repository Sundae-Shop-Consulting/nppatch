import { LightningElement, api, track } from "lwc";
import { fireEvent } from "c/pubsubNoPageRef";

const DELAY = 300;

export default class utilSearchableCombobox extends LightningElement {
    @api name;
    @api comboboxLabel;
    @api searchInputLabel;
    _selectedFieldValue;
    @api
    get selectedFieldValue() {
        return this._selectedFieldValue;
    }
    set selectedFieldValue(val) {
        this._selectedFieldValue = val;
    }
    @api options;
    _searchableOptions;
    @api
    get searchableOptions() {
        return this._searchableOptions;
    }
    set searchableOptions(val) {
        this._searchableOptions = val;
    }
    @api parentListenerEventName;
    @api fieldLevelHelp;
    @api disabled;
    @api hasErrors;
    @api dropdownAlignment = "left";

    @track isSearchOpen;
    @track searchKey = "";
    @track searchResults;
    @track areSearchResultsVisible = false;

    get customSearchResultBoxClasses() {
        if (this.dropdownAlignment === "bottom-left") {
            return "slds-box custom-search-result-box alignment-direction__bottom-left";
        }
        return "slds-box custom-search-result-box";
    }

    get comboboxClass() {
        return this.hasErrors ? "slds-has-error slds-listbox_extension" : "slds-listbox_extension";
    }

    showSearch() {
        this.isSearchOpen = true;
        fireEvent(this.pageRef, this.parentListenerEventName, undefined);
    }

    hideSearch() {
        this.isSearchOpen = false;
        this.areSearchResultsVisible = false;
    }

    debounceOnSearchKeyChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY.
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        if (searchKey && searchKey.length > 1) {
            this.delayTimeout = setTimeout(() => {
                this.handleSearchkeyChange(searchKey);
            }, DELAY);
        } else {
            this.searchResults = undefined;
        }
    }

    handleSearchkeyChange(searchKey) {
        const results = [];

        if (!this._searchableOptions) {
            this._searchableOptions = this.options;
        }

        for (let i = 0; i < this._searchableOptions.length; i++) {
            if (this._searchableOptions[i].label.toLowerCase().indexOf(searchKey.toLowerCase()) !== -1) {
                const result = {
                    id: i,
                    label: this._searchableOptions[i].label,
                    value: this._searchableOptions[i].value,
                };
                results.push(result);
            }
        }

        this.searchResults = results;
        this.areSearchResultsVisible = true;
    }

    selectSearchResult(event) {
        const result = {
            detail: {
                label: event.target.dataset.fieldLabel,
                value: event.target.dataset.fieldValue,
            },
        };

        fireEvent(this.pageRef, this.parentListenerEventName, result);

        this._selectedFieldValue = result.detail.value;
        this.searchResults = undefined;
        this.isSearchOpen = false;
        this.areSearchResultsVisible = false;
    }

    handleFieldChange(event) {
        fireEvent(this.pageRef, this.parentListenerEventName, event);
    }
}
