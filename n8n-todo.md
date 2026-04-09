# TODO

- Keine eigenmächtigen Änderungen ohne vorher Rücksprache zu halten
-

## Theme Provider

Bitte eine kurze THEME-PROVIDER.md schreiben und die Implementierung des Theme Providers über Shadcn erklären. Wo und wie er eingesetzt wird, sodass es funktioniert wie es funktioniert, sodass Dies durch die Daten in einem anderen Projekt implementiert werden kann wo die gleichen shadcn dependencys benutzt werden, aber der toggle nicht vollständig funktioniert

## Übergreifend

### Globaler Header

- braucht bitte eine border bottom in der identischen Farbe wie die broder der card. Abgeleitet vom shadcn theme, sodass der theme toggle
- schrift bitte auf bold setzten vom app bar title übergreifend

### Allgemeine Sonner Anpassungen

- Bitte mit einem lucide "copy" icon versehen
- Bitte in drei States aufteilen. Sucess wird die schrift grün, error die schrift rot, info die schrift bleibt schwarz (copy to clipboard z.B. ist hinweiß). nur die schrift!

### Datumsangaben Global

Bitte eine utils funktion anlegen die an jeder Stelle benutzt wird und zentral verrwaltbar ist für jegliche datetimes, sodass man ein human readable format hat ("17.09.2017 - 17:30")

## Pages

### Home-Page

- Beschreibung Audit: "Check access and health)
- Beschreibung Workflows: "Browse your workflows"
- Beschreibung Executions: "Inspect recent executions"
- Beschreibung Credentials: "Manage your secret keys"
- beschreibung Settings: "Manage your app settings"
- Beschreibung Users: "See user details"

### Workflow-Page

- Als shadcn-Cards machen wie die Cards die du auf dem home screen findest. In der zweiten Zeite im gleichen Stil wie die home Seite bitte einen Muted Untertitel. Hier erstmal einen generischen Platzhalter für alle Elemente

-

### Executions-Page

- oben Rechts in der App bar, gespiegelt zuum Back Button positioniert ein refresh button per lucide icons (in voller funktion - einfach page einmal reloaden)
- Ein Tab bestehend aus Zwei Auswahlen wie in workflow details vom dtyling. "Finished" und "Pending". die aktuelle ansicht unter Pending leer lassen, aber eigene leere Ansicht wenn man über den Tab navigiert.

### Executions-Details-Page

- Reihenfolge der rows ändern. Ganz oben Workflow ID, dann der Rest wie auch aktuell

### Credential-Edit-Page

- type und id müssen aus dem frontend verschwinden.
- created und updated felder bitte einmal mit einem seperator davor ans ende der maske setzen.
- Additiv einen button destructive darunter setzen der
- Im App Bar titel sollten hier statische texte stehen. "Add Credential" und "Edit Credential" respectivly

### Credetnail-Add-Choose-Page

- Beim Auswahldialog beim anlegen von Credentials auch nur "Choose Credential" ohne "type" am ende
- Anstatt eines dropdown auswahl dialogs bitte eine suchleiste an gleicher stelle in gleicher größe

### User-List Page

- gleicher stil der Karten wie im home. erste zeile fett, zweite muttet, icons müssen gerückt werden.
- Hier im Card titel einmal name und im untertitel nur e-mail.
- für das icon wird ein ordner von mir angelegt mit svgs, die entsprechend der value des api response objekts benannt werden, sodass die icons dynamisch nach rolle gesetzt werden, in mit fallback aufs aktuelle icon. (referenz dynamische credential icons)
- Hier muss auch ein plus oben rechts in der ecke sein identisch zu Data Tables um nden Add User Dialog aufzurufen (der muss noch erstellt und gewired werden)
- Auch hier Im App Bar titel sollten hier statische texte stehen. "Add User" und "Edit User" respectivly

### Edit Users Page

- Überschrift nicht die E-Mail Adresse sondern ein statisches "Edit User"
- Muss mit Labels und Inputs gefüllt sein.
- Der Deletebutton muss als varient destructive unter dem letzte und nur der speichern button oben rechts in der Ecke

### Audit-Page

- Einen toten "Share" button oben rechts wo normallerweise speichern oder add ist mit dem lucide icon "share"
- Fürs erste bitte einfach das komplette json welcher auf dieser page dargestellt wird ins clipboard copieren wenn der button geklickt wird (sonner nicht vergessen)
- Und einmal titel und untertitel aus der card nehmen.nur das json sollte dort drin sein und auch nicht mehr

### Settings-Page

- Seperator etwas schmaller (Vorlage Seperator auf der Credential Pages)

### Workflow-Page

- Einen aktuell toten add button hinzufügen in der app bar, wie gewohnt

### Datatables-Page

- Vermutlich gleicher Grund wie der Fehler in der nächsten Sektion beschrieben. es sind 0 rows obwohl es definitv nicht 0 rows sind

### Datatable-Edit/Details-Page

- Wirft aktuell einen "Error: Exception: HTTP 400"
