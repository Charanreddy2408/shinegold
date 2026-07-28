#!/usr/bin/env python3
"""Fill missing kn/te ARB keys and auto-migrate exact English string literals to l10n."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"

# Accurate Kannada for missing keys (from _kn_missing.txt English values).
KN: dict[str, str] = {
    "notVisitedYet": "ಇನ್ನೂ ಭೇಟಿ ನೀಡಿಲ್ಲ",
    "goodMorning": "ಶುಭೋದಯ",
    "goodAfternoon": "ಶುಭ ಮಧ್ಯಾಹ್ನ",
    "goodEvening": "ಶುಭ ಸಂಜೆ",
    "recordConversations": "ನೀವು ಆನ್‌ಬೋರ್ಡ್ ಮಾಡಲು ಬಯಸುವ ರೈತರೊಂದಿಗೆ ಸಂವಾದಗಳನ್ನು ರೆಕಾರ್ಡ್ ಮಾಡಿ",
    "farmsYouOnboarded": "ನೀವು ಆನ್‌ಬೋರ್ಡ್ ಮಾಡಿದ ಫಾರ್ಮ್‌ಗಳು",
    "noFarmsOnboardedYet": "ಇನ್ನೂ ಯಾವುದೇ ಫಾರ್ಮ್ ಆನ್‌ಬೋರ್ಡ್ ಆಗಿಲ್ಲ",
    "farmsFromOnboardTab": "ಆನ್‌ಬೋರ್ಡ್ ಟ್ಯಾಬ್‌ನಿಂದ ನೀವು ಸೇರಿಸುವ ಫಾರ್ಮ್‌ಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ",
    "moreOnboardedFarms": "+{count} ಹೆಚ್ಚು ಆನ್‌ಬೋರ್ಡ್ ಫಾರ್ಮ್‌ಗಳು",
    "noPriorityFarms": "ಆದ್ಯತೆಯ ಫಾರ್ಮ್‌ಗಳಿಲ್ಲ",
    "pendingVisitsToday": "ಇಂದಿನ ಬಾಕಿ ಭೇಟಿಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ",
    "farmsForToday": "ಇಂದಿನ ಫಾರ್ಮ್‌ಗಳು",
    "tapToViewDetails": "ವಿವರಗಳನ್ನು ನೋಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ",
    "harvest": "ಬೆಳೆ ಕೊಯ್ಲು",
    "assignedFarmsCount": "{count} ನಿಯೋಜಿತ ಫಾರ್ಮ್‌ಗಳು",
    "nearbyUnassignedFarms": "ಹತ್ತಿರದ ನಿಯೋಜಿಸದ ಫಾರ್ಮ್‌ಗಳು",
    "filters": "ಫಿಲ್ಟರ್‌ಗಳು",
    "clearAll": "ಎಲ್ಲಾ ತೆರವುಗೊಳಿಸಿ",
    "apply": "ಅನ್ವಯಿಸಿ",
    "nearbyFirst": "ಹತ್ತಿರದವು ಮೊದಲು",
    "farthestFirst": "ದೂರದವು ಮೊದಲು",
    "nameAZ": "ಹೆಸರು A-Z",
    "searchFarmFarmerMobile": "ಫಾರ್ಮ್, ರೈತ, ಮೊಬೈಲ್ ಹುಡುಕಿ...",
    "tryAdjustingFilters": "ನಿಮ್ಮ ಹುಡುಕಾಟ ಅಥವಾ ಫಿಲ್ಟರ್‌ಗಳನ್ನು ಹೊಂದಿಸಿ ಪ್ರಯತ್ನಿಸಿ",
    "clearFilters": "ಫಿಲ್ಟರ್‌ಗಳನ್ನು ತೆರವುಗೊಳಿಸಿ",
    "nearbyFarmsTitle": "ಹತ್ತಿರದ ಫಾರ್ಮ್‌ಗಳು",
    "unassignedFarmsWithinKm": "70 ಕಿ.ಮೀ ಒಳಗೆ {count} ನಿಯೋಜಿಸದ ಫಾರ್ಮ್‌ಗಳು",
    "noNearbyInvitations": "ಹತ್ತಿರದಲ್ಲಿ ಆಮಂತ್ರಣಗಳಿಲ್ಲ",
    "unassignedFarmsDescription": "ನಿಮ್ಮ ಹೋಮ್ ಲೊಕೇಶನ್‌ನಿಂದ 70 ಕಿ.ಮೀ ಒಳಗಿನ ನಿಯೋಜಿಸದ ಫಾರ್ಮ್‌ಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ. ಅಗತ್ಯವಿದ್ದರೆ ಪ್ರೊಫೈಲ್‌ನಲ್ಲಿ ಹೋಮ್ ಲೊಕೇಶನ್ ಹೊಂದಿಸಿ.",
    "farmerPrefix": "ರೈತ: {name}",
    "kmAwayLabel": "{km} ಕಿ.ಮೀ ದೂರ",
    "acceptAssignment": "ನಿಯೋಜನೆ ಸ್ವೀಕರಿಸಿ",
    "farmAddedToYourFarms": "{farmName} ನಿಮ್ಮ ಫಾರ್ಮ್‌ಗಳಿಗೆ ಸೇರಿಸಲಾಗಿದೆ",
    "farmSummary": "ಫಾರ್ಮ್ ಸಾರಾಂಶ",
    "harvestInformation": "ಬೆಳೆ ಕೊಯ್ಲು ಮಾಹಿತಿ",
    "setHarvestDate": "ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ ಹೊಂದಿಸಿ",
    "type": "ಪ್ರಕಾರ",
    "harvestStatusLabel": "ಬೆಳೆ ಕೊಯ್ಲು ಸ್ಥಿತಿ",
    "updateHarvestDate": "ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ ಅಪ್‌ಡೇಟ್",
    "updating": "ಅಪ್‌ಡೇಟ್ ಆಗುತ್ತಿದೆ…",
    "harvestDateHistory": "ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ ಇತಿಹಾಸ",
    "byLabel": "ಮೂಲಕ",
    "mapLabel": "ನಕ್ಷೆ",
    "farmPhotosLabel": "ಫಾರ್ಮ್ ಫೋಟೋಗಳು",
    "noVisitsRecordedYet": "ಇನ್ನೂ ಯಾವುದೇ ಭೇಟಿ ದಾಖಲಾಗಿಲ್ಲ",
    "continueVisit": "ಭೇಟಿ ಮುಂದುವರಿಸಿ",
    "updateHarvestDateTitle": "ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ ಅಪ್‌ಡೇಟ್",
    "currentHarvestDate": "ಪ್ರಸ್ತುತ: {date}",
    "currentNotSet": "ಪ್ರಸ್ತುತ: ಹೊಂದಿಸಿಲ್ಲ",
    "tapToPickNewDate": "ಹೊಸ ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ",
    "reasonOptional": "ಕಾರಣ (ಐಚ್ಛಿಕ)",
    "whyHarvestDateChanging": "ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ ಏಕೆ ಬದಲಾಗುತ್ತಿದೆ?",
    "saveHarvestDate": "ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ ಉಳಿಸಿ",
    "harvestDateUpdated": "ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ ಅಪ್‌ಡೇಟ್ ಆಯಿತು",
    "pickDifferentDateToSave": "ಬದಲಾವಣೆ ಉಳಿಸಲು ಬೇರೆ ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ",
    "farmNotFound": "ಫಾರ್ಮ್ ಕಂಡುಬಂದಿಲ್ಲ.",
    "noMobileNumber": "ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಇಲ್ಲ",
    "aadharPrefix": "ಆಧಾರ್: {number}",
    "assignExecutives": "ಎಕ್ಸಿಕ್ಯೂಟಿವ್‌ಗಳನ್ನು ನಿಯೋಜಿಸಿ",
    "executivesLabel": "ಎಕ್ಸಿಕ್ಯೂಟಿವ್‌ಗಳು",
    "executiveLabel": "ಎಕ್ಸಿಕ್ಯೂಟಿವ್",
    "farmVisit": "ಫಾರ್ಮ್ ಭೇಟಿ",
    "startLabel": "ಪ್ರಾರಂಭ",
    "reportLabel": "ವರದಿ",
    "mediaLabel": "ಮೀಡಿಯಾ",
    "offlineAnswersStayOnDevice": "ಆಫ್‌ಲೈನ್ — ಉತ್ತರಗಳು ಮತ್ತು ಮೀಡಿಯಾ ಸಿಂಕ್‌ವರೆಗೆ ಈ ಸಾಧನದಲ್ಲೇ ಉಳಿಯುತ್ತವೆ",
    "startVisitButton": "ಭೇಟಿ ಪ್ರಾರಂಭಿಸಿ",
    "checkinRecordsTimeLocation": "ಚೆಕ್-ಇನ್ ನಿಮ್ಮ ಸಮಯ ಮತ್ತು ಸ್ಥಳವನ್ನು ದಾಖಲಿಸುತ್ತದೆ. ನಂತರ ನೀವು ಕ್ಷೇತ್ರ ಭೇಟಿ ವರದಿ ಪೂರ್ಣಗೊಳಿಸುತ್ತೀರಿ.",
    "continueToMedia": "ಮೀಡಿಯಾಗೆ ಮುಂದುವರಿಸಿ",
    "photosAndVoice": "ಫೋಟೋಗಳು ಮತ್ತು ಧ್ವನಿ",
    "optionalPhotosVoice": "ಐಚ್ಛಿಕ — ಗರಿಷ್ಠ 5 ಜಿಯೋಟ್ಯಾಗ್ ಫೋಟೋಗಳು ಮತ್ತು ಧ್ವನಿ ನೋಟ್ (ಗರಿಷ್ಠ 2:30)",
    "reviewAndSubmit": "ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಸಲ್ಲಿಸಿ",
    "reviewVisit": "ಭೇಟಿ ಪರಿಶೀಲಿಸಿ",
    "reportFields": "ವರದಿ ಕ್ಷೇತ್ರಗಳು",
    "requiredFieldsCount": "{answered} / {required} ಅಗತ್ಯ",
    "photosAttachedCount": "{count} ಲಗತ್ತಿಸಲಾಗಿದೆ",
    "voiceNote": "ಧ್ವನಿ ನೋಟ್",
    "marked": "ಗುರುತಿಸಲಾಗಿದೆ",
    "skipped": "ಬಿಟ್ಟುಬಿಡಲಾಗಿದೆ",
    "submitVisit": "ಭೇಟಿ ಸಲ್ಲಿಸಿ",
    "requiredFieldNeedsAnswer": "1 ಅಗತ್ಯ ಕ್ಷೇತ್ರಕ್ಕೆ ಇನ್ನೂ ಉತ್ತರ ಬೇಕು",
    "requiredFieldsNeedAnswers": "{count} ಅಗತ್ಯ ಕ್ಷೇತ್ರಗಳಿಗೆ ಇನ್ನೂ ಉತ್ತರಗಳು ಬೇಕು",
    "requiredFieldNeedAnswerBelow": "ಕೆಳಗೆ 1 ಅಗತ್ಯ ಕ್ಷೇತ್ರಕ್ಕೆ ಉತ್ತರ ಬೇಕು",
    "requiredFieldsNeedAnswersBelow": "ಕೆಳಗೆ {count} ಅಗತ್ಯ ಕ್ಷೇತ್ರಗಳಿಗೆ ಉತ್ತರಗಳು ಬೇಕು",
    "voiceNoteMarked": "ಧ್ವನಿ ನೋಟ್ ಗುರುತಿಸಲಾಗಿದೆ",
    "voiceNoteAutoSaved": "2:30 ಮಿತಿಯಲ್ಲಿ ಧ್ವನಿ ನೋಟ್ ಸ್ವಯಂ-ಉಳಿಸಲಾಗಿದೆ",
    "offlineModeSyncLater": "ಆಫ್‌ಲೈನ್ ಮೋಡ್ — ಇಂಟರ್ನೆಟ್ ಬಂದಾಗ ಭೇಟಿ ಸಿಂಕ್ ಆಗುತ್ತದೆ",
    "noInternetFarmNotCached": "ಇಂಟರ್ನೆಟ್ ಇಲ್ಲ ಮತ್ತು ಈ ಫಾರ್ಮ್ ಇನ್ನೂ ಕ್ಯಾಶ್ ಆಗಿಲ್ಲ. ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ ಒಮ್ಮೆ ಫಾರ್ಮ್ ತೆರೆಯಿರಿ, ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
    "noInternetNoFormCached": "ಇಂಟರ್ನೆಟ್ ಇಲ್ಲ ಮತ್ತು ಉಳಿಸಿದ ಭೇಟಿ ಫಾರ್ಮ್ ಇಲ್ಲ. ಫಾರ್ಮ್ ಕ್ಯಾಶ್ ಆಗಲು ಮೊದಲು ಒಂದು ಆನ್‌ಲೈನ್ ಭೇಟಿ ಪೂರ್ಣಗೊಳಿಸಿ.",
    "couldNotCancelVisit": "ಭೇಟಿ ರದ್ದುಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ: {error}",
    "microphonePermissionRequired": "ರೆಕಾರ್ಡ್ ಮಾಡಲು ಮೈಕ್ರೋಫೋನ್ ಅನುಮತಿ ಬೇಕು",
    "couldNotStartRecording": "ರೆಕಾರ್ಡಿಂಗ್ ಪ್ರಾರಂಭಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ: {error}",
    "couldNotStopRecording": "ರೆಕಾರ್ಡಿಂಗ್ ನಿಲ್ಲಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ: {error}",
    "voiceSavedLocallyWillUpload": "ಧ್ವನಿ ಸ್ಥಳೀಯವಾಗಿ ಉಳಿಸಲಾಗಿದೆ — ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ ಅಪ್‌ಲೋಡ್ ಆಗುತ್ತದೆ",
    "voiceUploadFailed": "ಧ್ವನಿ ಅಪ್‌ಲೋಡ್ ವಿಫಲ: {error}",
    "maximum5PhotosAllowed": "ಗರಿಷ್ಠ 5 ಫೋಟೋಗಳು ಅನುಮತಿಸಲಾಗಿದೆ",
    "visitSubmittedSuccessfully": "ಭೇಟಿ ಯಶಸ್ವಿಯಾಗಿ ಸಲ್ಲಿಸಲಾಗಿದೆ",
    "visitSavedOfflineSyncLater": "ಭೇಟಿ ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ. ಇಂಟರ್ನೆಟ್ ಬಂದಾಗ ಸ್ವಯಂ ಸಿಂಕ್ ಆಗುತ್ತದೆ.",
    "myVisitsTitle": "ನನ್ನ ಭೇಟಿಗಳು",
    "visitRecordsCount": "{count} ಭೇಟಿ ದಾಖಲೆಗಳು",
    "visitsWaitingToSync": "{count} ಭೇಟಿಗಳು · {pending} ಸಿಂಕ್‌ಗಾಗಿ ಕಾಯುತ್ತಿವೆ",
    "syncingOfflineVisits": "ಆಫ್‌ಲೈನ್ ಭೇಟಿಗಳನ್ನು ಸಿಂಕ್ ಮಾಡಲಾಗುತ್ತಿದೆ — ನಿಧಾನ ಸಂಪರ್ಕದಲ್ಲಿ ಕೆಲವು ನಿಮಿಷಗಳು ಬೇಕಾಗಬಹುದು…",
    "searchByFarmName": "ಫಾರ್ಮ್ ಹೆಸರಿನಿಂದ ಹುಡುಕಿ...",
    "allLabel": "ಎಲ್ಲಾ",
    "ongoingLabel": "ನಡೆಯುತ್ತಿದೆ",
    "completedLabel": "ಪೂರ್ಣಗೊಂಡಿದೆ",
    "yourFarmVisitsAppearHere": "ನಿಮ್ಮ ಫಾರ್ಮ್ ಭೇಟಿಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ",
    "offlineVisitSyncedSingular": "1 ಆಫ್‌ಲೈನ್ ಭೇಟಿ ಸಿಂಕ್ ಆಯಿತು",
    "offlineVisitsSyncedPlural": "{count} ಆಫ್‌ಲೈನ್ ಭೇಟಿಗಳು ಸಿಂಕ್ ಆದವು",
    "stillOfflineSyncRetryLater": "ಇನ್ನೂ ಆಫ್‌ಲೈನ್ — ಸಿಂಕ್ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸುತ್ತದೆ",
    "nothingWaitingToSync": "ಸಿಂಕ್‌ಗಾಗಿ ಏನೂ ಕಾಯುತ್ತಿಲ್ಲ",
    "savedOnDeviceTapToSync": "ಈ ಸಾಧನದಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ · ಈಗ ಸಿಂಕ್ ಮಾಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ",
    "onboardFarmTitle": "ಫಾರ್ಮ್ ಆನ್‌ಬೋರ್ಡ್",
    "farmCreated": "ಫಾರ್ಮ್ ರಚಿಸಲಾಗಿದೆ!",
    "farmOnboardedExclaim": "ಫಾರ್ಮ್ ಆನ್‌ಬೋರ್ಡ್ ಆಯಿತು!",
    "farmAddedSuccessfully": "ಫಾರ್ಮ್ ಯಶಸ್ವಿಯಾಗಿ ಸೇರಿಸಲಾಗಿದೆ.",
    "viewDashboard": "ಡ್ಯಾಶ್‌ಬೋರ್ಡ್ ನೋಡಿ",
    "onboardAnother": "ಮತ್ತೊಂದನ್ನು ಆನ್‌ಬೋರ್ಡ್ ಮಾಡಿ",
    "nextFarmerDetails": "ಮುಂದೆ: ರೈತರ ವಿವರಗಳು",
    "farmNameInput": "ಫಾರ್ಮ್ ಹೆಸರು",
    "editFarmBoundary": "ಫಾರ್ಮ್ ಗಡಿ ಸಂಪಾದಿಸಿ",
    "markFarmBoundaryOnMap": "ನಕ್ಷೆಯಲ್ಲಿ ಫಾರ್ಮ್ ಗಡಿ ಗುರುತಿಸಿ",
    "yourLocationShownOnMap": "ನಕ್ಷೆಯಲ್ಲಿ ನಿಮ್ಮ ಸ್ಥಳ ತೋರಿಸಲಾಗಿದೆ · {pins} ಗಡಿ ಪಿನ್‌ಗಳು · {acres} ಎಕರೆಗಳು",
    "yourCurrentGpsShown": "ನಿಮ್ಮ ಪ್ರಸ್ತುತ GPS ನಕ್ಷೆಯಲ್ಲಿ ತೋರಿಸಲಾಗಿದೆ — ಗಡಿ ಪಿನ್‌ಗಳನ್ನು ಗುರುತಿಸಲು ಬಟನ್ ಟ್ಯಾಪ್ ಮಾಡಿ",
    "waitingForGpsEnableLocation": "GPSಗಾಗಿ ಕಾಯುತ್ತಿದೆ… ನಕ್ಷೆಯನ್ನು ನಿಮ್ಮ ಮೇಲೆ ಕೇಂದ್ರೀಕರಿಸಲು ಲೊಕೇಶನ್ ಸಕ್ರಿಯಗೊಳಿಸಿ",
    "locationAddressOptional": "ಸ್ಥಳ ವಿಳಾಸ (ಐಚ್ಛಿಕ)",
    "locationAddressHint": "ಪ್ರದೇಶ, ನಗರ, ಪಿನ್ — ಪ್ರದರ್ಶನ ಮಾತ್ರ; ನಕ್ಷೆ ಪಿನ್ ದೂರವನ್ನು ನಿರ್ಧರಿಸುತ್ತದೆ",
    "cropInput": "ಬೆಳೆ",
    "harvestTypeInput": "ಬೆಳೆ ಕೊಯ್ಲು ಪ್ರಕಾರ",
    "harvestDateInput": "ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ",
    "totalAcresInput": "ಒಟ್ಟು ಎಕರೆಗಳು",
    "calculatedFromBoundary": "ಗಡಿ ಪಿನ್‌ಗಳಿಂದ ಲೆಕ್ಕಹಾಕಲಾಗಿದೆ",
    "numberOfPlantsInput": "ಸಸಿಗಳ ಸಂಖ್ಯೆ",
    "totalPlantsOnFarm": "ಈ ಫಾರ್ಮ್‌ನಲ್ಲಿರುವ ಒಟ್ಟು ಸಸಿಗಳು",
    "farmPhotosSectionLabel": "ಫಾರ್ಮ್ ಫೋಟೋಗಳು",
    "addPhotoLabel": "ಫೋಟೋ ಸೇರಿಸಿ",
    "tapPhotoToReplace": "ಬದಲಾಯಿಸಲು ಫೋಟೋ ಟ್ಯಾಪ್ ಮಾಡಿ, ಅಥವಾ ತೆಗೆದುಹಾಕಿ ಬಳಸಿ.",
    "optionalAddPhotos": "ಐಚ್ಛಿಕ — ಗರಿಷ್ಠ {max} ಫೋಟೋಗಳನ್ನು ಸೇರಿಸಿ (ಕ್ಯಾಮೆರಾ ಅಥವಾ ಗ್ಯಾಲರಿ)",
    "farmerNameInput": "ರೈತರ ಹೆಸರು",
    "mobileNumberInput": "ಮೊಬೈಲ್ ಸಂಖ್ಯೆ",
    "aadharNumberInput": "ಆಧಾರ್ ಸಂಖ್ಯೆ",
    "aadharHint": "12-ಅಂಕಿಯ ಆಧಾರ್",
    "genderInput": "ಲಿಂಗ",
    "ageInput": "ವಯಸ್ಸು",
    "enterFarmName": "ಫಾರ್ಮ್ ಹೆಸರು ನಮೂದಿಸಿ",
    "pinFarmBoundaryMinimum3": "ನಕ್ಷೆಯಲ್ಲಿ ಫಾರ್ಮ್ ಗಡಿ ಪಿನ್ ಮಾಡಿ (ಕನಿಷ್ಠ 3 ಪಿನ್‌ಗಳು)",
    "enterCropName": "ಬೆಳೆ ಹೆಸರು ನಮೂದಿಸಿ",
    "enterNumberOfPlants": "ಸಸಿಗಳ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ",
    "enterFarmerName": "ರೈತರ ಹೆಸರು ನಮೂದಿಸಿ",
    "enterFarmerMobile": "ರೈತರ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ",
    "enterValid12DigitAadhar": "ಮಾನ್ಯ 12-ಅಂಕಿಯ ಆಧಾರ್ ನಮೂದಿಸಿ",
    "pleaseSelectGender": "ದಯವಿಟ್ಟು ಲಿಂಗ ಆಯ್ಕೆಮಾಡಿ",
    "enterValidFarmerAge": "ಮಾನ್ಯ ರೈತರ ವಯಸ್ಸು ನಮೂದಿಸಿ",
    "enterHarvestTypeOnFarmDetails": "ಫಾರ್ಮ್ ವಿವರಗಳ ಹಂತದಲ್ಲಿ ಬೆಳೆ ಕೊಯ್ಲು ಪ್ರಕಾರ ನಮೂದಿಸಿ",
    "farmBoundaryRequiredGoBack": "ಫಾರ್ಮ್ ಗಡಿ ಅಗತ್ಯ. ಹಿಂದೆ ಹೋಗಿ ಗಡಿ ಗುರುತಿಸಿ.",
    "farmCreatedSuccessfully": "ಫಾರ್ಮ್ ಯಶಸ್ವಿಯಾಗಿ ರಚಿಸಲಾಗಿದೆ",
    "maximumPhotosAllowed": "ಗರಿಷ್ಠ {max} ಫೋಟೋಗಳು ಅನುಮತಿಸಲಾಗಿದೆ",
    "removeLabel": "ತೆಗೆದುಹಾಕಿ",
    "youMustBeSignedInToOnboard": "ಫಾರ್ಮ್ ಆನ್‌ಬೋರ್ಡ್ ಮಾಡಲು ನೀವು ಸೈನ್ ಇನ್ ಆಗಿರಬೇಕು.",
    "selectFarmBoundary": "ಫಾರ್ಮ್ ಗಡಿ ಆಯ್ಕೆಮಾಡಿ",
    "recenterOnMyLocation": "ನನ್ನ ಸ್ಥಳಕ್ಕೆ ಮರುಕೇಂದ್ರೀಕರಿಸಿ",
    "showIndia": "ಭಾರತ ತೋರಿಸಿ",
    "searchVillageDistrict": "ಭಾರತದಲ್ಲಿ ಗ್ರಾಮ, ಜಿಲ್ಲೆ ಹುಡುಕಿ...",
    "farmBoundaryStatus": "ಫಾರ್ಮ್ ಗಡಿ — ಸ್ಥಿತಿ",
    "readyToConfirm": "ದೃಢೀಕರಿಸಲು ಸಿದ್ಧ · {pins} ಪಿನ್‌ಗಳು, {acres} ಎಕರೆಗಳು",
    "tapMapToDropBoundary": "ಗಡಿ ಮೂಲೆಗಳನ್ನು ಹಾಕಲು ನಕ್ಷೆಯನ್ನು ಟ್ಯಾಪ್ ಮಾಡಿ",
    "boundaryPinsLabel": "ಗಡಿ ಪಿನ್‌ಗಳು",
    "pinsPlaced": "{pins} ಪಿನ್‌ಗಳು · {acres} ಎಕರೆಗಳು",
    "minPinsRequired": "ಕನಿಷ್ಠ 3ರಲ್ಲಿ {pins} ಪಿನ್‌ಗಳು ಹಾಕಲಾಗಿದೆ",
    "tapMapAtEachCorner": "ಫಾರ್ಮ್‌ನ ಪ್ರತಿ ಮೂಲೆಯಲ್ಲಿ ನಕ್ಷೆಯನ್ನು ಟ್ಯಾಪ್ ಮಾಡಿ.",
    "gpsLocationLabel": "GPS ಸ್ಥಳ",
    "gettingFix": "ಫಿಕ್ಸ್ ಪಡೆಯಲಾಗುತ್ತಿದೆ…",
    "noGpsFixYet": "ಇನ್ನೂ GPS ಫಿಕ್ಸ್ ಇಲ್ಲ.",
    "fixOutsideIndia": "ಫಿಕ್ಸ್ ಭಾರತದ ಹೊರಗಿದೆ ({lat}, {lng}).",
    "gpsOptionalCanPinManually": "ಇಲ್ಲಿ GPS ಐಚ್ಛಿಕ — ನೀವು ಇನ್ನೂ ಕೈಯಾರೆ ಗಡಿ ಪಿನ್ ಮಾಡಬಹುದು. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಲು ಮರುಕೇಂದ್ರೀಕರಿಸಿ ಟ್ಯಾಪ್ ಮಾಡಿ.",
    "addressLookup": "ವಿಳಾಸ ಹುಡುಕಾಟ",
    "noAddressFound": "ಈ ಸ್ಥಳಕ್ಕೆ ವಿಳಾಸ ಕಂಡುಬಂದಿಲ್ಲ.",
    "notLookedUpYet": "ಇನ್ನೂ ಹುಡುಕಿಲ್ಲ.",
    "addressOptionalNeverBlocks": "ಐಚ್ಛಿಕ — ಹಿಂದಿನ ಪರದೆಯಲ್ಲಿ ವಿಳಾಸ ಟೈಪ್ ಮಾಡಬಹುದು. ಇದು ದೃಢೀಕರಣವನ್ನು ಎಂದಿಗೂ ತಡೆಯುವುದಿಲ್ಲ.",
    "locationSearchLabel": "ಸ್ಥಳ ಹುಡುಕಾಟ",
    "searchOptionalPinDirectly": "ಹುಡುಕಾಟ ಐಚ್ಛಿಕ — ನಕ್ಷೆಯಲ್ಲಿ ನೇರವಾಗಿ ಗಡಿ ಪಿನ್ ಮಾಡಿ.",
    "bluePinYourGps": "ನೀಲಿ ಪಿನ್ = ನಿಮ್ಮ GPS. ಫಾರ್ಮ್ ಸುತ್ತ ಗಡಿ ಮೂಲೆಗಳನ್ನು ಹಾಕಲು ನಕ್ಷೆ ಟ್ಯಾಪ್ ಮಾಡಿ.",
    "tapMapToDropPinsIndia": "ನಿಮ್ಮ ಫಾರ್ಮ್ ಗಡಿ ಸುತ್ತ ಪಿನ್‌ಗಳನ್ನು ಹಾಕಲು ನಕ್ಷೆ ಟ್ಯಾಪ್ ಮಾಡಿ (ಭಾರತ ಮಾತ್ರ)",
    "pinsCount": "{count} ಪಿನ್‌ಗಳು",
    "acresDisplay": "{acres} ಎಕರೆಗಳು",
    "min3Pins": "ಕನಿಷ್ಠ 3 ಪಿನ್‌ಗಳು",
    "undoLabel": "ರದ್ದುಮಾಡಿ",
    "clearLabel": "ತೆರವುಗೊಳಿಸಿ",
    "confirmBoundaryButton": "ಗಡಿ ದೃಢೀಕರಿಸಿ",
    "addMorePins": "ಇನ್ನೂ {count} ಪಿನ್{plural} ಸೇರಿಸಿ",
    "turnOnLocationToOpenMap": "ನಿಮ್ಮ ಪ್ರಸ್ತುತ ಸ್ಥಾನದಲ್ಲಿ ನಕ್ಷೆ ತೆರೆಯಲು ಲೊಕೇಶನ್ ಆನ್ ಮಾಡಿ.",
    "farmBoundaryMustBeInIndia": "ಫಾರ್ಮ್ ಗಡಿ ಭಾರತದೊಳಗೆ ಇರಬೇಕು.",
    "couldNotGetGpsEnableLocation": "GPS ಪಡೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಲೊಕೇಶನ್ ಸಕ್ರಿಯಗೊಳಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
    "gpsOutsideIndiaSearchVillage": "ನಿಮ್ಮ GPS ಭಾರತದ ಹೊರಗಿದೆ. ಗಡಿ ನಕ್ಷೆ ತೆರೆದು ಫಾರ್ಮ್ ಗ್ರಾಮ ಹುಡುಕಿ.",
    "yourGpsOutsideIndiaSearch": "ನಿಮ್ಮ GPS ಭಾರತದ ಹೊರಗಿದೆ. ಫಾರ್ಮ್ ಗ್ರಾಮ ಹುಡುಕಿ, ನಂತರ ಪಿನ್‌ಗಳನ್ನು ಗುರುತಿಸಿ.",
    "recordInteractionButton": "ಸಂವಹನ ರೆಕಾರ್ಡ್ ಮಾಡಿ",
    "editInteractionTitle": "ಸಂವಹನ ಸಂಪಾದಿಸಿ",
    "captureProspectFarmerDetails": "ನಿಮ್ಮ ಸಂವಾದದಿಂದ ಭಾವಿ ರೈತರ ವಿವರಗಳನ್ನು ಸೆರೆಹಿಡಿಯಿರಿ",
    "phoneNumberInput": "ಫೋನ್ ಸಂಖ್ಯೆ",
    "landLocationInput": "ಭೂಮಿ ಸ್ಥಳ",
    "landLocationHint": "ಗ್ರಾಮ / ಮಂಡಲ / ಪ್ರದೇಶ",
    "acresInput": "ಎಕರೆಗಳು",
    "currentCropInput": "ಪ್ರಸ್ತುತ ಬೆಳೆ",
    "specifyCrop": "ಬೆಳೆ ನಿರ್ದಿಷ್ಟಪಡಿಸಿ",
    "planningToTake": "ತೆಗೆದುಕೊಳ್ಳಲು ಯೋಜಿಸುತ್ತಿದ್ದಾರೆ",
    "monthSingular": "{count} ತಿಂಗಳು",
    "monthPlural": "{count} ತಿಂಗಳುಗಳು",
    "moLabel": "{count} ತಿಂ",
    "onboardingStatusLabel": "ಆನ್‌ಬೋರ್ಡಿಂಗ್ ಸ್ಥಿತಿ",
    "farmerReadyForOnboarding": "ರೈತ ಶೀಘ್ರದಲ್ಲೇ ಆನ್‌ಬೋರ್ಡಿಂಗ್‌ಗೆ ಸಿದ್ಧ",
    "needsMoreTime": "ನಿರ್ಧರಿಸುವ ಮೊದಲು ಇನ್ನಷ್ಟು ಸಮಯ ಬೇಕು",
    "stillEvaluating": "ಇನ್ನೂ ಮೌಲ್ಯಮಾಪನ ಅಥವಾ ಅನಿರ್ಧಿತ",
    "notesOptionalInput": "ಟಿಪ್ಪಣಿಗಳು (ಐಚ್ಛಿಕ)",
    "saveChanges": "ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿ",
    "saveInteractionButton": "ಸಂವಹನ ಉಳಿಸಿ",
    "pleaseSelectCropAndMonths": "ದಯವಿಟ್ಟು ಬೆಳೆ ಮತ್ತು ಯೋಜಿತ ತಿಂಗಳುಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ",
    "enterTheCropName": "ಬೆಳೆ ಹೆಸರು ನಮೂದಿಸಿ",
    "interactionUpdated": "ಸಂವಹನ ಅಪ್‌ಡೇಟ್ ಆಯಿತು",
    "interactionSaved": "ಸಂವಹನ ಉಳಿಸಲಾಗಿದೆ",
    "enterValidPhoneNumber": "ಮಾನ್ಯ ಫೋನ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ",
    "enterAcres": "ಎಕರೆಗಳನ್ನು ನಮೂದಿಸಿ",
    "selectACrop": "ಬೆಳೆ ಆಯ್ಕೆಮಾಡಿ",
    "interactionsTitle": "ಸಂವಹನಗಳು",
    "prospectConversationsCount": "{count} ಭಾವಿ ಸಂವಾದ{plural}",
    "searchNamePhoneLocation": "ಹೆಸರು, ಫೋನ್, ಸ್ಥಳ ಹುಡುಕಿ",
    "noInteractionsYetTitle": "ಇನ್ನೂ ಸಂವಹನಗಳಿಲ್ಲ",
    "logConversationsWithFarmers": "ಯೋಜನೆಗೆ ತರಲು ಪ್ರಯತ್ನಿಸುತ್ತಿರುವ ರೈತರೊಂದಿಗೆ ಸಂವಾದಗಳನ್ನು ದಾಖಲಿಸಿ",
    "recordButton": "ರೆಕಾರ್ಡ್",
    "planningMonthsLabel": "ಯೋಜನೆ {months} ತಿಂಗಳು{plural} · {date}",
    "visitReportTitle": "ಭೇಟಿ ವರದಿ",
    "pdfLabel": "PDF",
    "savingPdf": "ಉಳಿಸಲಾಗುತ್ತಿದೆ…",
    "downloadPDFButton": "PDF ಡೌನ್‌ಲೋಡ್",
    "preparingPdf": "PDF ತಯಾರಿಸಲಾಗುತ್ತಿದೆ…",
    "downloadReportPdf": "ವರದಿ PDF ಡೌನ್‌ಲೋಡ್",
    "reportPdfReadyToShare": "ವರದಿ PDF ಹಂಚಿಕೆ/ಉಳಿಸಲು ಸಿದ್ಧ",
    "fieldReportTitle": "ಕ್ಷೇತ್ರ ವರದಿ",
    "noStructuredReportAnswers": "ಈ ಭೇಟಿಗೆ ಯಾವುದೇ ರಚನಾತ್ಮಕ ವರದಿ ಉತ್ತರಗಳು ಉಳಿಸಲಾಗಿಲ್ಲ.",
    "additionalNotesLabel": "ಹೆಚ್ಚುವರಿ ಟಿಪ್ಪಣಿಗಳು",
    "voiceNoteTitle": "ಧ್ವನಿ ನೋಟ್",
    "voiceNoteRecordedButNotAvailable": "ಧ್ವನಿ ನೋಟ್ ರೆಕಾರ್ಡ್ ಆಗಿದೆ ಆದರೆ ಆಡಿಯೋ ಫೈಲ್ ಲಭ್ಯವಿಲ್ಲ.",
    "photosCountLabel": "ಫೋಟೋಗಳು ({count})",
    "executiveFieldLabel": "ಎಕ್ಸಿಕ್ಯೂಟಿವ್",
    "checkInLabel": "ಚೆಕ್-ಇನ್",
    "checkOutLabel": "ಚೆಕ್-ಔಟ್",
    "durationLabel": "ಅವಧಿ",
    "fetchingPhotosAssemblingPdf": "ಫೋಟೋಗಳನ್ನು ಪಡೆದು PDF ಜೋಡಿಸಲಾಗುತ್ತಿದೆ — ಕೆಲವು ನಿಮಿಷಗಳು ಬೇಕಾಗಬಹುದು…",
}


def load_arb(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def save_arb(path: Path, data: dict) -> None:
    # Keep readable JSON with trailing newline
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def fill_missing() -> None:
    en = load_arb(L10N / "app_en.arb")
    te = load_arb(L10N / "app_te.arb")
    kn = load_arb(L10N / "app_kn.arb")

    if "notVisitedYet" not in te:
        te["notVisitedYet"] = "ఇంకా సందర్శించలేదు"

    missing = [k for k in en if not k.startswith("@") and k not in kn]
    for k in missing:
        if k in KN:
            kn[k] = KN[k]
        else:
            # fallback: keep English so gen-l10n has the key; mark for review
            kn[k] = en[k]
            print(f"WARN no kn translation for {k}, using English")

    # Preserve metadata entries from en if present
    save_arb(L10N / "app_te.arb", te)
    save_arb(L10N / "app_kn.arb", kn)

    en_keys = [k for k in en if not k.startswith("@")]
    te_miss = [k for k in en_keys if k not in te]
    kn_miss = [k for k in en_keys if k not in kn]
    print(f"en={len(en_keys)} te_miss={len(te_miss)} kn_miss={len(kn_miss)}")


def build_exact_map(en: dict) -> dict[str, str]:
    """Map exact English UI string -> l10n getter name (no placeholders)."""
    m: dict[str, str] = {}
    for k, v in en.items():
        if k.startswith("@"):
            continue
        if not isinstance(v, str):
            continue
        if "{" in v or "}" in v:
            continue
        # Prefer first key if duplicates
        m.setdefault(v, k)
    return m


IMPORT_LINE = "import '{rel}shared/utils/l10n_ext.dart';\n"


def rel_import(dart_path: Path) -> str:
    # depth from lib/
    parts = dart_path.relative_to(ROOT / "lib").parts
    # file is under lib/... so go up len(parts)-1
    up = "../" * (len(parts) - 1)
    return up


def migrate_file(path: Path, exact: dict[str, str]) -> int:
    text = path.read_text(encoding="utf-8")
    original = text
    replacements = 0

    # Replace simple quoted strings that match ARB values inside common UI constructors
    # Only replace when the full string matches exactly.
    def repl_quote(match: re.Match) -> str:
        nonlocal replacements
        quote = match.group(1)
        val = match.group(2)
        key = exact.get(val)
        if not key:
            return match.group(0)
        replacements += 1
        # Use context.l10n — callers must have context in scope
        return f"{quote}l10n.{key}{quote}" if False else f"l10n.{key}"

    # Pattern: 'English text' or "English text" as standalone expression args
    # We replace 'Foo' with l10n.key when Foo is known — but only for
    # Text('..'), title: '..', label: '..', etc.

    patterns = [
        (re.compile(r"Text\(\s*'([^']+)'"), "Text("),
        (re.compile(r'Text\(\s*"([^"]+)"'), "Text("),
        (re.compile(r"label:\s*'([^']+)'"), "label: "),
        (re.compile(r'title:\s*\'([^\']+)\''), "title: "),
        (re.compile(r"subtitle:\s*'([^']+)'"), "subtitle: "),
        (re.compile(r"labelText:\s*'([^']+)'"), "labelText: "),
        (re.compile(r"hintText:\s*'([^']+)'"), "hintText: "),
        (re.compile(r"tooltip:\s*'([^']+)'"), "tooltip: "),
        (re.compile(r"message:\s*'([^']+)'"), "message: "),
        (re.compile(r"SnackBar\(\s*content:\s*Text\(\s*'([^']+)'\s*\)"), None),
    ]

    def replace_in_text(src: str) -> str:
        nonlocal replacements

        def sub_text(m: re.Match) -> str:
            nonlocal replacements
            val = m.group(1)
            key = exact.get(val)
            if not key:
                return m.group(0)
            replacements += 1
            return f"Text(l10n.{key}"

        def sub_named(prefix: str):
            def _sub(m: re.Match) -> str:
                nonlocal replacements
                val = m.group(1)
                key = exact.get(val)
                if not key:
                    return m.group(0)
                replacements += 1
                return f"{prefix}l10n.{key}"

            return _sub

        src = re.sub(r"Text\(\s*'([^']+)'", sub_text, src)
        src = re.sub(r'Text\(\s*"([^"]+)"', sub_text, src)
        src = re.sub(r"label:\s*'([^']+)'", sub_named("label: "), src)
        src = re.sub(r"title:\s*'([^']+)'", sub_named("title: "), src)
        src = re.sub(r"subtitle:\s*'([^']+)'", sub_named("subtitle: "), src)
        src = re.sub(r"labelText:\s*'([^']+)'", sub_named("labelText: "), src)
        src = re.sub(r"hintText:\s*'([^']+)'", sub_named("hintText: "), src)
        src = re.sub(r"tooltip:\s*'([^']+)'", sub_named("tooltip: "), src)
        src = re.sub(r"message:\s*'([^']+)'", sub_named("message: "), src)
        # const Text('x') -> Text(l10n.x)  (already handled if Text('))
        src = re.sub(r"const Text\(l10n\.", "Text(l10n.", src)
        src = re.sub(r"const SnackBar\(\s*content:\s*Text\(l10n\.", "SnackBar(content: Text(l10n.", src)
        return src

    new_text = replace_in_text(text)
    if new_text == original or replacements == 0:
        return 0

    # Ensure l10n import
    if "l10n_ext.dart" not in new_text and "app_localizations.dart" not in new_text:
        rel = rel_import(path)
        import_stmt = IMPORT_LINE.format(rel=rel)
        # insert after last import
        lines = new_text.splitlines(keepends=True)
        last_import = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                last_import = i
        lines.insert(last_import + 1, import_stmt)
        new_text = "".join(lines)

    # Ensure `final l10n = context.l10n;` in build methods that now use l10n.
    # Simple heuristic: if build( has context and uses l10n. but no final l10n
    if "l10n." in new_text and "final l10n = context.l10n" not in new_text and "final l10n = AppLocalizations" not in new_text:
        # Inject at start of build methods
        def inject_build(m: re.Match) -> str:
            body = m.group(0)
            if "l10n." not in body:
                return body
            # find opening brace of build
            return body  # handled below globally

        # Inject after `Widget build(BuildContext context` ... `{`
        new_text2 = re.sub(
            r"(Widget build\(BuildContext context(?:,\s*WidgetRef ref)?\)\s*\{)",
            r"\1\n    final l10n = context.l10n;",
            new_text,
            count=0,
        )
        # Avoid duplicate inject
        new_text2 = re.sub(
            r"(final l10n = context\.l10n;\s*){2,}",
            "final l10n = context.l10n;",
            new_text2,
        )
        new_text = new_text2

        # For State methods that use l10n outside build (snackbars), inject locally is harder —
        # use context.l10n. inline instead for those remaining if needed.

    # If we injected into multiple build methods that don't use l10n, remove unused?
    # Leave for analyzer.

    # Replace const constructors that break: const Foo( title: l10n.x ) 
    new_text = re.sub(r"const (GradientHeader|ShineNavItem|AdminMenuTile|InputDecoration)\(", r"\1(", new_text)

    path.write_text(new_text, encoding="utf-8")
    return replacements


def migrate_all() -> None:
    en = load_arb(L10N / "app_en.arb")
    exact = build_exact_map(en)
    total = 0
    files = 0
    lib = ROOT / "lib"
    for path in lib.rglob("*.dart"):
        s = str(path).replace("\\", "/")
        if "/l10n/" in s:
            continue
        n = migrate_file(path, exact)
        if n:
            files += 1
            total += n
            print(f"  {n:3d} {path.relative_to(ROOT)}")
    print(f"Migrated {total} exact strings across {files} files")


if __name__ == "__main__":
    fill_missing()
    migrate_all()
