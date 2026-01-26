# Grim Fable Mobile App

## Project Overview

**Project Name:** Grim Fable (working title)  
**Goal:** Create an AI Dungeon-like mobile app for Android with persistent character progression between adventure sessions  
**Target Platform:** Android (Flutter)  
**Development Approach:** 100% AI-assisted development  
**Timeline:** Iterative MVP → Feature additions → Google Play release

---

## Phase 0: Research & Architecture (CURRENT PHASE)

### Objectives
1. Analyze the open source AI Dungeon repository for useful patterns
2. Determine technical architecture for Flutter implementation
3. Create initial project structure

### Tasks

#### Task 0.1: Repository Analysis
**Goal:** Extract useful patterns from AI Dungeon open source repo without copying outdated code

**Steps:**
1. Clone/review the AI Dungeon 2 repository: `https://github.com/AIDungeon/AIDungeon`
2. Document the following patterns:
   - Story state management approach
   - User input processing flow
   - AI prompt engineering techniques
   - Save/load game architecture
   - Session/adventure structure
   - Content filtering mechanisms (if any)

**Deliverable:** Create `RESEARCH.md` with findings and recommendations

#### Task 0.2: Architecture Decision Document
**Goal:** Define the technical stack and architecture

**Key Decisions to Document:**
- Flutter project structure (feature-based vs layer-based)
- State management solution (Provider, Riverpod, Bloc, or GetX)
- Local storage solution (Hive, SQLite, SharedPreferences)
- AI API integration approach (http client, dio, etc.)
- Navigation structure
- Testing strategy

**Deliverable:** Create `ARCHITECTURE.md` with justified decisions

#### Task 0.3: Project Initialization
**Goal:** Set up the Flutter project with proper structure

**Steps:**
1. Create Flutter project: `flutter create grim_fable`
2. Set up folder structure:
   ```
   lib/
   ├── core/
   │   ├── models/
   │   ├── services/
   │   └── utils/
   ├── features/
   │   ├── character/
   │   ├── adventure/
   │   └── home/
   ├── shared/
   │   └── widgets/
   └── main.dart
   ```
3. Configure `pubspec.yaml` with initial dependencies
4. Set up basic theme and app structure

**Deliverable:** Initialized project that runs with "Hello World"

---

## Phase 1: MVP Core Features

### MVP Scope Definition

**INCLUDED in MVP:**
- ✅ Text-based adventure gameplay
- ✅ Single persistent character with basic attributes (name, backstory)
- ✅ Adventure sessions that save/load
- ✅ Simple, clean Android UI
- ✅ Free AI API integration (Claude or OpenAI)
- ✅ Basic chat-like input/output interface

**EXCLUDED from MVP (Future phases):**
- ❌ AI-generated artwork
- ❌ Complex character progression (levels, items, stats)
- ❌ Multiple character slots
- ❌ Curated/themed adventure templates
- ❌ Monetization features
- ❌ Advanced input filtering
- ❌ Elaborate UI animations

---

### Feature 1.1: Character Creation & Management

#### User Story
*As a player, I want to create a persistent character with a name and backstory so that my adventures feel personalized and continuous.*

#### Technical Requirements
- Create `Character` model with fields:
  - `id` (UUID)
  - `name` (String)
  - `backstory` (String, optional)
  - `createdAt` (DateTime)
  - `lastPlayedAt` (DateTime)
- Implement local storage persistence (Hive or SQLite)
- Create character creation UI screen
- Create character selection/home screen

#### Acceptance Criteria
- [ ] User can create a new character with name and optional backstory
- [ ] Character data persists between app restarts
- [ ] User can view their character on home screen
- [ ] Character's last played timestamp updates when starting adventure

#### Implementation Tasks
1. Define `Character` model class
2. Create `CharacterRepository` for data persistence
3. Build character creation form UI
4. Build home screen showing current character
5. Add validation (name required, character limits)
6. Write unit tests for character model and repository

---

### Feature 1.2: AI Integration Service

#### User Story
*As the system, I need to connect to an AI API to generate story responses based on player input.*

#### Technical Requirements
- Create `AIService` abstraction layer
- Implement API client for chosen LLM (Claude/OpenAI)
- Design prompt templates for story generation
- Handle API errors gracefully
- Add loading states

#### Acceptance Criteria
- [ ] Service successfully calls AI API with user input
- [ ] Responses are returned as formatted text
- [ ] API errors display user-friendly messages
- [ ] Loading indicator shows during API calls
- [ ] Prompt engineering maintains story context

#### Implementation Tasks
1. Create `AIService` interface/abstract class
2. Implement concrete service (e.g., `ClaudeAIService`)
3. Store API key securely (environment variable or config)
4. Design base prompt template for adventure storytelling
5. Add retry logic for failed requests
6. Create mock AI service for testing
7. Write integration tests

