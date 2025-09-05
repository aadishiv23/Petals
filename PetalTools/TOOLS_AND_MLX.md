## Petals MLX Tooling: Architecture and How It Works

This document explains how Petals integrates tools with local MLX models, how tool calls are detected and executed, and how to add new tools.

### High-level Flow

1) UI/ViewModels enqueue messages and choose a model (Gemini or MLX). For MLX, they delegate to `PetalMLXService`.
2) `PetalMLXService` formats messages and invokes the MLX model via `ConcreteCoreModelContainer.generate(...)`, passing a list of MLX tool definitions from `PetalMLXToolRegistry.mlxTools()`.
3) The model may stream text. If a tool call is detected, the raw output is passed to `AppToolCallHandler.processLLMOutput(...)`.
4) `AppToolCallHandler` normalizes the model output to a standard JSON format and decodes it into `MLXToolCall`. It then dispatches to the matching tool and returns a string result back to the service for display.
5) Telemetry tracks timings, selected tool, and raw outputs for debugging.

### Where Things Live

- PetalMLX service and tool execution
  - `PetalMLX/Sources/PetalMLX/Services/PetalMLXService.swift`
  - `PetalMLX/Sources/PetalMLX/Tools/AppToolCallHandler.swift`
  - `PetalMLX/Sources/PetalMLX/Tools/PetalMLXToolRegistry.swift`

- Tool model/decoding types
  - `PetalCore/Sources/PetalCore/Models/MLXToolCallTypes.swift`

- Tools and factories/registration
  - `PetalTools/Sources/PetalTools/Tools/...`
  - `PetalTools/Sources/PetalTools/Factory/PetalToolFactory.swift`
  - `PetalTools/Sources/PetalTools/Services/PetalToolRegistry.swift`

- Telemetry (optional but recommended for debugging)
  - `PetalCore/Sources/PetalCore/Telemetry/*`

### Tool-call Formats the Model Can Emit

`AppToolCallHandler` supports multiple formats and normalizes them to a common JSON shape:

- Llama-style tags:
  - `<|python_tag|>{ ... }<|eom_id|>`
- Generic tag wrapper:
  - `<tool_call>{ ... }</tool_call>`
- Raw JSON at beginning of output:
  - `{ "name": "toolName", "arguments": { ... } }`

All formats get normalized to:

```json
{
  "name": "toolName",
  "arguments": { /* tool-specific arguments */ }
}
```

Then they are decoded into:

```swift
// PetalCore/Models/MLXToolCallTypes.swift
public struct MLXToolCall: Codable {
    public let name: MLXToolCallType
    public let parameters: MLXToolCallArguments
}
```

### Tool Type and Arguments

`MLXToolCallType` lists every tool name Petals understands. `MLXToolCallArguments` enumerates all typed argument payloads Petals can parse. You must add to both when adding a new tool.

Key types:

- `MLXToolCallType`: enum of known tool names (e.g., `petalCalendarFetchEventsTool`, `petalContactsTool`).
- `MLXToolCallArguments`: enum with one associated case per tool’s argument structure. Its decoder is tolerant of common LLM formatting quirks.

Example (contacts tool):

```swift
public enum MLXToolCallType: String, Codable {
    // ...
    case petalContactsTool
}

public enum MLXToolCallArguments: Codable {
    // ...
    case contacts(ContactsArguments)
}

public struct ContactsArguments: Codable {
    public let action: String // "searchContacts" | "listContacts"
    public let query: String?
    public let limit: Int?
    public let includePhones: Bool?
    public let includeEmails: Bool?
}
```

### Making Tools Available to the Model

`PetalMLXToolRegistry.mlxTools()` returns an array of `MLXCompatibleTool` instances. Each tool provides an `asMLXToolDefinition()` that aligns with OpenAI/Function-Calling style schema and is passed to `generate(...)`.

```swift
let tools = await PetalMLXToolRegistry.mlxTools()
let toolDefinitions = tools.map { $0.asMLXToolDefinition().toDictionary() }
// pass toolDefinitions into container.generate(...)
```

