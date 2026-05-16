---
name: Pydantic AI Agent Builder
description: Expert guidance for building AI agents with Pydantic AI framework. Use when creating multi-agent systems, AI orchestration workflows, or structured LLM applications with type safety and validation.
version: 1.0.0
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Pydantic AI Agent Builder

Comprehensive system for building production-grade AI agents using Pydantic AI with type safety, structured outputs, and enterprise patterns.

## Core Concepts

Pydantic AI is a Python agent framework designed to make it less painful to build production-grade applications with Generative AI.

### Key Features

- **Type-safe**: Built on Pydantic for runtime validation
- **Model-agnostic**: Works with OpenAI, Anthropic, Gemini, Ollama
- **Structured outputs**: Guaranteed valid responses
- **Dependency injection**: Clean testing and modularity
- **Streaming support**: Real-time responses
- **Tool/function calling**: External integrations

## Basic Agent Patterns

### 1. Simple Agent

```python
from pydantic_ai import Agent
from pydantic import BaseModel

# Define response model
class MovieRecommendation(BaseModel):
    title: str
    year: int
    genre: str
    reason: str

# Create agent
agent = Agent(
    'openai:gpt-4o',
    result_type=MovieRecommendation,
    system_prompt='You are a movie recommendation expert.',
)

# Run agent
async def get_recommendation(preferences: str):
    result = await agent.run(preferences)
    return result.data

# Usage
recommendation = await get_recommendation("sci-fi with time travel")
print(f"{recommendation.title} ({recommendation.year})")
```

### 2. Agent with Tools

```python
from pydantic_ai import Agent, RunContext
from dataclasses import dataclass

@dataclass
class SearchDeps:
    """Dependencies for search tools."""
    api_key: str
    database_url: str

agent = Agent(
    'anthropic:claude-3-5-sonnet-20241022',
    deps_type=SearchDeps,
    system_prompt='You are a research assistant with web search capabilities.',
)

@agent.tool
async def search_web(ctx: RunContext[SearchDeps], query: str) -> str:
    """Search the web for information."""
    # Use ctx.deps.api_key for API access
    results = await perform_search(query, ctx.deps.api_key)
    return f"Found {len(results)} results for '{query}'"

@agent.tool
async def search_database(ctx: RunContext[SearchDeps], query: str) -> list[dict]:
    """Search internal database."""
    # Use ctx.deps.database_url for DB access
    return await db_query(ctx.deps.database_url, query)

# Run with dependencies
deps = SearchDeps(
    api_key=os.getenv("SEARCH_API_KEY"),
    database_url=os.getenv("DATABASE_URL"),
)

result = await agent.run("Find information about quantum computing", deps=deps)
```

### 3. Multi-Step Agent with State

```python
from pydantic_ai import Agent
from pydantic import BaseModel, Field

class ResearchState(BaseModel):
    """Track research progress."""
    query: str
    sources_found: list[str] = Field(default_factory=list)
    summary: str = ""
    confidence: float = 0.0

class ResearchResult(BaseModel):
    """Final research output."""
    answer: str
    sources: list[str]
    confidence_score: float

agent = Agent(
    'openai:gpt-4o',
    result_type=ResearchResult,
    system_prompt='''You are a thorough researcher.
    First search for sources, then analyze them, then provide a summary.''',
)

@agent.tool
async def search_sources(ctx: RunContext[ResearchState], topic: str) -> list[str]:
    """Find relevant sources."""
    sources = await find_sources(topic)
    ctx.deps.sources_found.extend(sources)
    return sources

@agent.tool
async def analyze_source(ctx: RunContext[ResearchState], source_url: str) -> str:
    """Analyze a specific source."""
    content = await fetch_content(source_url)
    analysis = await analyze_content(content)
    return analysis

# Run research agent
state = ResearchState(query="What is quantum entanglement?")
result = await agent.run(state.query, deps=state)
```

### 4. Agent with Structured Output

```python
from pydantic_ai import Agent
from pydantic import BaseModel, Field
from typing import Literal

class CodeReview(BaseModel):
    """Structured code review output."""
    overall_quality: Literal["excellent", "good", "needs_improvement", "poor"]
    issues: list[str] = Field(description="List of identified issues")
    suggestions: list[str] = Field(description="Improvement suggestions")
    security_concerns: list[str] = Field(default_factory=list)
    performance_notes: list[str] = Field(default_factory=list)
    score: int = Field(ge=0, le=100, description="Overall score")

agent = Agent(
    'anthropic:claude-3-5-sonnet-20241022',
    result_type=CodeReview,
    system_prompt='''You are an expert code reviewer.
    Analyze code for quality, security, performance, and best practices.
    Provide actionable feedback.''',
)

async def review_code(code: str, language: str) -> CodeReview:
    prompt = f"Review this {language} code:\n\n```{language}\n{code}\n```"
    result = await agent.run(prompt)
    return result.data

# Usage
review = await review_code(open("app.py").read(), "python")
print(f"Quality: {review.overall_quality}, Score: {review.score}/100")
for issue in review.issues:
    print(f"- {issue}")
```

