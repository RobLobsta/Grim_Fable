# Saga Mode Design Document

## Overview
Saga Mode is a guided narrative experience in Grim Fable that allows players to relive iconic stories from established lore (starting with the Diablo series). Unlike the free-form Adventure Mode, Saga Mode uses predefined story structures stored in JSON files to ensure the narrative follows a specific path while still allowing for player agency and AI-driven creativity.

## Core Components

### 1. JSON Data Structure
Each Saga is defined by a JSON file containing metadata and a series of chapters.

```json
{
  "id": "saga_id",
  "title": "Saga Title",
  "series": "Series Name",
  "description": "Longer description of the saga.",
  "chapters": [
    {
      "id": "ch1",
      "title": "Chapter Title",
      "startingPrompt": "Initial text for the chapter.",
      "plotAnchors": [
        "Key event 1 that must occur",
        "Key event 2 that must occur"
      ],
      "importantNouns": [
        "Person Name",
        "Place Name",
        "Artifact Name"
      ],
      "hiddenGoal": "The AI's internal objective to progress the story.",
      "mechanics": {
        "key": "value"
      }
    }
  ]
}
```

### 2. Plot Anchor System
Plot Anchors are critical narrative milestones.
- The AI is briefed on these anchors at the start of a chapter.
- The AI is nudged to weave these events into the story based on player actions.
- A chapter is considered "complete" when the AI confirms that all anchors (or the primary goal) have been addressed.

### 3. Lore Lexicon (Noun Priming)
To prevent the AI from hallucinating or forgetting key names:
- The `important_nouns` list is injected into the system prompt.
- This ensures that characters like "Sadun Tryst" or locations like "Lut Gholein" are consistently referenced.

### 4. Saga-Specific Mechanics
Sagas can introduce unique gameplay variables. For *Legacy of Blood*, we implement:
- **Armor's Influence (Corruption)**: A numerical value (0.0 to 1.0) representing Norrec's loss of control to Bartuc's armor.
- Higher corruption levels will alter the AI's tone and may restrict player choices to more aggressive or "bloodthirsty" options.

## UI/UX Design

### 1. The Scroll Aesthetic
The Saga Mode interface will feature a "Tattered Scroll" look:
- Parchment background textures.
- Irregular, rough edges.
- Calligraphic font choices for headers.
- Ink-bleed effects on text.

### 2. The Chronicle
A dedicated view within the Saga screen that allows players to:
- Review completed chapters.
- See which plot anchors have been discovered/witnessed.
- Track their "Corruption" or other saga-specific metrics.

## AI Implementation Details
The `SagaNotifier` will extend the existing adventure logic but with a modified system prompt:
- **Mode Identification**: "You are now in Saga Mode: [Saga Title]."
- **Lore Strictness**: "You must adhere to the provided Lore Lexicon and Plot Anchors."
- **Perspective**: "The player is roleplaying as [Protagonist Name]."
