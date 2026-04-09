TODO: Firebase Push Notifications (FCM) Integration

🎯 Ziel

Push Notifications (Android → später iOS) in bestehende App integrieren
Trigger: n8n → FCM → Device

🧱 Voraussetzungen

    Firebase Projekt existiert
    FCM aktiviert
    n8n Setup fertig (HTTP + Auth getestet)
    App hat bereits Settings Screen

🔥 1. Firebase in Flutter App integrieren

    Package hinzufügen:

firebase_core: latest

firebase_messaging: latest

    Firebase initialisieren (App Start)

await Firebase.initializeApp();

📲 2. Berechtigungen (Android)

    AndroidManifest.xml prüfen:

<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    Runtime Permission (Android 13+):

await FirebaseMessaging.instance.requestPermission();

🔑 3. Device Token holen

    Token abrufen:

final token = await FirebaseMessaging.instance.getToken();

print(token);

    Token speichern:
        lokal (z. B. SharedPreferences)
        optional: Backend senden (später)

⚙️ 4. Settings Screen erweitern

UI

    Toggle hinzufügen:
        Label: "Push Notifications"
        Default: OFF

Logik

Toggle ON:

    Permission anfragen
    Token holen
    Status speichern (enabled = true)

Toggle OFF:

    Notifications deaktivieren:

await FirebaseMessaging.instance.deleteToken();

    Status speichern (enabled = false)

📡 5. Topic (optional, aktuell NICHT nötig)

    (skip für 1:1 Setup)

🔔 6. Notification Handling

Foreground:

FirebaseMessaging.onMessage.listen((message) {

// TODO: Snackbar / Dialog anzeigen

});

Background:

    Handler definieren

🧪 7. Test vorbereiten

    echten Token ausgeben lassen
    Token kopieren → in n8n einsetzen

🔗 8. n8n Integration

    HTTP Node Body anpassen:

{

"message": {

    "token": "DEVICE_TOKEN",

    "notification": {

      "title": "Error",

      "body": "Workflow failed"

    }

}

}

✅ 9. Test durchführen

    App starten
    Toggle aktivieren
    Token log prüfen
    n8n Request senden
    Notification erscheint

⚠️ Edge Cases

    Token kann sich ändern → regelmäßig neu holen
    Permission verweigert → UI Feedback
    App im Hintergrund / geschlossen testen

🚀 Optional später

    mehrere Geräte unterstützen
    Token an Backend speichern
    iOS Setup (APNs)
    unterschiedliche Notification-Typen (error, warning)

🧠 Minimal Definition of Done

    Toggle im Settings Screen funktioniert
    Token wird generiert
    n8n kann Push senden
    Notification kommt auf Gerät an