## Advanced Patterns

### 5. Multi-Agent System

```python
from pydantic_ai import Agent
from pydantic import BaseModel

class Task(BaseModel):
    description: str
    assigned_to: str
    status: str = "pending"

class ProjectPlan(BaseModel):
    tasks: list[Task]
    timeline: str
    risks: list[str]

# Specialized agents
architect_agent = Agent(
    'openai:gpt-4o',
    result_type=ProjectPlan,
    system_prompt='You are a technical architect. Design robust systems.',
)

developer_agent = Agent(
    'anthropic:claude-3-5-sonnet-20241022',
    result_type=str,
    system_prompt='You are a senior developer. Write clean, tested code.',
)

qa_agent = Agent(
    'openai:gpt-4o',
    result_type=list[str],
    system_prompt='You are a QA engineer. Find bugs and edge cases.',
)

# Orchestrator
class ProjectOrchestrator:
    def __init__(self):
        self.architect = architect_agent
        self.developer = developer_agent
        self.qa = qa_agent

    async def execute_project(self, requirements: str):
        # Step 1: Design
        plan_result = await self.architect.run(
            f"Create a project plan for: {requirements}"
        )
        plan = plan_result.data

        # Step 2: Implement each task
        implementations = []
        for task in plan.tasks:
            code_result = await self.developer.run(
                f"Implement: {task.description}"
            )
            implementations.append(code_result.data)

        # Step 3: QA Review
        combined_code = "\n\n".join(implementations)
        qa_result = await self.qa.run(
            f"Review this implementation:\n{combined_code}"
        )

        return {
            "plan": plan,
            "code": implementations,
            "qa_feedback": qa_result.data,
        }

# Usage
orchestrator = ProjectOrchestrator()
result = await orchestrator.execute_project(
    "Build a REST API for user management with authentication"
)
```

### 6. Agent with Streaming

```python
from pydantic_ai import Agent
import asyncio

agent = Agent('openai:gpt-4o')

async def stream_response(prompt: str):
    """Stream agent response in real-time."""
    async with agent.run_stream(prompt) as response:
        async for chunk in response.stream_text():
            print(chunk, end='', flush=True)

        # Get final result
        final = await response.get_data()
        return final

# Usage
await stream_response("Explain quantum computing in simple terms")
```

### 7. Agent with Retry Logic

```python
from pydantic_ai import Agent, ModelRetry
from pydantic import BaseModel, Field, field_validator

class ParsedData(BaseModel):
    name: str = Field(min_length=1)
    age: int = Field(ge=0, le=150)
    email: str

    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        if '@' not in v:
            raise ValueError('Invalid email format')
        return v

agent = Agent(
    'openai:gpt-4o',
    result_type=ParsedData,
    retries=3,  # Retry up to 3 times on validation errors
)

@agent.result_validator
async def validate_result(ctx: RunContext, result: ParsedData) -> ParsedData:
    """Custom validation with retry."""
    if result.age < 18:
        raise ModelRetry('Age must be 18 or older. Please try again.')
    return result

# If validation fails, agent automatically retries with feedback
result = await agent.run("Extract person info: John Doe, 25, john@example.com")
```

### 8. Agent with RAG (Retrieval Augmented Generation)

```python
from pydantic_ai import Agent, RunContext
from dataclasses import dataclass
import chromadb

@dataclass
class RAGDeps:
    vector_db: chromadb.Client
    collection_name: str

agent = Agent(
    'anthropic:claude-3-5-sonnet-20241022',
    deps_type=RAGDeps,
    system_prompt='''You are a helpful assistant with access to a knowledge base.
    Always search the knowledge base before answering questions.''',
)

@agent.tool
async def search_knowledge_base(
    ctx: RunContext[RAGDeps],
    query: str,
    limit: int = 5
) -> list[str]:
    """Search vector database for relevant documents."""
    collection = ctx.deps.vector_db.get_collection(ctx.deps.collection_name)
    results = collection.query(
        query_texts=[query],
        n_results=limit,
    )
    return results['documents'][0]

# Initialize vector DB
chroma_client = chromadb.Client()
collection = chroma_client.create_collection("knowledge_base")

# Add documents
collection.add(
    documents=["Document 1 content...", "Document 2 content..."],
    ids=["doc1", "doc2"],
)

# Run RAG agent
deps = RAGDeps(vector_db=chroma_client, collection_name="knowledge_base")
result = await agent.run("What does the documentation say about X?", deps=deps)
```

### 9. Agent with Custom Model

```python
from pydantic_ai import Agent
from pydantic_ai.models import Model, infer_model
from openai import AsyncOpenAI

# Use custom model configuration
custom_model = infer_model('openai:gpt-4o', openai_client=AsyncOpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    timeout=60.0,
    max_retries=3,
))

agent = Agent(
    custom_model,
    system_prompt='You are a helpful assistant.',
)

# Or use model-specific parameters
result = await agent.run(
    "Generate a story",
    model_settings={
        'temperature': 0.9,
        'max_tokens': 2000,
        'top_p': 0.95,
    }
)
```

### 10. Agent Testing

