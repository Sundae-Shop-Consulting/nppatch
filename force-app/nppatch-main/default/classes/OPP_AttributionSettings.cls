/**
 * @description Handles Opportunity Naming Settings Attribution options.
 * Extracted from STG_PanelOppNaming_CTRL to decouple from VF settings infrastructure.
 */
public class OPP_AttributionSettings {

    /**
     * @description Specifies whether you want to apply these settings to Contact Donations,
     * Organization Donations, or both Contact and Organization Donations.
     */
    public enum AttributionOptions {
        Both,
        Contact_Donations,
        Organization_Donations
    }

    public String selectedOption { get; private set; }
    public String selectedLabel { get; private set; }

    /**
     * @description Contains the Opp Naming Settings Attribution API name to the custom label mapping
     */
    private Map<String, String> labelByOption {
        get {
            if (labelByOption == null) {
                labelByOption = new Map<String, String>{
                    AttributionOptions.Both.name() => System.Label.OppNamingBoth,
                    AttributionOptions.Contact_Donations.name() => System.Label.oppNamingIndividual,
                    AttributionOptions.Organization_Donations.name() => System.Label.oppNamingOrganizational
                };
            }
            return labelByOption;
        }
        set;
    }

    /**
     * @description Contains the Opp Naming Settings Attribution custom label to the API name mapping
     */
    private Map<String, String> optionByLabel {
        get {
            if (optionByLabel == null) {
                optionByLabel = new Map<String, String>{
                    System.Label.OppNamingBoth => AttributionOptions.Both.name(),
                    'Both' => AttributionOptions.Both.name(),

                    System.Label.oppNamingIndividual => AttributionOptions.Contact_Donations.name(),
                    'Contact Donations' => AttributionOptions.Contact_Donations.name(),

                    System.Label.oppNamingOrganizational => AttributionOptions.Organization_Donations.name(),
                    'Organization Donations' => AttributionOptions.Organization_Donations.name()
                };
            }
            return optionByLabel;
        }
        set;
    }

    /**
     * @description Sets attribution value as configured in the Opportunity Naming Settings
     */
    public OPP_AttributionSettings withSelected(String option) {
        this.selectedOption = optionByLabel.containsKey(option) ? optionByLabel.get(option) : option;
        this.selectedLabel = getLabel(this.selectedOption);
        return this;
    }

    /**
     * @description Map the attribution option to the custom label used in Opp naming or settings field option display
     */
    public String getLabel(String option) {
        String label = labelByOption.get(option);

        return String.isBlank(label)
            ? String.isBlank(option) ? '' : option
            : label;
    }

    /**
     * @description Returns true if attribution is applicable to both Contact and Organization Donations
     */
    public Boolean isBoth() {
        return selectedOption == AttributionOptions.Both.name();
    }
}