#### Prompt Engineering Notes
**Base System Prompt Structure:**
```
You are a creative storyteller for an interactive text adventure called Grim Fable.

Character: {character_name}
Backstory: {character_backstory}

Current Story Context:
{previous_story_beats}

Player Action: {user_input}

Generate the next story segment (2-4 paragraphs) that:
- Responds naturally to the player's action
- Maintains narrative consistency
- Offers subtle choices or paths forward
- Matches a dark fantasy tone
- Keeps the character as the protagonist
```

---

### Feature 1.3: Adventure Session Management

#### User Story
*As a player, I want to start new adventures and continue previous ones so I can play in multiple sessions.*

#### Technical Requirements
- Create `Adventure` model with fields:
  - `id` (UUID)
  - `characterId` (foreign key)
  - `title` (String, auto-generated or user-defined)
  - `storyHistory` (List of story segments)
  - `createdAt` (DateTime)
  - `lastPlayedAt` (DateTime)
  - `isActive` (bool)
- Implement adventure persistence
- Create adventure list UI
- Handle multiple adventures per character

#### Acceptance Criteria
- [ ] User can start a new adventure
- [ ] Adventures save automatically during play
- [ ] User can view list of past adventures
- [ ] User can resume an adventure from where they left off
- [ ] Adventure history maintains full context

#### Implementation Tasks
1. Define `Adventure` and `StorySegment` models
2. Create `AdventureRepository` for persistence
3. Build "Start New Adventure" flow
4. Build adventure list/history screen
5. Implement auto-save mechanism
6. Add "Continue" and "New Adventure" buttons on home screen
7. Write unit tests for adventure management

---

### Feature 1.4: Core Gameplay Interface

#### User Story
*As a player, I want a chat-like interface to input actions and read story responses.*

#### Technical Requirements
- Create adventure gameplay screen with:
  - Scrollable story display (chat bubbles or messages)
  - Text input field for player actions
  - Send button
  - Loading indicator during AI generation
- Display distinction between story text and player input
- Auto-scroll to latest message
- Handle keyboard behavior properly

#### Acceptance Criteria
- [ ] Player can type and submit actions
- [ ] Story responses appear as distinct messages
- [ ] Interface scrolls smoothly to new content
- [ ] Loading state is clear during AI processing
- [ ] Keyboard doesn't obscure input field
- [ ] Input field clears after submission

#### Implementation Tasks
1. Design UI layout (Figma mockup or whiteboard)
2. Create `AdventureScreen` widget
3. Build message list widget (ListView with custom tiles)
4. Create text input area with send button
5. Implement auto-scroll behavior
6. Add loading overlay/indicator
7. Style story messages vs player messages differently
8. Handle edge cases (empty input, API errors)
9. Add basic error handling UI

---

### Feature 1.5: Game Loop & State Management

#### User Story
*As the system, I need to coordinate user input, AI responses, and state updates to create a smooth gameplay experience.*

#### Technical Requirements
- Implement state management solution (Provider/Riverpod/Bloc)
- Create game loop flow:
  1. User submits action
  2. Add action to story history
  3. Call AI service with full context
  4. Receive and display response
  5. Save adventure state
  6. Wait for next input
- Handle story context window (limit history sent to AI)

#### Acceptance Criteria
- [ ] Gameplay flow works end-to-end
- [ ] State updates trigger UI rebuilds correctly
- [ ] Adventure auto-saves after each turn
- [ ] Context window prevents token limit issues
- [ ] App handles interruptions (phone call, app background)

#### Implementation Tasks
1. Set up state management provider
2. Create `AdventureController`/`AdventureBloc`
3. Implement action submission flow
4. Implement response handling flow
5. Add context window management (keep last N turns)
6. Implement auto-save on each turn
7. Add app lifecycle handling (pause/resume)
8. Write integration tests for complete flow

---

## Phase 2: Polish & Testing (Pre-Release)

### Feature 2.1: UI/UX Refinement
- Improve visual design (colors, typography, spacing)
- Add subtle animations (fade-ins, transitions)
- Improve error messages and empty states
- Add app icon and splash screen
- Ensure Material Design compliance

### Feature 2.2: Testing & Bug Fixes
- Comprehensive manual testing on physical Android device
- Fix crashes and edge cases
- Test with various input types
- Performance optimization (memory leaks, lag)
- Test app lifecycle transitions

### Feature 2.3: Documentation
- Create user-facing README
- Add in-app tutorial or help screen
- Document known limitations
- Create privacy policy (even for free app)

---

## Phase 3: Google Play Preparation

### Task 3.1: App Store Assets
- Design app icon (512x512)
- Create feature graphic (1024x500)
- Take screenshots (at least 2, up to 8)
- Write app description
- Set up app metadata

### Task 3.2: Release Build
- Configure app signing
- Set proper version numbers
- Remove debug code/logs
- Build release APK/AAB
- Test release build thoroughly