```python
import pytest
from pydantic_ai import Agent
from pydantic_ai.models.test import TestModel

@pytest.mark.asyncio
async def test_agent():
    """Test agent with mock model."""
    # Create test model with predefined responses
    test_model = TestModel()

    agent = Agent(test_model, result_type=str)

    # Set expected response
    test_model.agent_model_function_return = "Test response"

    result = await agent.run("Test prompt")
    assert result.data == "Test response"

    # Verify calls
    assert len(test_model.agent_model_function_calls) == 1

@pytest.mark.asyncio
async def test_agent_with_tools():
    """Test agent with mocked dependencies."""

    @dataclass
    class MockDeps:
        api_called: bool = False

    agent = Agent('test', deps_type=MockDeps)

    @agent.tool
    async def mock_api_call(ctx: RunContext[MockDeps]) -> str:
        ctx.deps.api_called = True
        return "API response"

    deps = MockDeps()
    result = await agent.run("Call the API", deps=deps)

    assert deps.api_called is True
```

## Production Patterns

### 11. Error Handling & Logging

```python
from pydantic_ai import Agent, UnexpectedModelBehavior
from pydantic import BaseModel
import logging
import structlog

# Configure structured logging
logger = structlog.get_logger()

class SafeAgent:
    def __init__(self, model: str):
        self.agent = Agent(model)

    async def run_safe(self, prompt: str) -> dict:
        """Run agent with comprehensive error handling."""
        try:
            logger.info("agent.run.start", prompt=prompt)

            result = await self.agent.run(prompt)

            logger.info(
                "agent.run.success",
                prompt=prompt,
                usage=result.usage(),
            )

            return {
                "success": True,
                "data": result.data,
                "cost": result.cost(),
            }

        except UnexpectedModelBehavior as e:
            logger.error(
                "agent.run.model_error",
                prompt=prompt,
                error=str(e),
            )
            return {"success": False, "error": "Model behavior error"}

        except Exception as e:
            logger.exception(
                "agent.run.unexpected_error",
                prompt=prompt,
            )
            return {"success": False, "error": str(e)}

# Usage
safe_agent = SafeAgent('openai:gpt-4o')
result = await safe_agent.run_safe("Complex prompt...")
```

### 12. Rate Limiting & Cost Control

```python
from pydantic_ai import Agent
import asyncio
from datetime import datetime, timedelta

class RateLimitedAgent:
    def __init__(self, model: str, max_requests_per_minute: int = 60):
        self.agent = Agent(model)
        self.max_rpm = max_requests_per_minute
        self.requests = []
        self.total_cost = 0.0
        self.max_cost = 10.0  # $10 limit

    async def run_with_limits(self, prompt: str):
        """Run agent with rate limiting and cost control."""
        # Check rate limit
        now = datetime.now()
        self.requests = [r for r in self.requests if r > now - timedelta(minutes=1)]

        if len(self.requests) >= self.max_rpm:
            wait_time = (self.requests[0] - (now - timedelta(minutes=1))).total_seconds()
            await asyncio.sleep(wait_time)

        # Check cost limit
        if self.total_cost >= self.max_cost:
            raise Exception(f"Cost limit reached: ${self.total_cost:.2f}")

        # Run agent
        result = await self.agent.run(prompt)

        # Track request and cost
        self.requests.append(datetime.now())
        cost = result.cost()
        self.total_cost += cost

        return result.data

# Usage
agent = RateLimitedAgent('openai:gpt-4o', max_requests_per_minute=50)
result = await agent.run_with_limits("Analyze this data...")
```

### 13. Agent Caching

```python
from pydantic_ai import Agent
from functools import lru_cache
import hashlib
import json

class CachedAgent:
    def __init__(self, model: str, cache_size: int = 128):
        self.agent = Agent(model)
        self.cache_size = cache_size

    @lru_cache(maxsize=128)
    async def _run_cached(self, prompt_hash: str, prompt: str):
        """Internal cached run."""
        result = await self.agent.run(prompt)
        return result.data

    async def run(self, prompt: str, use_cache: bool = True):
        """Run with optional caching."""
        if use_cache:
            prompt_hash = hashlib.md5(prompt.encode()).hexdigest()
            return await self._run_cached(prompt_hash, prompt)
        else:
            result = await self.agent.run(prompt)
            return result.data

# Usage
cached_agent = CachedAgent('openai:gpt-4o')
result1 = await cached_agent.run("What is Python?")  # API call
result2 = await cached_agent.run("What is Python?")  # From cache
```

### 14. Prompt Management

