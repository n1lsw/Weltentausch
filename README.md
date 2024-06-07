# Wenn das Skript ausgeführt wird:

Vergleiche die letzten Zeitstempel ("last modified") zwischen...

* lokalen Speicherdateien für das Spiel Valheim und
* remote Speicherdateien (Valheim) in einem Discord-Kanal, in dem ich die Dateien mit anderen austausche

Wenn die lokalen Dateien neuer sind, poste die Dateien in den Kanal <br />
Wenn die remote Dateien neuer sind, lade sie herunter, d.h. überschreibe die vorhandenen Dateien


# ToDo:

## Disord erlaubt max. 25 MB pro POST Anfrage
* file chunks: https://blog.idera.com/database-tools/splitting-large-files-in-smaller-parts-part-1/
* Cloud service &rarr; gibt es eine API? Was ist das Upload Limit?
* Netzwerk über Internet mit beteiligten PCs und dann als SCP o.ä. schicken &rarr; würde mich einfach interessieren, wie das geht

## Soll das Script permanent laufen, z.B. direkt bei PC Neustart?
* Das Script könnte auf dem Spiel Host den Savegame Ordner "überwachen" und immer, wenn es eine neue Datei gibt, diese hochladen/verschicken
* Der Download müsste, während das Spiel läuft, verboten sein
* Beim Download müsste man im Allgemeinen nochmal **prüfen**, ob Datein überschrieben werden (außerhalb des Spiels ist das ja erwünscht, um einen neuen Stand zu holen)


