"""Azure AI Foundry Agentic Agent — Multi-tool demo.

Creates an agent with Code Interpreter, File Search, and Custom Function Calling,
then runs a multi-turn conversation to showcase agentic capabilities.
"""

import json
import os
import sys

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    AgentThread,
    CodeInterpreterTool,
    FunctionTool,
    MessageRole,
    RunStatus,
    SubmitToolOutputsAction,
    ThreadRun,
    ToolOutput,
)
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

from tools import ALL_TOOL_SCHEMAS, FUNCTION_HANDLERS

load_dotenv()

ENDPOINT = os.environ.get("AZURE_AI_PROJECT_ENDPOINT", "")
MODEL = "gpt-4o-mini"


def create_client() -> AIProjectClient:
    """Create an authenticated AIProjectClient using DefaultAzureCredential."""
    if not ENDPOINT:
        print("ERROR: Set AZURE_AI_PROJECT_ENDPOINT in .env or environment.")
        sys.exit(1)
    return AIProjectClient(endpoint=ENDPOINT, credential=DefaultAzureCredential())


def create_agent(client: AIProjectClient) -> str:
    """Create an agent with Code Interpreter and Custom Functions."""
    code_interpreter = CodeInterpreterTool()
    custom_functions = FunctionTool(functions=ALL_TOOL_SCHEMAS)

    agent = client.agents.create_agent(
        model=MODEL,
        name="foundry-demo-agent",
        instructions=(
            "You are a helpful assistant with access to multiple tools.\n"
            "- Use the Code Interpreter to run Python code for calculations or data analysis.\n"
            "- Use get_weather() to look up current weather for any city.\n"
            "- Use lookup_inventory() to check product stock levels.\n"
            "Always explain what tool you are using and why."
        ),
        tools=code_interpreter.definitions + custom_functions.definitions,
    )
    print(f"[+] Agent created: {agent.id}")
    return agent.id


def run_conversation(client: AIProjectClient, agent_id: str) -> None:
    """Run a multi-turn conversation demonstrating all tools."""
    thread: AgentThread = client.agents.create_thread()
    print(f"[+] Thread created: {thread.id}\n")

    prompts = [
        "What's the weather like in Stockholm and Tokyo right now?",
        "Check the inventory for SKU-1234 and SKU-5678. Which one is out of stock?",
        "Using code interpreter, calculate the compound interest on $10,000 at 5% annual rate over 10 years, compounded monthly. Show the formula and result.",
    ]

    for i, prompt in enumerate(prompts, 1):
        print(f"{'='*60}")
        print(f"Turn {i}: {prompt}")
        print(f"{'='*60}")

        client.agents.create_message(
            thread_id=thread.id,
            role=MessageRole.USER,
            content=prompt,
        )

        run: ThreadRun = client.agents.create_run(
            thread_id=thread.id,
            agent_id=agent_id,
        )

        run = _process_run(client, thread.id, run)

        messages = client.agents.list_messages(thread_id=thread.id)
        latest = messages.data[0]
        for content_block in latest.content:
            if hasattr(content_block, "text"):
                print(f"\nAssistant:\n{content_block.text.value}\n")

    client.agents.delete_thread(thread.id)
    print("[+] Thread deleted — conversation complete.")


def _process_run(client: AIProjectClient, thread_id: str, run: ThreadRun) -> ThreadRun:
    """Poll a run to completion, handling function calls as they arise."""
    while run.status in (RunStatus.QUEUED, RunStatus.IN_PROGRESS, RunStatus.REQUIRES_ACTION):
        if run.status == RunStatus.REQUIRES_ACTION:
            run = _handle_tool_calls(client, thread_id, run)
        else:
            import time
            time.sleep(1)
            run = client.agents.get_run(thread_id=thread_id, run_id=run.id)

    if run.status == RunStatus.FAILED:
        print(f"[!] Run failed: {run.last_error}")
    return run


def _handle_tool_calls(client: AIProjectClient, thread_id: str, run: ThreadRun) -> ThreadRun:
    """Execute required function calls and submit outputs back to the run."""
    action: SubmitToolOutputsAction = run.required_action
    tool_outputs: list[ToolOutput] = []

    for tool_call in action.submit_tool_outputs.tool_calls:
        fn_name = tool_call.function.name
        fn_args = json.loads(tool_call.function.arguments)
        print(f"  -> Calling {fn_name}({fn_args})")

        handler = FUNCTION_HANDLERS.get(fn_name)
        if handler:
            result = handler(fn_args)
        else:
            result = json.dumps({"error": f"Unknown function: {fn_name}"})

        tool_outputs.append(ToolOutput(tool_call_id=tool_call.id, output=result))

    run = client.agents.submit_tool_outputs_to_run(
        thread_id=thread_id,
        run_id=run.id,
        tool_outputs=tool_outputs,
    )
    return run


def main() -> None:
    """Entry point — create client, agent, run conversation, clean up."""
    client = create_client()
    agent_id = create_agent(client)

    try:
        run_conversation(client, agent_id)
    finally:
        client.agents.delete_agent(agent_id)
        print("[+] Agent deleted — cleanup complete.")


if __name__ == "__main__":
    main()