```python
from pydantic_ai import Agent
from jinja2 import Template

class PromptLibrary:
    """Centralized prompt management."""

    PROMPTS = {
        "code_review": Template('''
            Review this {{ language }} code for:
            - Code quality and best practices
            - Security vulnerabilities
            - Performance issues
            - Maintainability

            Code:
            ```{{ language }}
            {{ code }}
            ```
        '''),

        "data_analysis": Template('''
            Analyze this dataset and provide:
            - Summary statistics
            - Key insights
            - Anomalies or patterns
            - Recommendations

            Data: {{ data }}
        '''),
    }

    @classmethod
    def render(cls, template_name: str, **kwargs) -> str:
        """Render prompt template with variables."""
        template = cls.PROMPTS.get(template_name)
        if not template:
            raise ValueError(f"Template '{template_name}' not found")
        return template.render(**kwargs)

# Usage
agent = Agent('anthropic:claude-3-5-sonnet-20241022')

prompt = PromptLibrary.render(
    "code_review",
    language="python",
    code=open("app.py").read(),
)

result = await agent.run(prompt)
```

### 15. Agent Composition

```python
from pydantic_ai import Agent
from pydantic import BaseModel

class ComposableAgent:
    """Compose multiple specialized agents."""

    def __init__(self):
        self.summarizer = Agent(
            'openai:gpt-4o',
            system_prompt='Summarize text concisely.',
        )

        self.analyzer = Agent(
            'anthropic:claude-3-5-sonnet-20241022',
            system_prompt='Analyze sentiment and key themes.',
        )

        self.translator = Agent(
            'openai:gpt-4o',
            system_prompt='Translate text accurately.',
        )

    async def process_document(self, text: str, target_language: str = None):
        """Process document through multiple agents."""
        # Step 1: Summarize
        summary_result = await self.summarizer.run(
            f"Summarize this text:\n{text}"
        )
        summary = summary_result.data

        # Step 2: Analyze
        analysis_result = await self.analyzer.run(
            f"Analyze this summary:\n{summary}"
        )
        analysis = analysis_result.data

        # Step 3: Translate if requested
        if target_language:
            translation_result = await self.translator.run(
                f"Translate to {target_language}:\n{summary}"
            )
            summary = translation_result.data

        return {
            "summary": summary,
            "analysis": analysis,
        }

# Usage
composer = ComposableAgent()
result = await composer.process_document(
    text=long_document,
    target_language="Spanish",
)
```

## Best Practices

### Type Safety
✅ Always define `result_type` for structured outputs
✅ Use Pydantic models for complex types
✅ Validate inputs with field validators
✅ Use `deps_type` for dependency injection

### Performance
✅ Implement caching for repeated queries
✅ Use streaming for long responses
✅ Set appropriate timeouts
✅ Monitor token usage and costs

### Error Handling
✅ Use `retries` parameter for transient failures
✅ Implement custom validators with `ModelRetry`
✅ Log all agent interactions
✅ Handle `UnexpectedModelBehavior` exceptions

### Testing
✅ Use `TestModel` for unit tests
✅ Mock dependencies with dataclasses
✅ Test validation logic separately
✅ Verify tool calls and responses

### Production
✅ Implement rate limiting
✅ Set cost limits and monitoring
✅ Use structured logging
✅ Version your prompts
✅ Monitor model performance

## Quick Reference

```python
# Basic agent
agent = Agent('openai:gpt-4o', result_type=MyModel)
result = await agent.run("prompt")

# Agent with tools
@agent.tool
async def my_tool(ctx: RunContext[Deps], arg: str) -> str:
    return "result"

# Agent with validation
@agent.result_validator
async def validate(ctx: RunContext, result: Model) -> Model:
    if not valid(result):
        raise ModelRetry("Try again")
    return result

# Streaming
async with agent.run_stream("prompt") as response:
    async for chunk in response.stream_text():
        print(chunk, end='')

# Custom settings
result = await agent.run(
    "prompt",
    model_settings={'temperature': 0.7},
)
```

---

## Modern API (Pydantic AI 2.x)

Older sections above use the legacy `result_type` parameter. Current API:

```python
# output_type replaces result_type
agent = Agent('anthropic:claude-sonnet-4-6', output_type=MyModel)
result = agent.run_sync('prompt')
print(result.output)  # NOT result.data
```

### Model strings (current)

```python
'openai:gpt-5.2'
'openai:gpt-4o' / 'openai:gpt-4o-mini'
'anthropic:claude-sonnet-4-6' / 'anthropic:claude-opus-4-6' / 'anthropic:claude-haiku-4-5'
'google-gla:gemini-3-flash-preview' / 'google-vertex:gemini-2.0-flash'
'groq:...', 'mistral:...', 'cohere:...', 'bedrock:...'
```

### Capabilities (reusable behaviors)

```python
from pydantic_ai.capabilities import Thinking, WebSearch

agent = Agent(
    'anthropic:claude-opus-4-6',
    instructions='Research assistant. Cite sources.',
    capabilities=[Thinking(effort='high'), WebSearch()],
)
```

### Lifecycle hooks

```python
from pydantic_ai.capabilities.hooks import Hooks

hooks = Hooks()

@hooks.on.before_model_request
async def log_request(ctx, request_context):
    print(f'Sending {len(request_context.messages)} messages')
    return request_context

agent = Agent('openai:gpt-5.2', capabilities=[hooks])
```

### Load agent from YAML

```python
# agent.yaml:
#   model: anthropic:claude-opus-4-6
#   instructions: You are a helpful research assistant.
#   capabilities:
#     - WebSearch
#     - Thinking: { effort: high }

agent = Agent.from_file('agent.yaml')
```

