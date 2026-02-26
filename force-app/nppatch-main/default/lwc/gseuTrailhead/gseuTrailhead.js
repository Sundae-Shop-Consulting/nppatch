import { LightningElement } from 'lwc';
import NPPATCH_STATIC_RESOURCES from '@salesforce/resourceUrl/NPPatchStaticResources'
import gseuTrailheadText from '@salesforce/label/c.gseuTrailheadText'
import gseuTrailheadLogoText from '@salesforce/label/c.gseuTrailheadLogoText'
import opensInNewLink from '@salesforce/label/c.opensInNewLink'
import gseuExploreTrailheadButton from '@salesforce/label/c.gseuExploreTrailheadButton'
export default class EuTrailhead extends LightningElement {
    /**
     * Url of the image shown in the component
     */
    imgUrl = NPPATCH_STATIC_RESOURCES + '/gsAssets/trailheadComponent/trailheadLogo.svg';

    /**
     * Object to reference the labels
     */
    labels = {
        gseuTrailheadText,
        gseuTrailheadLogoText,
        gseuExploreTrailheadButton,
        opensInNewLink
    }

    exploreTrailheadAriaLabel = `${this.labels.gseuExploreTrailheadButton} ${this.labels.opensInNewLink}`;

    /**
     * Handles the click in the button. 
     * It opens an url(https://sforce.co/2MyeNE9) in a new tab.
     */
    handleClick() {
        window.open("https://sforce.co/2MyeNE9");
    }
}