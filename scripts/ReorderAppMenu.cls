/**
* @description Reorders the App Menu to put NPPatch apps first; used by reorder_app_menu CCI task.
*/
static final String NPPatch_APP_NAME = 'NPPatch_Lightning';

public static void setPPatchAppToFirst() {
    List<UserAppMenuItem> appMenuItems = [SELECT ApplicationId, Name FROM UserAppMenuItem ORDER BY SortOrder];
    List<Id> orderedIds = new List<Id>();
    Boolean firstItem = true;
    for (UserAppMenuItem item : appMenuItems) {
        if (item.Name == NPPatch_APP_NAME) {
            if (firstItem) {
                return;
            }
            orderedIds.add(0, item.ApplicationId);
        } else {
            orderedIds.add(item.ApplicationId);
        }
        firstItem = false;
    }
    AppLauncher.AppMenu.setOrgSortOrder(orderedIds);
}