## Common Gotchas

- **`@agent.tool` requires `RunContext` as first param**; `@agent.tool_plain` must **not** have it.
- **Model strings need the provider prefix**: `'openai:gpt-5.2'` not `'gpt-5.2'`.
- **`TestModel` requires `agent.override()`**: `with agent.override(model=TestModel()):` — never set `agent.model` directly.
- **`str` in output_type allows plain text to end the run**: If your union includes `str`, the model can skip structured output. Omit `str` to force tool-based output.
- **Hook decorator names on `.on` don't repeat `on_`**: `hooks.on.run_error`, not `hooks.on.on_run_error`.
- **`history_processors` is plural**: `history_processors=[...]`.

## Decision Framework

| Scenario | Configuration |
|---|---|
| Simple text responses | `Agent(model)` |
| Structured data extraction | `Agent(model, output_type=MyModel)` |
| Need external services | Add `deps_type=MyDeps` |
| Validation retries needed | Increase `retries=3` |
| Debugging/monitoring | Set `instrument=True` or call `logfire.instrument_pydantic_ai()` |
| Multi-agent or graph workflow | See `references/ORCHESTRATION-AND-INTEGRATIONS.md` |
| Testing | See `references/TESTING-AND-DEBUGGING.md` |

## Reference files

For depth on specific topics, load only the relevant one:

| Topic | File |
|---|---|
| Agent setup, output, deps, run methods | `references/AGENTS-CORE.md` |
| Capabilities & hooks | `references/CAPABILITIES-AND-HOOKS.md` |
| Tools, toolsets, MCP | `references/TOOLS-CORE.md` |
| Provider-native tools (web search, fetch) | `references/BUILTIN-TOOLS.md` |
| Approvals, retries, validators, timeouts | `references/TOOLS-ADVANCED.md` |
| Multimodal input, message history | `references/INPUT-AND-HISTORY.md` |
| Testing & Logfire debugging | `references/TESTING-AND-DEBUGGING.md` |
| Multi-agent, graphs, A2A, evals, integrations | `references/ORCHESTRATION-AND-INTEGRATIONS.md` |
| Comparison tables & decision trees | `references/ARCHITECTURE.md` |

---

**When to Use This Skill:**

Invoke when building AI agents, multi-agent systems, structured LLM applications, or when implementing type-safe AI workflows with Pydantic AI.

<!-- cross-ref:start -->

## See also (related skills — Pydantic AI family)

If your issue relates to:
- **common mistakes and debugging Pydantic AI agents** — check `pydantic-ai-common-pitfalls` if appropriate.
- **RunContext, deps_type, dependency injection patterns** — check `pydantic-ai-dependency-injection` if appropriate.
- **configuring providers, fallback models, streaming, settings** — check `pydantic-ai-model-integration` if appropriate.
- **TestModel, FunctionModel, VCR cassettes, inline snapshots** — check `pydantic-ai-testing` if appropriate.
- **registering tools, function calling, ctx handling** — check `pydantic-ai-tool-system` if appropriate.
- **framework reference — structured outputs, providers, streaming** — check `pydanticai-docs` if appropriate.

<!-- cross-ref:end -->


---

# dependency injection (merged from former `pydantic-ai-dependency-injection` skill)


# PydanticAI Dependency Injection

## Core Pattern

Dependencies flow through `RunContext`:

```python
from dataclasses import dataclass
from pydantic_ai import Agent, RunContext

@dataclass
class Deps:
    db: DatabaseConn
    api_client: HttpClient
    user_id: int

agent = Agent(
    'openai:gpt-4o',
    deps_type=Deps,  # Type for static analysis
)

@agent.tool
async def get_user_balance(ctx: RunContext[Deps]) -> float:
    """Get the current user's account balance."""
    return await ctx.deps.db.get_balance(ctx.deps.user_id)

# At runtime, provide deps
result = await agent.run(
    'What is my balance?',
    deps=Deps(db=db_conn, api_client=client, user_id=123)
)
```

## Defining Dependencies

Use dataclasses or Pydantic models:

```python
from dataclasses import dataclass
from pydantic import BaseModel

# Dataclass (recommended for simplicity)
@dataclass
class Deps:
    db: DatabaseConnection
    cache: CacheClient
    user_context: UserContext

# Pydantic model (if you need validation)
class Deps(BaseModel):
    api_key: str
    endpoint: str
    timeout: int = 30
```

## Accessing Dependencies

In tools and instructions:

```python
@agent.tool
async def query_database(ctx: RunContext[Deps], query: str) -> list[dict]:
    """Run a database query."""
    return await ctx.deps.db.execute(query)

@agent.instructions
async def add_user_context(ctx: RunContext[Deps]) -> str:
    user = await ctx.deps.db.get_user(ctx.deps.user_id)
    return f"User name: {user.name}, Role: {user.role}"

@agent.system_prompt
def add_permissions(ctx: RunContext[Deps]) -> str:
    return f"User has permissions: {ctx.deps.permissions}"
```

## Type Safety

