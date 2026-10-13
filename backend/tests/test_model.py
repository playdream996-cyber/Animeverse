import io
import json
import unittest
from unittest.mock import patch
from animeverse.model import OllamaModel

class TransportTests(unittest.TestCase):
    def test_ollama_contract_and_json_parsing(self):
        envelope = json.dumps({"message": {"content": '{"narrative":"Hello"}'}}).encode()
        with patch("urllib.request.urlopen", return_value=io.BytesIO(envelope)) as call:
            self.assertEqual(OllamaModel().generate([{"role":"user","content":"hi"}]), {"narrative":"Hello"})
        request = call.call_args.args[0]
        body = json.loads(request.data)
        self.assertFalse(body["stream"])
        self.assertFalse(body["think"])
        self.assertEqual(body["format"], "json")
        self.assertEqual(request.full_url, "http://127.0.0.1:11434/api/chat")

    def test_malformed_model_json_is_rejected(self):
        with patch("urllib.request.urlopen", return_value=io.BytesIO(b'{"message":{"content":"not json"}}')):
            with self.assertRaises(ValueError):
                OllamaModel().generate([])

if __name__ == "__main__":
    unittest.main()
