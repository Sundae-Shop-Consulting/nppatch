import { LightningElement } from 'lwc';
import gsVideoHeaderTitle from '@salesforce/label/c.gsVideoHeaderTitle';
import NPPATCH_STATIC_RESOURCES from '@salesforce/resourceUrl/NPPatchStaticResources';

export default class GseuHeader extends LightningElement {
    backgroundUrl = NPPATCH_STATIC_RESOURCES + '/gsAssets/gseuHeader/GetStarted.svg';
    /**
    * Returns an Image URL to display in UI
    * @return      the image at the specified URL
    * @see         URL
    */
    get imgSrc() {
        return `background-image:url(${this.backgroundUrl});
                background-size: cover;
                background-repeat: no-repeat;
                background-position: center center;
                padding-top: 42%`;
    }

    get title() {
        return gsVideoHeaderTitle;
    }

}