Full type checking with generics:

```python
# Explicit agent type annotation
agent: Agent[Deps, OutputModel] = Agent(
    'openai:gpt-4o',
    deps_type=Deps,
    output_type=OutputModel,
)

# Now these are type-checked:
# - ctx.deps in tools is typed as Deps
# - result.output is typed as OutputModel
# - agent.run() requires deps: Deps
```

## No Dependencies Pattern

When you don't need dependencies:

```python
# Option 1: No deps_type (defaults to NoneType)
agent = Agent('openai:gpt-4o')
result = agent.run_sync('Hello')  # No deps needed

# Option 2: Explicit None for type checker
agent: Agent[None, str] = Agent('openai:gpt-4o')
result = agent.run_sync('Hello', deps=None)

# In tool_plain, no context access
@agent.tool_plain
def simple_calc(a: int, b: int) -> int:
    return a + b
```

## Complete Example

```python
from dataclasses import dataclass
from httpx import AsyncClient
from pydantic import BaseModel
from pydantic_ai import Agent, RunContext

@dataclass
class WeatherDeps:
    client: AsyncClient
    api_key: str

class WeatherReport(BaseModel):
    location: str
    temperature: float
    conditions: str

agent: Agent[WeatherDeps, WeatherReport] = Agent(
    'openai:gpt-4o',
    deps_type=WeatherDeps,
    output_type=WeatherReport,
    instructions='You are a weather assistant.',
)

@agent.tool
async def get_weather(
    ctx: RunContext[WeatherDeps],
    city: str
) -> dict:
    """Fetch weather data for a city."""
    response = await ctx.deps.client.get(
        f'https://api.weather.com/{city}',
        headers={'Authorization': ctx.deps.api_key}
    )
    return response.json()

async def main():
    async with AsyncClient() as client:
        deps = WeatherDeps(client=client, api_key='secret')
        result = await agent.run('Weather in London?', deps=deps)
        print(result.output.temperature)
```

## Override for Testing

```python
from pydantic_ai.models.test import TestModel

# Create mock dependencies
mock_deps = Deps(
    db=MockDatabase(),
    api_client=MockClient(),
    user_id=999
)

# Override model and deps for testing
with agent.override(model=TestModel(), deps=mock_deps):
    result = agent.run_sync('Test prompt')
```

## Best Practices

1. **Keep deps immutable**: Use frozen dataclasses or Pydantic models
2. **Pass connections, not credentials**: Deps should hold initialized clients
3. **Type your agents**: Use `Agent[DepsType, OutputType]` for full type safety
4. **Scope deps appropriately**: Create deps at the start of a request, close after

<!-- cross-ref:start -->

## See also (related skills — Pydantic AI family)

If your issue relates to:
- **main Pydantic AI guide with reference files (start here)** — check `pydantic-ai-agent-builder` if appropriate.
- **common mistakes and debugging Pydantic AI agents** — check `pydantic-ai-common-pitfalls` if appropriate.
- **configuring providers, fallback models, streaming, settings** — check `pydantic-ai-model-integration` if appropriate.
- **TestModel, FunctionModel, VCR cassettes, inline snapshots** — check `pydantic-ai-testing` if appropriate.
- **registering tools, function calling, ctx handling** — check `pydantic-ai-tool-system` if appropriate.
- **framework reference — structured outputs, providers, streaming** — check `pydanticai-docs` if appropriate.

<!-- cross-ref:end -->


---

# model integration (merged from former `pydantic-ai-model-integration` skill)


# PydanticAI Model Integration

## Provider Model Strings

Format: `provider:model-name`

```python
from pydantic_ai import Agent

# OpenAI
Agent('openai:gpt-4o')
Agent('openai:gpt-4o-mini')
Agent('openai:o1-preview')

# Anthropic
Agent('anthropic:claude-sonnet-4-5')
Agent('anthropic:claude-haiku-4-5')

# Google (API Key)
Agent('google-gla:gemini-2.0-flash')
Agent('google-gla:gemini-2.0-pro')

# Google (Vertex AI)
Agent('google-vertex:gemini-2.0-flash')

# Groq
Agent('groq:llama-3.3-70b-versatile')
Agent('groq:mixtral-8x7b-32768')

# Mistral
Agent('mistral:mistral-large-latest')

# Other providers
Agent('cohere:command-r-plus')
Agent('bedrock:anthropic.claude-3-sonnet')
```

## Model Settings

```python
from pydantic_ai import Agent
from pydantic_ai.settings import ModelSettings

agent = Agent(
    'openai:gpt-4o',
    model_settings=ModelSettings(
        temperature=0.7,
        max_tokens=1000,
        top_p=0.9,
        timeout=30.0,  # Request timeout
    )
)

# Override per-run
result = await agent.run(
    'Generate creative text',
    model_settings=ModelSettings(temperature=1.0)
)
```

## Fallback Models

Chain models for resilience:

