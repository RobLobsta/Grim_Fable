# RESEARCH.md: AI Dungeon 2 Repository Analysis

## 1. Story State Management Approach
AI Dungeon 2 uses a `Story` class to encapsulate the state of an adventure. Key components include:
- `story_start`: The initial prompt and first AI response.
- `actions`: A list of strings representing player inputs.
- `results`: A list of strings representing the AI's responses to those actions.
- `context`: A base string that provides permanent background information to the AI.
- `game_state`: A dictionary for potential metadata (though underutilized in the basic version).

**Recommendation for Grim Fable:**
Follow a similar history-based approach. Use a `List<StorySegment>` in the `Adventure` model, where each segment contains both the player's action and the AI's response.

## 2. User Input Processing Flow
Player input is processed to maintain a consistent second-person narrative:
- Basic cleaning (stripping whitespace).
- Command detection (e.g., `/save`, `/revert`).
- Automatic prefixing: If the input doesn't start with "You" or "I", it's often prefixed with "You " to fit the "You [action]" pattern.
- Person conversion: Transforming "I" to "You" to keep the story perspective consistent.

**Recommendation for Grim Fable:**
Implement a "Player Action" processing layer that ensures inputs are formatted into a coherent narrative flow before being sent to the AI and saved to history.

## 3. AI Prompt Engineering Techniques
Prompts are constructed dynamically:
- **Base Context**: Permanent information about the world/character.
- **Story History**: A sliding window of recent actions and results is appended to the context.
- **Current Action**: The player's latest input is appended at the end.
- **Trimming**: The system cuts trailing incomplete sentences from the AI output to improve readability.

**Recommendation for Grim Fable:**
Use a "System Prompt" for character backstory and world rules. Implement a sliding context window (e.g., last 10-15 exchanges) to stay within token limits while maintaining coherence.

## 4. Save/Load Game Architecture
- **Serialization**: The `Story` object is converted to a JSON dictionary.
- **Persistence**: JSON files are saved locally using a UUID-based filename (e.g., `story<UUID>.json`).
- **Cloud Sync**: The original repo had hooks for cloud storage (Google Cloud Storage), though later versions reverted to local-only for simplicity.

**Recommendation for Grim Fable:**
Use `Hive` for local storage in Flutter. Each `Adventure` should be stored as a Hive object. Character data should be stored separately and linked by ID.

## 5. Session/Adventure Structure
The game flow is managed by a `StoryManager`:
- It handles the transition between the "Splash Screen" (New Game/Load Game) and the "Active Gameplay".
- It coordinates between the LLM generator and the story state.

**Recommendation for Grim Fable:**
Implement an `AdventureController` (using Provider/Riverpod) that manages the lifecycle of a session, from initialization to auto-saving after each turn.

## 6. Content Filtering Mechanisms
- **Word List**: A `censored_words.txt` file is used to filter or flag inappropriate content.
- **Toggling**: Users can turn the censor on or off via commands.

**Recommendation for Grim Fable:**
MVP should focus on a "Dark Fantasy" tone via the system prompt. Advanced filtering can be deferred to post-MVP phases.

---
*Findings extracted from `https://github.com/AIDungeon/AIDungeon` (Commit: Latest as of analysis)*
