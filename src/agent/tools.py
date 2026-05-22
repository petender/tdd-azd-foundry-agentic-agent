"""Custom function definitions for the Azure AI Foundry agentic agent.

Each function has a JSON schema for the model and a handler that executes locally.
"""

import json
from typing import Any

# ──────────────────────────────────────────────
# Function JSON schemas (passed to the agent)
# ──────────────────────────────────────────────

GET_WEATHER_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get the current weather for a given city. Returns temperature in Celsius and a short description.",
        "parameters": {
            "type": "object",
            "properties": {
                "city": {
                    "type": "string",
                    "description": "The city name, e.g. 'Stockholm' or 'New York'.",
                }
            },
            "required": ["city"],
        },
    },
}

LOOKUP_INVENTORY_SCHEMA = {
    "type": "function",
    "function": {
        "name": "lookup_inventory",
        "description": "Look up the current inventory count for a product by its product ID.",
        "parameters": {
            "type": "object",
            "properties": {
                "product_id": {
                    "type": "string",
                    "description": "The product identifier, e.g. 'SKU-1234'.",
                }
            },
            "required": ["product_id"],
        },
    },
}

ALL_TOOL_SCHEMAS = [GET_WEATHER_SCHEMA, LOOKUP_INVENTORY_SCHEMA]

# ──────────────────────────────────────────────
# Function handlers (execute locally)
# ──────────────────────────────────────────────

_MOCK_WEATHER: dict[str, dict[str, Any]] = {
    "stockholm": {"temp_c": 12, "description": "Partly cloudy"},
    "new york": {"temp_c": 22, "description": "Sunny"},
    "london": {"temp_c": 15, "description": "Overcast with light rain"},
    "tokyo": {"temp_c": 28, "description": "Hot and humid"},
}

_MOCK_INVENTORY: dict[str, int] = {
    "SKU-1234": 142,
    "SKU-5678": 0,
    "SKU-9012": 37,
    "SKU-3456": 891,
}


def get_weather(city: str) -> str:
    """Return mock weather data for a city."""
    data = _MOCK_WEATHER.get(city.lower(), {"temp_c": 20, "description": "Clear skies"})
    return json.dumps({"city": city, **data})


def lookup_inventory(product_id: str) -> str:
    """Return mock inventory count for a product."""
    count = _MOCK_INVENTORY.get(product_id.upper(), -1)
    if count < 0:
        return json.dumps({"product_id": product_id, "error": "Product not found"})
    return json.dumps({"product_id": product_id, "units_in_stock": count})


# Dispatcher — maps function name to handler
FUNCTION_HANDLERS: dict[str, Any] = {
    "get_weather": lambda args: get_weather(args["city"]),
    "lookup_inventory": lambda args: lookup_inventory(args["product_id"]),
}
