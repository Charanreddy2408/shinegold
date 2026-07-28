import json
from pathlib import Path

L = Path("lib/l10n")
extra = {
    "yourCoverage": ("YOUR COVERAGE", "మీ కవరేజ్", "ನಿಮ್ಮ ಕವರೇಜ್"),
    "networkOverview": ("Network Overview", "నెట్‌వర్క్ అవలోకనం", "ನೆಟ್‌ವರ್ಕ್ ಅವಲೋಕನ"),
    "acrossAllFieldOperations": (
        "Across all field operations",
        "అన్ని ఫీల్డ్ కార్యకలాపాలలో",
        "ಎಲ್ಲಾ ಕ್ಷೇತ್ರ ಕಾರ್ಯಾಚರಣೆಗಳಲ್ಲಿ",
    ),
    "totalFieldVisitsLogged": (
        "Total field visits logged",
        "మొత్తం ఫీల్డ్ సందర్శనలు నమోదు",
        "ಒಟ್ಟು ಕ್ಷೇತ್ರ ಭೇಟಿಗಳು ದಾಖಲು",
    ),
    "fieldActivity": ("Field activity", "ఫీల్డ్ కార్యకలాపం", "ಕ್ಷೇತ್ರ ಚಟುವಟಿಕೆ"),
    "harvestSoon": ("Harvest soon", "త్వరలో పంట", "ಶೀಘ್ರದಲ್ಲಿ ಬೆಳೆ ಕೊಯ್ಲು"),
    "farmNetworkIndia": (
        "Farm Network — India",
        "ఫారమ్ నెట్‌వర్క్ — భారత్",
        "ಫಾರ್ಮ್ ನೆಟ್‌ವರ್ಕ್ — ಭಾರತ",
    ),
    "pinchToZoomHint": (
        "Pinch to zoom · drag to pan · tap a pin for farm details",
        "జూమ్‌కు పించ్ · పాన్‌కు డ్రాగ్ · వివరాలకు పిన్ ట్యాప్",
        "ಝೂಮ್‌ಗೆ ಪಿಂಚ್ · ಪ್ಯಾನ್‌ಗೆ ಡ್ರ್ಯಾಗ್ · ವಿವರಗಳಿಗೆ ಪಿನ್ ಟ್ಯಾಪ್",
    ),
    "viewFarmDetails": ("View Farm Details", "ఫారమ్ వివరాలు చూడండి", "ಫಾರ್ಮ್ ವಿವರಗಳನ್ನು ನೋಡಿ"),
    "indiaFarmMap": ("India farm map", "భారత ఫారమ్ మ్యాప్", "ಭಾರತ ಫಾರ್ಮ್ ನಕ್ಷೆ"),
    "fullScreenMap": ("Full screen map", "ఫుల్ స్క్రీన్ మ్యాప్", "ಪೂರ್ಣಪರದೆ ನಕ್ಷೆ"),
    "resetView": ("Reset view", "వ్యూరీసెట్", "ವೀಕ್ಷಣೆ ಮರುಹೊಂದಿಸಿ"),
    "statesLabel": ("States", "రాష్ట్రాలు", "ರಾಜ್ಯಗಳು"),
    "contactAndIdentity": ("Contact & Identity", "సంప్రదింపు & గుర్తింపు", "ಸಂಪರ್ಕ ಮತ್ತು ಗುರುತು"),
    "verifiedAdministrator": (
        "Verified Administrator",
        "ధృవీకరించిన అడ్మిన్",
        "ಪರಿಶೀಲಿತ ಅಡ್ಮಿನ್",
    ),
    "fullAccessFarmsTeam": (
        "Full access to farms, team & harvest data",
        "ఫారమ్‌లు, టీమ్ & పంట డేటాకు పూర్తి యాక్సెస్",
        "ಫಾರ್ಮ್‌ಗಳು, ತಂಡ ಮತ್ತು ಬೆಳೆ ಡೇಟಾಗೆ ಪೂರ್ಣ ಪ್ರವೇಶ",
    ),
    "visitsCount": ("{count} visits", "{count} సందర్శనలు", "{count} ಭೇಟಿಗಳು"),
    "farmsCount": ("{count} farms", "{count} ఫారమ్‌లు", "{count} ಫಾರ್ಮ್‌ಗಳು"),
    "recordsCount": ("{count} records", "{count} రికార్డులు", "{count} ದಾಖಲೆಗಳು"),
    "minOnSite": ("{count} min on site", "{count} నిమి సైట్‌లో", "{count} ನಿಮಿ ಸೈಟ್‌ನಲ್ಲಿ"),
    "onboardFarmTitleCase": ("Onboard Farm", "ఫారమ్ ఆన్‌బోర్డ్", "ಫಾರ್ಮ್ ಆನ್‌ಬೋರ್ಡ್"),
    "photosLabel": ("Photos", "ఫోటోలు", "ಫೋಟೋಗಳು"),
    "copyReport": ("Copy report", "రిపోర్ట్ కాపీ", "ವರದಿ ನಕಲಿಸಿ"),
    "reportCopied": ("Report copied", "రిపోర్ట్ కాపీ అయింది", "ವರದಿ ನಕಲಿಸಲಾಗಿದೆ"),
    "couldNotOpenDialer": (
        "Could not open phone dialer",
        "ఫోన్ డయలర్ తెరవలేకపోయాం",
        "ಫೋನ್ ಡಯಲರ್ ತೆರೆಯಲಾಗಲಿಲ್ಲ",
    ),
    "couldNotOpenWhatsApp": (
        "Could not open WhatsApp",
        "వాట్సాప్ తెరవలేకపోయాం",
        "ವಾಟ್ಸಾಪ್ ತೆರೆಯಲಾಗಲಿಲ್ಲ",
    ),
    "tapToRecordMax": (
        "Tap to record (max {max})",
        "రికార్డ్‌కు ట్యాప్ (గరిష్టం {max})",
        "ರೆಕಾರ್ಡ್‌ಗೆ ಟ್ಯಾಪ್ (ಗರಿಷ್ಠ {max})",
    ),
    "acresLower": ("acres", "ఎకరాలు", "ಎಕರೆಗಳು"),
}

meta = {
    "visitsCount": {"placeholders": {"count": {"type": "int"}}},
    "farmsCount": {"placeholders": {"count": {"type": "int"}}},
    "recordsCount": {"placeholders": {"count": {"type": "int"}}},
    "minOnSite": {"placeholders": {"count": {"type": "int"}}},
    "tapToRecordMax": {"placeholders": {"max": {"type": "String"}}},
}

for loc, idx in [("app_en.arb", 0), ("app_te.arb", 1), ("app_kn.arb", 2)]:
    p = L / loc
    data = json.loads(p.read_text(encoding="utf-8"))
    for k, vals in extra.items():
        if k not in data:
            data[k] = vals[idx]
            if loc == "app_en.arb" and k in meta:
                data[f"@{k}"] = meta[k]
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print("ok", len(extra))