The registry includes platform-specific tools (e.g., Notes/Reminders on macOS, Contacts on iOS) in addition to cross-platform tools.

### Detecting and Executing Tool Calls

`AppToolCallHandler.processLLMOutput(result)` is the single entry point that:

1) Attempts Llama-style parsing, generic `<tool_call>...</tool_call>`, and raw JSON detection.
2) Normalizes JSON to `{ name, arguments }`.
3) Decodes to `MLXToolCall` using `MLXToolCallType` and `MLXToolCallArguments`.
4) Dispatches to a strongly-typed branch in `processToolCallArgument(with:argument:)`, where it converts from the generic arguments to the concrete tool `Input` type and executes it.

Dispatch example (abridged):

```swift
switch (mlxMatchingTool, argument) {
case let (tool as PetalCalendarFetchEventsTool, .calendarFetchEvents(args)):
    let input = try JSONDecoder().decode(PetalCalendarFetchEventsTool.Input.self, from: jsonData)
    let output = try await tool.execute(input)
    return output.events // human-readable string for chat

case let (tool as PetalContactsTool, .contacts(args)):
    let input = try JSONDecoder().decode(PetalContactsTool.Input.self, from: jsonData)
    let output = try await tool.execute(input)
    // map to human-readable lines
    return output.contacts.map { ... }.joined(separator: "\n")

// ... other tools
}
```

### PetalTools: Implementing a Tool

Tools usually live under `PetalTools/Sources/PetalTools/Tools/...`. A tool generally conforms to a Petals tool protocol (e.g., `PetalTool`) and MLX compatibility (`MLXCompatibleTool`) so it can:

- Expose metadata (`id`, `name`, `description`, `triggerKeywords`, `domain`, `requiredPermission`).
- Provide an `asMLXToolDefinition()` with a function name (must match `MLXToolCallType` case) and JSON schema for parameters.
- Define `Input`/`Output` Codable structs and an `execute(_:)` method that performs the action and returns data formatted as a user-facing string (or a structured payload that the handler can format).

Example: `PetalContactsTool` (iOS)

- `id`: `petalContactsTool` (also used as MLX function name)
- Parameters: `action`, `query`, `limit`, `includePhones`, `includeEmails`
- `execute(_:)`: queries CNContacts and returns results

### Adding a New MLX Tool (Checklist)

1) Implement the tool in `PetalTools`:
   - Create `Input` and `Output` structs (Codable).
   - Implement `execute(_:)`.
   - Conform to `MLXCompatibleTool` and provide `asMLXToolDefinition()` with the exact function `name` you’ll use.

2) Register the tool:
   - In `PetalToolFactory`, add a constructor method and register it in `PetalToolRegistry`.
   - Ensure `PetalMLXToolRegistry.mlxTools()` returns an instance on the intended platforms.

3) Wire up decoding:
   - Add a case to `MLXToolCallType` with the exact tool `name`.
   - Add a corresponding case in `MLXToolCallArguments` and extend its decoder to detect your argument shape.

4) Handle dispatch:
   - In `AppToolCallHandler.processToolCallArgument(...)`, add a `switch` case matching your tool and argument enum case.
   - Convert `args` → your tool’s `Input` and call `tool.execute(_:)`.
   - Return a human-readable string for the chat.

5) Optional UX & Heuristics:
   - Update `PetalMLXService.detectPotentialToolName(from:)` to predict your tool for better preloading UX.
   - Update any client views to display custom UI while tools are running if desired.

6) Telemetry (optional, recommended):
   - Telemetry automatically records tool timings if `TelemetryContext` has an active chat/message.
   - You can also set initial model output, chosen tool, and processed tool output from `PetalMLXService`.

### Example: Model Output That Triggers a Tool

The model might emit (Llama-style):

```
<|python_tag|>{
  "function": "petalContactsTool",
  "parameters": {
    "action": "searchContacts",
    "query": "Alice"
  }
}<|eom_id|>
```

The handler normalizes it to:

