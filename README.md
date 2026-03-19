# Raumplaner

Ein interaktiver 3D-Raumplaner, entwickelt mit **Godot 4.5**.  
Möbel können manuell in einem anpassbaren Raum platziert oder automatisch durch einen Layout-Algorithmus angeordnet werden.

## Features

- **3D-Raumansicht** mit orbitierender Kamera (Drehen, Zoomen)
- **Möbel-Auswahl**: Bett, Schreibtisch, Regal, Pinnwand
- **Manuelle Platzierung**: Möbel per Mausklick im Raum positionieren
- **Möbel bearbeiten**: Grösse anpassen oder Möbelstück löschen (Klick auf Objekt)
- **Raum bearbeiten**: Breite, Tiefe und Höhe des Raums per Klick auf den Boden/Decke einstellen
- **Automatische Anordnung** per Algorithmus-Picker:
  - **V1** – Regelbasiert, platziert Möbel sofort an Wänden (grösste zuerst, zufällige Wandreihenfolge)
  - **V2** – Schrittweise, animierte Platzierung mit Verschiebungslogik für Überlappungen

## Voraussetzungen

- [Godot Engine 4.5](https://godotengine.org/download)

## Projekt öffnen & starten

1. Godot 4.5 starten und **„Import"** wählen.
2. Die Datei `project.godot` aus diesem Verzeichnis auswählen.
3. Das Projekt wird geladen. Zum Ausführen **F5** drücken oder auf den Play-Button klicken.

## Bedienung

| Aktion | Eingabe |
|---|---|
| Kamera drehen | Rechte Maustaste gedrückt halten + Maus bewegen |
| Kamera zoomen | Mausrad |
| Möbel platzieren | Möbel-Button auswählen, dann Linksklick im Raum |
| Platzierung abbrechen | Rechtsklick oder `Esc` |
| Möbel bearbeiten / löschen | Linksklick auf platziertes Möbelstück |
| Raum bearbeiten | Linksklick auf Boden oder Decke |
| Layout generieren | Algorithmus wählen → **Generate!** klicken |

## Projektstruktur

```
scripts/
  arrangers/      # Layout-Algorithmen (V2 wird verwendet)
  furniture/      # Basisklasse für Möbelobjekte
  ui/             # UI-Steuerung (Möbelauswahl, Algorithmus-Picker, Edit-Dialoge)
  camera.gd       # Kamerasteuerung
  room.gd         # Raumdefinition und -skalierung
furniture/        # Möbel-Szenen (.tscn)
ui/               # Icon-Assets
```
