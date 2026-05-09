"""
Question generation engine.
Uses Command R7B Arabic running locally via Ollama (free, no API key needed).
Supports Arabic (primary) and English.

Make sure Ollama is running before starting this service:
    ollama serve
    ollama pull command-r7b-arabic
"""

import json
import re
import os
import urllib.request
import urllib.error

from embedder import Embedder
from prompts  import build_prompt

OLLAMA_URL   = os.getenv("OLLAMA_URL",   "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "command-r7b-arabic")


class QuestionEngine:
    def __init__(self, embedder: Embedder):
        self.embedder = embedder
        self._check_ollama()

    def _check_ollama(self):
        """Verify Ollama is running and the model is available."""
        try:
            with urllib.request.urlopen(f"{OLLAMA_URL}/api/tags", timeout=3) as resp:
                data     = json.loads(resp.read())
                models   = [m["name"] for m in data.get("models", [])]
                # Check if our model (with or without tag) is pulled
                base     = OLLAMA_MODEL.split(":")[0]
                available = any(base in m for m in models)
                if not available:
                    print(f"[QuestionEngine] WARNING: Model '{OLLAMA_MODEL}' not found.")
                    print(f"  Run:  ollama pull {OLLAMA_MODEL}")
                else:
                    print(f"[QuestionEngine] Ollama ready — model: {OLLAMA_MODEL}")
        except urllib.error.URLError:
            print("[QuestionEngine] WARNING: Ollama is not running.")
            print("  Start it with:  ollama serve")

    # ── Public method ─────────────────────────────────────────────────────────

    def generate(
        self,
        document_id:    str,
        num_questions:  int,
        question_types: list[str],
        bloom_levels:   list[str],
        difficulty:     str,
        language:       str,
        topic_hint:     str = "",
    ) -> list[dict]:
        """
        Generate `num_questions` questions from the stored document.
        Question types and Bloom's levels are cycled if fewer than num_questions.
        """
        questions = []

        for i in range(num_questions):
            q_type = question_types[i % len(question_types)]
            bloom  = bloom_levels[i  % len(bloom_levels)]

            # Retrieve relevant context chunks for this question
            query  = topic_hint or f"{bloom} level question about the main topic"
            chunks = self.embedder.retrieve(document_id, query, top_k=3)
            if not chunks:
                chunks = self.embedder.get_random_chunks(document_id, n=3)

            context = "\n\n".join(chunks)

            system_prompt, user_prompt = build_prompt(
                context=context,
                question_type=q_type,
                bloom_level=bloom,
                difficulty=difficulty,
                language=language,
                question_num=i + 1,
            )

            print(f"  Generating question {i+1}/{num_questions} "
                  f"[{q_type} | {bloom} | {difficulty}]...")

            question = self._call_ollama(system_prompt, user_prompt, q_type, bloom, difficulty)
            if question:
                questions.append(question)

        return questions

    # ── Ollama call ───────────────────────────────────────────────────────────

    def _call_ollama(
        self,
        system_prompt: str,
        user_prompt:   str,
        q_type:        str,
        bloom_level:   str,
        difficulty:    str,
    ) -> dict | None:
        payload = json.dumps({
            "model": OLLAMA_MODEL,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user",   "content": user_prompt},
            ],
            "stream": False,
            "options": {
                "temperature": 0.7,
                "num_predict": 1024,
            },
        }).encode("utf-8")

        req = urllib.request.Request(
            f"{OLLAMA_URL}/api/chat",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=300) as resp:
                data = json.loads(resp.read())
                raw  = data["message"]["content"].strip()
                return self._parse_json(raw, q_type, bloom_level, difficulty)

        except urllib.error.URLError as e:
            print(f"[QuestionEngine] Ollama request failed: {e}")
            return None
        except (KeyError, json.JSONDecodeError) as e:
            print(f"[QuestionEngine] Bad response from Ollama: {e}")
            return None

    # ── JSON parser ───────────────────────────────────────────────────────────

    def _parse_json(
        self,
        raw:         str,
        q_type:      str,
        bloom_level: str,
        difficulty:  str,
    ) -> dict | None:
        # Strip markdown fences that the model sometimes adds
        raw = re.sub(r"```(?:json)?", "", raw).strip().rstrip("`").strip()

        # Remove LaTeX math notation the model sometimes inserts (e.g. \( \text{ATP} \))
        raw = re.sub(r"\\\(.*?\\\)", lambda m: re.sub(r"\\text\{([^}]+)\}", r"\1", m.group()).replace("\\(","").replace("\\)","").strip(), raw)
        raw = re.sub(r"\$[^$]+\$", "", raw)   # strip $...$

        def _try_parse(text: str) -> dict | None:
            try:
                data = json.loads(text)
                data.setdefault("type",        q_type)
                data.setdefault("bloom_level", bloom_level)
                data.setdefault("difficulty",  difficulty)
                # Normalise bloom/difficulty to lowercase
                data["bloom_level"] = str(data["bloom_level"]).lower()
                data["difficulty"]  = str(data["difficulty"]).lower()
                return data
            except json.JSONDecodeError:
                return None

        result = _try_parse(raw)
        if result:
            return result

        # Try to extract the first {...} block from the text
        match = re.search(r'\{.*\}', raw, re.DOTALL)
        if match:
            result = _try_parse(match.group())
            if result:
                return result

        print(f"[QuestionEngine] Could not parse JSON:\n{raw[:300]}")
        return None
