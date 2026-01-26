# ARCHITECTURE.md: Grim Fable Technical Architecture

## 1. Project Structure
We will use a **Feature-based structure** to ensure scalability and separation of concerns.

```
lib/
├── core/               # App-wide core logic
│   ├── models/         # Global models
│   ├── services/       # Core services (AI, Storage)
│   └── utils/          # Formatting, constants, theme
├── features/           # Feature-specific logic and UI
│   ├── character/      # Character creation and management
│   ├── adventure/      # Gameplay and session management
│   └── home/           # Main landing screen
├── shared/             # Shared UI components
│   └── widgets/        # Reusable widgets (buttons, tiles)
└── main.dart           # Entry point
```

## 2. State Management Solution
**Decision:** **Riverpod**
- **Reasoning:** Riverpod provides a compile-safe way to manage state, handle dependency injection, and react to asynchronous data (like AI responses). It's more modern and flexible than Provider and less boilerplate-heavy than Bloc for an MVP.

## 3. Local Storage Solution
**Decision:** **Hive**
- **Reasoning:** Hive is a lightweight, fast, NoSQL database for Flutter. Since our story segments and character backstories are flexible in length and structure, a document-style store like Hive is more suitable than a relational SQLite database. It also handles custom objects easily via TypeAdapters.

## 4. AI API Integration Approach
**Decision:** **Dio**
- **Reasoning:** Dio offers powerful features like interceptors (useful for logging/API key handling), global configuration, and better error handling than the basic `http` package. We will implement an `AIService` abstraction to allow swapping between OpenAI, Claude, or Gemini easily.

## 5. Navigation Structure
**Decision:** **GoRouter**
- **Reasoning:** Standardized routing that handles deep linking and state-based navigation cleanly.

## 6. Testing Strategy
- **Unit Testing**: Testing models (JSON serialization) and business logic (Character/Adventure repositories).
- **Mocking**: Use `mockito` or `mocktail` to mock the `AIService` during widget and integration tests.
- **Widget Testing**: Ensuring core UI components (input fields, message bubbles) render correctly.

## 7. Theming & Design
- **Platform Focus**: Android-specific Material 3 design.
- **Color Palette**: Darker shades of blue (Primary) and silver (Secondary/Accents) to maintain a Dark Fantasy aesthetic.
- **Typography**: Clear, readable serif fonts for story text to evoke a "fable" feel.