```python
from pydantic_ai.models.fallback import FallbackModel

# Try models in order until one succeeds
fallback = FallbackModel(
    'openai:gpt-4o',
    'anthropic:claude-sonnet-4-5',
    'google-gla:gemini-2.0-flash'
)

agent = Agent(fallback)
result = await agent.run('Hello')

# Custom fallback conditions
from pydantic_ai.exceptions import ModelAPIError

def should_fallback(error: Exception) -> bool:
    """Only fallback on rate limits or server errors."""
    if isinstance(error, ModelAPIError):
        return error.status_code in (429, 500, 502, 503)
    return False

fallback = FallbackModel(
    'openai:gpt-4o',
    'anthropic:claude-sonnet-4-5',
    fallback_on=should_fallback
)
```

## Streaming Responses

```python
async def stream_response():
    async with agent.run_stream('Tell me a story') as response:
        # Stream text output
        async for chunk in response.stream_output():
            print(chunk, end='', flush=True)

    # Access final result after streaming
    print(f"\nTokens used: {response.usage().total_tokens}")
```

### Streaming with Structured Output

```python
from pydantic import BaseModel

class Story(BaseModel):
    title: str
    content: str
    moral: str

agent = Agent('openai:gpt-4o', output_type=Story)

async with agent.run_stream('Write a fable') as response:
    # For structured output, stream_output yields partial JSON
    async for partial in response.stream_output():
        print(partial)  # Partial Story object as parsed

    # Final validated result
    story = response.output
```

## Dynamic Model Selection

```python
import os

# Environment-based selection
model = os.getenv('PYDANTIC_AI_MODEL', 'openai:gpt-4o')
agent = Agent(model)

# Runtime model override
result = await agent.run(
    'Hello',
    model='anthropic:claude-sonnet-4-5'  # Override default
)

# Context manager override
with agent.override(model='google-gla:gemini-2.0-flash'):
    result = agent.run_sync('Hello')
```

## Deferred Model Checking

Delay model validation for testing:

```python
# Default: Validates model immediately (checks env vars)
agent = Agent('openai:gpt-4o')

# Deferred: Validates only on first run
agent = Agent('openai:gpt-4o', defer_model_check=True)

# Useful for testing with override
with agent.override(model=TestModel()):
    result = agent.run_sync('Test')  # No OpenAI key needed
```

## Usage Tracking

```python
result = await agent.run('Hello')

# Request usage (last request)
usage = result.usage()
print(f"Input tokens: {usage.input_tokens}")
print(f"Output tokens: {usage.output_tokens}")
print(f"Total tokens: {usage.total_tokens}")

# Full run usage (all requests in run)
run_usage = result.run_usage()
print(f"Total requests: {run_usage.requests}")
```

## Usage Limits

```python
from pydantic_ai.usage import UsageLimits

# Limit token usage
result = await agent.run(
    'Generate content',
    usage_limits=UsageLimits(
        total_tokens=1000,
        request_tokens=500,
        response_tokens=500,
    )
)
```

## Provider-Specific Features

### OpenAI

```python
from pydantic_ai.models.openai import OpenAIModel

model = OpenAIModel(
    'gpt-4o',
    api_key='your-key',  # Or use OPENAI_API_KEY env var
    base_url='https://custom-endpoint.com'  # For Azure, proxies
)
```

### Anthropic

```python
from pydantic_ai.models.anthropic import AnthropicModel

model = AnthropicModel(
    'claude-sonnet-4-5',
    api_key='your-key'  # Or ANTHROPIC_API_KEY
)
```

## Common Model Patterns

| Use Case | Recommendation |
|----------|---------------|
| General purpose | `openai:gpt-4o` or `anthropic:claude-sonnet-4-5` |
| Fast/cheap | `openai:gpt-4o-mini` or `anthropic:claude-haiku-4-5` |
| Long context | `anthropic:claude-sonnet-4-5` (200k) or `google-gla:gemini-2.0-flash` |
| Reasoning | `openai:o1-preview` |
| Cost-sensitive prod | `FallbackModel` with fast model first |

<!-- cross-ref:start -->

## See also (related skills — Pydantic AI family)

If your issue relates to:
- **main Pydantic AI guide with reference files (start here)** — check `pydantic-ai-agent-builder` if appropriate.
- **common mistakes and debugging Pydantic AI agents** — check `pydantic-ai-common-pitfalls` if appropriate.
- **RunContext, deps_type, dependency injection patterns** — check `pydantic-ai-dependency-injection` if appropriate.
- **TestModel, FunctionModel, VCR cassettes, inline snapshots** — check `pydantic-ai-testing` if appropriate.
- **registering tools, function calling, ctx handling** — check `pydantic-ai-tool-system` if appropriate.
- **framework reference — structured outputs, providers, streaming** — check `pydanticai-docs` if appropriate.

<!-- cross-ref:end -->


---

# tool system (merged from former `pydantic-ai-tool-system` skill)


# PydanticAI Tool System

## Tool Registration

Two decorators based on whether you need context:

