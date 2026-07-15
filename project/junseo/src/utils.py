import os
from pathlib import Path

from google import genai
from google.genai import types
from dotenv import load_dotenv
from langfuse import Langfuse

ENV_PATH = Path(__file__).parent.parent.parent.parent / ".env"
load_dotenv(dotenv_path=ENV_PATH)

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

langfuse = Langfuse(
    public_key=os.getenv("LANGFUSE_PUBLIC_KEY"),
    secret_key=os.getenv("LANGFUSE_SECRET_KEY"),
    host=os.getenv("LANGFUSE_HOST"),
)


def _validate_model(model: str) -> None:
    if not model.startswith("gemini"):
        raise ValueError(f"Only Gemini models are supported. Got: '{model}'")


def _openai_tools_to_gemini(openai_tools: list) -> list[types.Tool]:
    """Convert OpenAI-format tool definitions to google.genai Tool objects."""
    declarations = []
    for tool in openai_tools:
        func = tool["function"]
        declarations.append(
            types.FunctionDeclaration(
                name=func["name"],
                description=func["description"],
                parameters=func.get("parameters", {}),
            )
        )
    return [types.Tool(function_declarations=declarations)]


def call_with_tools(
    model: str,
    system_prompt: str,
    user_message: str,
    tools: list,
    temperature: float = 0.0,
    top_p: float = 1.0,
    top_k: int = 40,
) -> dict:
    """
    Call a Gemini model with tool definitions.

    Returns:
        {
            "called_tool": bool,
            "tool_name": str | None,
            "tool_args": dict | None,
            "response_text": str | None,
        }
    """
    _validate_model(model)

    gemini_tools = _openai_tools_to_gemini(tools)
    safety_settings = [
        types.SafetySetting(category="HARM_CATEGORY_HARASSMENT",        threshold="BLOCK_NONE"),
        types.SafetySetting(category="HARM_CATEGORY_HATE_SPEECH",        threshold="BLOCK_NONE"),
        types.SafetySetting(category="HARM_CATEGORY_SEXUALLY_EXPLICIT",  threshold="BLOCK_NONE"),
        types.SafetySetting(category="HARM_CATEGORY_DANGEROUS_CONTENT",  threshold="BLOCK_NONE"),
    ]

    config = types.GenerateContentConfig(
        system_instruction=system_prompt,
        tools=gemini_tools,
        tool_config=types.ToolConfig(
            function_calling_config=types.FunctionCallingConfig(mode="AUTO")
        ),
        safety_settings=safety_settings,
        temperature=temperature,
        top_p=top_p,
        top_k=top_k,
    )

    with langfuse.start_as_current_generation(
        name="gemini-tool-call",
        model=model,
        input={"system": system_prompt, "user": user_message},
        model_parameters={"temperature": temperature, "top_p": top_p, "top_k": top_k},
    ) as gen:
        response = client.models.generate_content(
            model=model,
            contents=user_message,
            config=config,
        )

        candidate = response.candidates[0] if response.candidates else None

        if candidate and candidate.content and candidate.content.parts:
            for part in candidate.content.parts:
                if part.function_call and part.function_call.name:
                    fc = part.function_call
                    result = {
                        "called_tool": True,
                        "tool_name": fc.name,
                        "tool_args": dict(fc.args) if fc.args else {},
                        "response_text": None,
                    }
                    gen.update(output={"tool_name": fc.name, "tool_args": result["tool_args"]})
                    return result

        try:
            text = response.text
        except Exception:
            finish = candidate.finish_reason if candidate else "unknown"
            text = f"[blocked: finish_reason={finish}]"

        gen.update(output={"response_text": text})

    return {
        "called_tool": False,
        "tool_name": None,
        "tool_args": None,
        "response_text": text,
    }


def call_text(
    model: str,
    system_prompt: str,
    user_message: str,
    temperature: float = 0.0,
    top_p: float = 1.0,
    top_k: int = 40,
) -> str:
    """Call a Gemini model for a plain text response (no tools)."""
    _validate_model(model)

    config = types.GenerateContentConfig(
        system_instruction=system_prompt,
        temperature=temperature,
        top_p=top_p,
        top_k=top_k,
    )

    with langfuse.start_as_current_generation(
        name="gemini-text-call",
        model=model,
        input={"system": system_prompt, "user": user_message},
        model_parameters={"temperature": temperature, "top_p": top_p, "top_k": top_k},
    ) as gen:
        response = client.models.generate_content(
            model=model,
            contents=user_message,
            config=config,
        )
        try:
            text = response.text
        except Exception:
            text = None
        gen.update(output={"response_text": text})

    return text
