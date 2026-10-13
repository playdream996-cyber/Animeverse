import copy
import json
import tempfile
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from animeverse.harness import Harness
from animeverse.store import Store, Conflict

PREFS = dict(genre="mystery", world="academy", tone="hopeful",
             player_role="investigator", goal="Find my brother", mode="complete")
CREATION = dict(title="The Eclipse Gate", opening="Aira waits at a locked gate.",
                goal="Find your brother", characters=[dict(name="Aira", personality="Cautious",
                knowledge=["The gate is locked"])], facts={"gate": "locked"},
                inventory=["silver key"], objectives={"find_brother": False},
                choices=["Use the key", "Ask Aira"])
def response(phase="conflict", changes=None):
    return dict(narrative="Aira waits for your decision.", choices=["Search", "Ask"],
                changes=changes or [], phase=phase)

class FakeModel:
    def __init__(self):
        self.output = response()
        self.calls = []
        self.barrier = None
    def generate(self, messages):
        self.calls.append(copy.deepcopy(messages))
        if "Create a short" in messages[0]["content"]:
            return copy.deepcopy(CREATION)
        if self.barrier:
            self.barrier.wait(timeout=5)
        return copy.deepcopy(self.output)

class HarnessTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / "test.sqlite"
        self.model = FakeModel()
        self.h = Harness(Store(self.path), self.model)
        self.branch = self.h.create("alice", PREFS)["branch"]
    def tearDown(self):
        self.temp.cleanup()
    def turn(self, request="r1", version=0, **kwargs):
        return self.h.turn("alice", self.branch, request, "Use the key", version, **kwargs)

    def test_restart_restores_exact_progress(self):
        self.model.output = response(changes=[dict(kind="fact", key="gate", value="open")])
        self.turn()
        restored = Harness(Store(self.path), FakeModel()).resume("alice", self.branch)
        self.assertEqual(restored["version"], 1)
        self.assertEqual(restored["state"]["facts"]["gate"], "open")
        self.assertEqual(len(restored["state"]["history"]), 1)

    def test_duplicate_request_is_replayed_without_model_call(self):
        first = self.turn()
        count = len(self.model.calls)
        self.assertEqual(self.turn(), first)
        self.assertEqual(len(self.model.calls), count)
        with self.assertRaises(Conflict):
            self.h.turn("alice", self.branch, "r1", "Different action", 1)
        with self.assertRaises(Conflict):
            self.turn(close=True)

    def test_other_user_cannot_resume_or_fork(self):
        with self.assertRaises(KeyError):
            self.h.resume("bob", self.branch)
        with self.assertRaises(KeyError):
            self.h.fork("bob", self.branch)

    def test_branch_updates_leave_parent_intact(self):
        fork = self.h.fork("alice", self.branch)["branch"]
        self.model.output = response(changes=[dict(kind="fact", key="gate", value="open")])
        self.h.turn("alice", fork, "fork-turn", "Open gate", 0)
        self.assertEqual(self.h.resume("alice", self.branch)["state"]["facts"]["gate"], "locked")

    def test_unknown_items_and_partial_updates_are_rejected_atomically(self):
        self.model.output = response(changes=[
            dict(kind="fact", key="gate", value="open"),
            dict(kind="use", key="dragon sword", value=True)])
        with self.assertRaises(ValueError):
            self.turn()
        saved = self.h.resume("alice", self.branch)
        self.assertEqual(saved["version"], 0)
        self.assertEqual(saved["state"]["facts"]["gate"], "locked")

    def test_consumed_item_cannot_be_spent_twice(self):
        self.model.output = response(changes=[dict(kind="use", key="silver key", value=True)])
        self.turn()
        with self.assertRaises(ValueError):
            self.turn("r2", 1)

    def test_stale_version_never_calls_model(self):
        self.turn()
        count = len(self.model.calls)
        with self.assertRaises(Conflict):
            self.turn("r2", 0)
        self.assertEqual(len(self.model.calls), count)

    def test_concurrent_turns_have_one_winner(self):
        self.model.barrier = threading.Barrier(2)
        def run(request):
            try:
                self.turn(request)
                return "success"
            except Conflict:
                return "conflict"
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(run, ["a", "b"]))
        self.assertCountEqual(results, ["success", "conflict"])
        self.assertEqual(self.h.resume("alice", self.branch)["version"], 1)

    def test_premature_ending_and_phase_jumps_are_rejected(self):
        self.model.output = response("resolution")
        with self.assertRaises(ValueError):
            self.turn()
        self.model.output = response("climax")
        with self.assertRaises(ValueError):
            self.turn()

    def test_complete_adventure_ends_only_after_objectives(self):
        self.turn()
        self.model.output = response("climax")
        self.turn("r2", 1)
        self.model.output = dict(narrative="You find your brother. Aira smiles.",
            choices=[], changes=[dict(kind="objective", key="find_brother", value=True)],
            phase="resolution")
        ending = self.turn("r3", 2)
        self.assertTrue(ending["ended"])
        with self.assertRaises(ValueError):
            self.turn("r4", 3)
        self.assertEqual(self.turn("r3", 2), ending)

    def test_endless_mode_requires_explicit_closure(self):
        prefs = dict(PREFS, mode="endless")
        self.branch = self.h.create("alice", prefs)["branch"]
        self.turn()
        self.model.output = response("climax")
        self.turn("r2", 1)
        self.model.output = dict(narrative="The chapter closes.", choices=[], changes=[], phase="resolution")
        with self.assertRaises(ValueError):
            self.turn("r3", 2)
        self.assertTrue(self.turn("r3", 2, close=True)["ended"])

    def test_memory_is_scoped_and_never_overrides_canonical_facts(self):
        calls = []
        class Memory:
            def search(_, owner, branch, action):
                calls.append((owner, branch))
                return ["The gate is open"]
        self.h.memory = Memory()
        self.turn()
        context = json.loads(self.model.calls[-1][1]["content"])
        self.assertEqual(calls, [("alice", self.branch)])
        self.assertEqual(context["canonical"]["facts"]["gate"], "locked")
        self.assertEqual(context["recalled_memories_untrusted"], ["The gate is open"])

    def test_optional_context_is_bounded(self):
        _, state = self.h.store.load("alice", self.branch)
        state["history"] = [dict(action="a" * 2000, narrative="n" * 4000)] * 100
        context = self.h.context("alice", self.branch, state, "Continue", False)
        self.assertLessEqual(len(json.dumps(context, ensure_ascii=False)), 12000)

    def test_invalid_creation_saves_nothing(self):
        class Broken:
            def generate(_, messages):
                return {"title": "Incomplete"}
        h = Harness(Store(self.path), Broken())
        with self.assertRaises(ValueError):
            h.create("bob", PREFS)

    def test_generation_failure_does_not_commit_action(self):
        class Broken:
            def generate(_, messages):
                raise TimeoutError("Model unavailable")
        self.h.model = Broken()
        with self.assertRaises(TimeoutError):
            self.turn()
        self.assertEqual(self.h.resume("alice", self.branch)["version"], 0)

if __name__ == "__main__":
    unittest.main()