### Task 3.3: Google Play Console Setup
- Create developer account (if needed)
- Fill out store listing
- Set up content rating questionnaire
- Add privacy policy URL
- Submit for review

---

## Future Phases (Post-MVP)

### Phase 4: Visual Enhancements
- Integrate AI art generation API
- Character portrait generation
- Scene illustrations
- UI theming improvements

### Phase 5: Advanced Features
- Multiple character slots
- Character stats and progression
- Item inventory system
- Themed adventure templates
- Input filtering and content moderation

### Phase 6: Monetization
- Ad integration (Google AdMob)
- Premium subscription model
- In-app purchases (cosmetics, API credits)

### Phase 7: Social & Expansion
- Share adventures feature
- Community-created scenarios
- Cloud save/sync
- iOS version

---

## Development Guidelines

### Code Quality Standards
- Follow Flutter/Dart style guide
- Write clear, self-documenting code
- Add comments for complex logic
- Use meaningful variable names
- Keep functions small and focused

### Git Workflow
- Use feature branches (`feature/character-creation`)
- Write descriptive commit messages
- Commit frequently with logical chunks
- Create tags for phase completions

### Testing Strategy
- Unit tests for models and business logic
- Widget tests for UI components
- Integration tests for critical flows
- Manual testing on real devices before releases

### AI Development Tips for Jules
- Break down tasks into smallest possible chunks
- Test each component independently before integration
- Use print debugging generously during development
- Reference Flutter documentation for widget usage
- Search for Flutter packages that solve common problems
- Don't over-engineer - MVP means simple and working

---

## Dependencies Reference

### Required Packages (add to pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1  # or riverpod/bloc based on architecture decision
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # API Calls
  http: ^1.1.0
  
  # Utilities
  uuid: ^4.1.0
  intl: ^0.18.1
  
  # UI Enhancements
  flutter_markdown: ^0.6.18  # for formatted story text

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.6
  mockito: ^5.4.4
```

---

## API Integration Notes

### Recommended Free Tier APIs for Development
1. **OpenAI GPT-3.5-turbo** - $0.002 per 1K tokens (free credits available)
2. **Anthropic Claude** - Limited free tier for development
3. **Google Gemini** - Generous free tier

### API Key Security
- Never commit API keys to Git
- Use environment variables or `--dart-define`
- Consider using Firebase Remote Config for production

### Prompt Optimization
- Keep context window under 4K tokens for free tiers
- Summarize old story beats instead of sending full history
- Cache character info in system prompt

---

## Success Metrics

### MVP Launch Criteria
- [ ] App builds and installs on Android device
- [ ] User can create character
- [ ] User can start adventure and interact for 10+ turns
- [ ] Adventures save and can be resumed
- [ ] No critical bugs or crashes
- [ ] Basic UI is functional and understandable
- [ ] Ready for Google Play submission

### Post-Launch Goals
- 100 installs in first month
- Average session length > 10 minutes
- Crash-free rate > 99%
- User feedback collected
- Iteration plan based on feedback

---

## Troubleshooting Guide

### Common Issues & Solutions

**Issue: AI responses are too long/expensive**
- Solution: Add max_tokens parameter to API calls (300-500 tokens)

**Issue: Story loses context quickly**
- Solution: Implement sliding context window with summaries

**Issue: App performance degrades with long adventures**
- Solution: Paginate story history, only load recent segments

**Issue: Flutter build errors**
- Solution: Run `flutter clean && flutter pub get`

**Issue: API rate limiting**
- Solution: Add exponential backoff retry logic

---

## Questions for Human Developer

As Jules works through this, flag these decision points:

1. **State Management**: Should I use Provider, Riverpod, or Bloc? (Recommend based on Phase 0 research)
2. **AI API**: Which free API should I start with? (OpenAI, Claude, or Gemini?)
3. **Theme/Style**: Any color preferences for dark fantasy aesthetic?
4. **Adventure Starting**: Should adventures start with a generated scenario or blank slate?
5. **Character Backstory**: Required or optional during creation?

---

## Getting Started (For Jules)

1. **Start with Phase 0**: Complete repository analysis first
2. **Read ARCHITECTURE.md**: After creating it, follow those decisions
3. **Build incrementally**: Each feature should be fully working before moving on
4. **Test on device**: Deploy to Android device/emulator frequently
5. **Ask questions**: Flag any unclear requirements

**First Command to Run:**
```bash
git clone https://github.com/AIDungeon/AIDungeon
# Review the code, then create RESEARCH.md with findings
```

---

## Project Timeline Estimate

- **Phase 0** (Research): 1-2 sessions
- **Phase 1** (MVP Development): 8-12 sessions
- **Phase 2** (Polish): 2-3 sessions
- **Phase 3** (Release Prep): 1-2 sessions

**Total Estimated Development Time**: 12-19 AI coding sessions

---

## Contact & Feedback

This is a living document. Update it as you learn and iterate. Good luck building Grim Fable! 🗡️📖
