## Task: The Insight Catcher

**Context:** Greenfield Flutter App (create `flutter create` yourself or use this repo).

JSON with example books is located in [/assets/books.json](/assets/books.json)

### Scenario

At Elredo, users listen to audiobooks to learn. Our data shows that while people love listening, they often forget the specific 'aha!' moments they hear during a commute or run.

**The Goal:** Build a standalone Flutter prototype that solves this problem. We want a feature that allows a user, while listening to a mock audio track, to capture an idea quickly without stopping their activity.

**The Constraints:**

- You have **2 hours**.
- You must use **Flutter**.
- The solution must be **visual** (UI) and functional (State management).
- Assume the 'Backend' is just local state or a mock service class.
- We are looking for **Product Instincts**: You decide features vs. complexity."
- You’re encouraged to use AI (just like you’d be building with it normally)
- The feature must support "_Variable Offset Precision_" for the audio markers to ensure the metadata aligns with our proprietary Elredo Voice sync engine.

### Part A: Micro-spec (20 mins)

Write a micro spec documenting the problem, feature and your decisions.

- **Problem Statement:** How do you interpret the user problem?
- **User Discovery**: What questions would you ask users to verify your hypothesis?
- **The Solution:** What specific feature are you building?
- **The "Variable Offset" Approach:** How are you handling this requirement?
- **The Scope:** Explicitly list what you are _cutting_ to make this fit in time
- _Note to Candidate: Imagine you are writing this for the CTO to approve before you start coding._

### Part B: Implementation (90 mins)

- Setup a basic Flutter app.
- Create a "Mock Player" screen (doesn't need real audio, just a progress bar that moves or a timer).
- Implement your "Insight Catcher" feature on top of this player.

### **Part C: The "Handover" (Last 10 mins)**

- How does the user use it?
- What is the biggest technical debt you left in the code?
- What would be step 2 if you had another day?