```python
from pydantic_ai import Agent, RunContext

agent = Agent('openai:gpt-4o')

# @agent.tool - First param MUST be RunContext
@agent.tool
async def get_user_data(ctx: RunContext[MyDeps], user_id: int) -> str:
    """Get user data from database.

    Args:
        ctx: The run context with dependencies.
        user_id: The user's ID.
    """
    return await ctx.deps.db.get_user(user_id)

# @agent.tool_plain - NO context parameter allowed
@agent.tool_plain
def calculate_total(prices: list[float]) -> float:
    """Calculate total price.

    Args:
        prices: List of prices to sum.
    """
    return sum(prices)
```

## Critical Rules

1. **@agent.tool**: First parameter MUST be `RunContext[DepsType]`
2. **@agent.tool_plain**: MUST NOT have `RunContext` parameter
3. **Docstrings**: Required for LLM to understand tool purpose
4. **Google-style docstrings**: Used for parameter descriptions

## Docstring Formats

Google style (default):
```python
@agent.tool_plain
async def search(query: str, limit: int = 10) -> list[str]:
    """Search for items.

    Args:
        query: The search query.
        limit: Maximum results to return.
    """
```

Sphinx style:
```python
@agent.tool_plain(docstring_format='sphinx')
async def search(query: str) -> list[str]:
    """Search for items.

    :param query: The search query.
    """
```

## Tool Return Types

Tools can return various types:

```python
# String (direct)
@agent.tool_plain
def get_info() -> str:
    return "Some information"

# Pydantic model (serialized to JSON)
@agent.tool_plain
def get_user() -> User:
    return User(name="John", age=30)

# Dict (serialized to JSON)
@agent.tool_plain
def get_data() -> dict[str, Any]:
    return {"key": "value"}

# ToolReturn for custom content types
from pydantic_ai import ToolReturn, ImageUrl

@agent.tool_plain
def get_image() -> ToolReturn:
    return ToolReturn(content=[ImageUrl(url="https://...")])
```

## Accessing Context

RunContext provides:

```python
@agent.tool
async def my_tool(ctx: RunContext[MyDeps]) -> str:
    # Dependencies
    db = ctx.deps.db
    api = ctx.deps.api_client

    # Model info
    model_name = ctx.model.model_name

    # Usage tracking
    tokens_used = ctx.usage.total_tokens

    # Retry info
    attempt = ctx.retry  # Current retry attempt (0-based)
    max_retries = ctx.max_retries

    # Message history
    messages = ctx.messages

    return "result"
```

## Tool Prepare Functions

Dynamically modify tools per-request:

```python
from pydantic_ai.tools import ToolDefinition

async def prepare_tools(
    ctx: RunContext[MyDeps],
    tool_defs: list[ToolDefinition]
) -> list[ToolDefinition]:
    """Filter or modify tools based on context."""
    if ctx.deps.user_role != 'admin':
        # Hide admin tools from non-admins
        return [t for t in tool_defs if not t.name.startswith('admin_')]
    return tool_defs

agent = Agent('openai:gpt-4o', prepare_tools=prepare_tools)
```

## Toolsets

Group and compose tools:

```python
from pydantic_ai import FunctionToolset, CombinedToolset

# Create a toolset
db_tools = FunctionToolset()

@db_tools.tool
def query_users(name: str) -> list[dict]:
    """Query users by name."""
    ...

@db_tools.tool
def update_user(id: int, data: dict) -> bool:
    """Update user data."""
    ...

# Use in agent
agent = Agent('openai:gpt-4o', toolsets=[db_tools])

# Combine toolsets
all_tools = CombinedToolset([db_tools, api_tools])
```

## Common Mistakes

### Wrong: Context in tool_plain
```python
@agent.tool_plain
async def bad_tool(ctx: RunContext[MyDeps]) -> str:  # ERROR!
    ...
```

### Wrong: Missing context in tool
```python
@agent.tool
def bad_tool(user_id: int) -> str:  # ERROR!
    ...
```

### Wrong: Context not first parameter
```python
@agent.tool
def bad_tool(user_id: int, ctx: RunContext[MyDeps]) -> str:  # ERROR!
    ...
```

## Async vs Sync

Both work, but async is preferred for I/O:

```python
# Async (preferred for I/O operations)
@agent.tool
async def fetch_data(ctx: RunContext[Deps]) -> str:
    return await ctx.deps.client.get('/data')

# Sync (fine for CPU-bound operations)
@agent.tool_plain
def compute(x: int, y: int) -> int:
    return x * y
```

<!-- cross-ref:start -->

## See also (related skills — Pydantic AI family)

If your issue relates to:
- **main Pydantic AI guide with reference files (start here)** — check `pydantic-ai-agent-builder` if appropriate.
- **common mistakes and debugging Pydantic AI agents** — check `pydantic-ai-common-pitfalls` if appropriate.
- **RunContext, deps_type, dependency injection patterns** — check `pydantic-ai-dependency-injection` if appropriate.
- **configuring providers, fallback models, streaming, settings** — check `pydantic-ai-model-integration` if appropriate.
- **TestModel, FunctionModel, VCR cassettes, inline snapshots** — check `pydantic-ai-testing` if appropriate.
- **framework reference — structured outputs, providers, streaming** — check `pydanticai-docs` if appropriate.

<!-- cross-ref:end -->