```json
{
  "name": "petalContactsTool",
  "arguments": { "action": "searchContacts", "query": "Alice" }
}
```

Then it decodes into `MLXToolCall`, dispatches to `PetalContactsTool`, runs the query, and returns a formatted string into the chat transcript.

### Debugging Tips

- If you see `Invalid or unknown tool name`, ensure your tool’s MLX function name equals the `MLXToolCallType` case.
- If arguments fail to decode, extend `MLXToolCallArguments` decoding logic to tolerate alternative key spellings or optional data.
- Use the Telemetry viewer to see model initial output, chosen tool, processed tool output, and timings.

### Security & Permissions

- Tools can require permissions; e.g., Contacts requires iOS contact access. Handle permission requests gracefully and return helpful messages when denied.

---

This architecture keeps the model-facing schema (tool definitions) separate from app-facing logic (tool execution), while providing robust parsing and telemetry for easier debugging.


### Recommended Improvements (with small stubs)

- Stronger single source of truth
  - Define tool metadata once and derive MLX/Ollama schema and Swift IO types.
  - Pseudocode:
    ```swift
    struct ToolSpec {
        let id: String
        let description: String
        let parameters: [ParameterSpec]
        let requiredPermission: Permission
        // Codegen helpers
        func toMLX() -> MLXToolDefinition { ... }
        func toOllama() -> OllamaTool { ... }
    }
    ```

- Arguments normalization layer
  - Centralize tolerant fixes (e.g., `listContacts` + `query` → `searchContacts`).
  - Stub:
    ```swift
    protocol ToolArgumentNormalizer {
        associatedtype Args
        func normalize(_ args: Args) -> Args
    }

    struct ContactsNormalizer: ToolArgumentNormalizer {
        func normalize(_ args: ContactsArguments) -> ContactsArguments { /* coerce action/query */ }
    }
    ```

- Typed results, not strings
  - Tools return `Output`; formatting happens in a renderer.
  - Stub:
    ```swift
    protocol ToolRenderer {
        associatedtype Output
        func renderText(_ output: Output) -> String
        // Optionally: renderView(_ output: Output) -> some View
    }
    ```

- Tool lifecycle hooks
  - Pre/post hooks for permissions, timeouts, retries.
  - Stub:
    ```swift
    protocol ToolLifecycle {
        func willExecute(context: ToolContext)
        func didExecute(context: ToolContext, result: Result<Void, Error>)
    }
    ```

- Capability discovery and dynamic availability
  - Only advertise tools the platform/permissions support.
  - Stub:
    ```swift
    struct Capability { let platform: Platform; let permissions: Set<Permission> }
    protocol ToolCapabilityProvider { func isAvailable(for capability: Capability) -> Bool }
    ```

- Better error taxonomy
  - Differentiate decode/validation/permission/execution errors.
  - Stub:
    ```swift
    enum ToolExecutionError: Error { case decode, validation(String), permission, runtime(Error) }
    ```

- Telemetry enrichments
  - Correlate tool phases and decisions.
  - Stub additions: `validationWarnings: [String]`, `phaseTimings: [String: Double]`.

- Testing and fixtures
  - Snapshot tests for all supported tool-call formats and normalizations.
  - Example cases:
    - `<|python_tag|>{"function":"..."}<|eom_id|>`
    - `<tool_call>{...}</tool_call>`
    - `{ "name": "...", "arguments": { ... } }`

- Prompting guardrails
  - Add exemplar prompts clarifying canonical parameter names and actions.

- Rendering improvements
  - Create view renderers per tool (e.g., ContactsListView) with a textual fallback.

- Registry ergonomics
  - Query by platform and permission, return schema+executor together.
  - Stub:
    ```swift
    struct RegisteredTool {
        let schema: MLXToolDefinition
        let executor: any PetalTool
        let isAvailable: (Capability) -> Bool
    }
    ```

- Safety/Privacy
  - Redact PII in telemetry unless verbose is enabled; add a global kill switch.

- Developer UX
  - Script to scaffold a tool from a template (creates Tool, IO, schema, registry entry, tests).

