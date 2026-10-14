"""Replaceable model transport; does not store canonical state."""
import json
import urllib.request

class OllamaModel:
    def __init__(self, model="qwen3:4b", url="http://127.0.0.1:11434", timeout=120):
        self.model, self.url, self.timeout = model, url.rstrip("/"), timeout

    def generate(self, messages):
        body = json.dumps({"model": self.model, "messages": messages,
                           "stream": False, "think": False, "format": "json",
                           "options": {"num_ctx": 4096, "num_predict": 900}}).encode()
        request = urllib.request.Request(self.url + "/api/chat", body,
                                          {"Content-Type": "application/json"})
        with urllib.request.urlopen(request, timeout=self.timeout) as response:
            raw = response.read(1_000_001)
        if len(raw) > 1_000_000:
            raise ValueError("Model response too large")
        envelope = json.loads(raw)
        if envelope.get("error"):
            raise ValueError("Model generation failed")
        return json.loads(envelope["message"]["content"])
