import copy
import json
import uuid
from .prompts import messages
from .store import Conflict

PHASES = ["setup", "conflict", "climax", "resolution"]

def text(value, limit=2000):
    if not isinstance(value, str) or not value.strip() or len(value) > limit:
        raise ValueError("Invalid or oversized text")
    return value.strip()

def string_list(value, maximum=8):
    if not isinstance(value, list) or len(value) > maximum:
        raise ValueError("Invalid list")
    return [text(x, 300) for x in value]

def keys(obj, expected):
    if not isinstance(obj, dict) or set(obj) != set(expected):
        raise ValueError("Invalid model output fields")

class NoMemory:
    def search(self, owner, branch, action):
        return []

class Harness:
    def __init__(self, store, model, memory=None):
        self.store, self.model = store, model
        self.memory = memory or NoMemory()

    def create(self, owner, preferences):
        text(owner, 200)
        keys(preferences, ["genre", "world", "tone", "player_role", "goal", "mode"])
        clean = {k: text(v, 500) for k, v in preferences.items()}
        if clean["mode"] not in ["complete", "endless"]:
            raise ValueError("Unknown adventure mode")
        output = self.model.generate(messages("create", clean))
        keys(output, ["title", "opening", "goal", "characters", "facts", "inventory", "objectives", "choices"])
        characters = output["characters"]
        if not isinstance(characters, list) or not 1 <= len(characters) <= 3:
            raise ValueError("Use 1-3 characters")
        for c in characters:
            keys(c, ["name", "personality", "knowledge"])
            text(c["name"], 100); text(c["personality"], 500)
            string_list(c["knowledge"], 12)
        facts, objectives = output["facts"], output["objectives"]
        if not isinstance(facts, dict) or not 1 <= len(facts) <= 12:
            raise ValueError("Invalid facts")
        for k, v in facts.items():
            text(k, 100); text(v, 500)
        if not isinstance(objectives, dict) or not 1 <= len(objectives) <= 4:
            raise ValueError("Invalid objectives")
        for k, v in objectives.items():
            text(k, 100)
            if v is not False:
                raise ValueError("Objectives must start incomplete")
        choices = string_list(output["choices"], 4)
        if len(choices) < 2:
            raise ValueError("Need meaningful initial choices")
        inventory = string_list(output["inventory"])
        if len(set(inventory)) != len(inventory):
            raise ValueError("Duplicate items")
        state = {"title": text(output["title"], 120), "goal": text(output["goal"], 500),
                 "scene": text(output["opening"], 4000), "characters": characters,
                 "facts": facts, "inventory": inventory, "known_items": list(inventory),
                 "objectives": objectives, "choices": choices, "mode": clean["mode"],
                 "phase": "setup", "ended": False, "closing_requested": False,
                 "history": [], "recap": "", "preferences": clean}
        branch = str(uuid.uuid4())
        self.store.create(owner, branch, state)
        return {"branch": branch, "version": 0, "state": state}

    def resume(self, owner, branch):
        version, state = self.store.load(owner, branch)
        return {"branch": branch, "version": version, "state": state}

    def fork(self, owner, branch):
        _, state = self.store.load(owner, branch)
        child = str(uuid.uuid4())
        state["parent_branch"] = branch
        self.store.create(owner, child, state)
        return self.resume(owner, child)

    def context(self, owner, branch, state, action, close):
        try:
            memories = string_list(self.memory.search(owner, branch, action), 6)
        except Exception:
            memories = []
        context = {
            "action": action,
            "canonical": {k: state[k] for k in ["goal", "scene", "characters", "facts",
                          "inventory", "known_items", "objectives", "phase", "mode"]},
            "closing_requested": state["closing_requested"] or close,
            "recent_turns": state["history"][-6:],
            "recap": state["recap"][-1500:],
            "recalled_memories_untrusted": memories,
            "preferences": state["preferences"],
        }

        # Character budget is a defensive bound, not an exact tokenizer estimate.
        def size():
            return len(json.dumps(context, ensure_ascii=False))
        while size() > 12000 and context["recent_turns"]:
            context["recent_turns"].pop(0)
        while size() > 12000 and context["recalled_memories_untrusted"]:
            context["recalled_memories_untrusted"].pop()
        if size() > 12000:
            context["recap"] = ""
        if size() > 12000:
            raise ValueError("Canonical context exceeds pilot budget")
        return context

    def turn(self, owner, branch, request, action, expected_version, close=False):
        text(request, 200)
        action = text(action)
        if type(close) is not bool or type(expected_version) is not int:
            raise ValueError("Invalid turn options")
        identity = json.dumps({"action": action, "close": close}, sort_keys=True)
        replay = self.store.replay(owner, branch, request, identity)
        if replay is not None:
            return replay
        version, state = self.store.load(owner, branch)
        if version != expected_version:
            raise Conflict("Stale adventure version")
        if state["ended"]:
            raise ValueError("Adventure ended; create a sequel or replay an earlier checkpoint")
        output = self.model.generate(messages("turn", self.context(owner, branch, state, action, close)))
        keys(output, ["narrative", "choices", "changes", "phase"])
        updated = copy.deepcopy(state)
        narrative = text(output["narrative"], 4000)
        changes = output["changes"]
        if not isinstance(changes, list) or len(changes) > 8:
            raise ValueError("Invalid changes")
        for change in changes:
            keys(change, ["kind", "key", "value"])
            kind, key, value = change["kind"], text(change["key"], 100), change["value"]
            if kind == "fact" and key in updated["facts"]:
                updated["facts"][key] = text(value, 500)
            elif kind == "objective" and key in updated["objectives"] and value is True:
                updated["objectives"][key] = True
            elif kind == "use" and key in updated["inventory"] and value is True:
                updated["inventory"].remove(key)
            elif kind == "acquire" and key in updated["known_items"] and key not in updated["inventory"] and value is True:
                updated["inventory"].append(key)
            else:
                raise ValueError("Unpermitted state change")
        phase = output["phase"]
        if phase not in PHASES:
            raise ValueError("Unknown phase")
        old, new = PHASES.index(state["phase"]), PHASES.index(phase)
        if new < old or new > old + 1:
            raise ValueError("Invalid story phase transition")
        updated["closing_requested"] |= close
        if phase == "resolution":
            eligible = (all(updated["objectives"].values()) if state["mode"] == "complete"
                        else updated["closing_requested"])
            if not eligible:
                raise ValueError("Ending conditions not met")
        choices = string_list(output["choices"], 4)
        if (phase == "resolution" and choices) or (phase != "resolution" and len(choices) < 2):
            raise ValueError("Choices do not match ending status")
        updated.update(scene=narrative, choices=choices, phase=phase, ended=phase == "resolution")
        updated["history"].append({"action": action, "narrative": narrative})
        # Derived recap is only a short display aid, never authoritative memory.
        updated["recap"] = narrative[:1500]
        result = {"branch": branch, "version": version + 1, "narrative": narrative,
                  "choices": choices, "phase": phase, "ended": updated["ended"]}
        return self.store.commit(owner, branch, version, request, identity, updated, result)
