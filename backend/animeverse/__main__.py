import argparse
import json
from .harness import Harness
from .model import OllamaModel
from .store import Store

parser = argparse.ArgumentParser(description="Local adventure harness; no public HTTP server")
parser.add_argument("--db", default="adventures.sqlite")
parser.add_argument("--model", default="qwen3:4b")
parser.add_argument("--owner", required=True, help="Trusted local identity; not mobile authentication")
commands = parser.add_subparsers(dest="command", required=True)
create = commands.add_parser("create")
create.add_argument("preferences", help="Path to preferences JSON")
resume = commands.add_parser("resume"); resume.add_argument("branch")
fork = commands.add_parser("fork"); fork.add_argument("branch")
turn = commands.add_parser("turn")
turn.add_argument("branch"); turn.add_argument("action"); turn.add_argument("--request", required=True)
turn.add_argument("--version", required=True, type=int); turn.add_argument("--close", action="store_true")
args = parser.parse_args()
h = Harness(Store(args.db), OllamaModel(args.model))
if args.command == "create":
    with open(args.preferences) as f:
        result = h.create(args.owner, json.load(f))
elif args.command == "resume":
    result = h.resume(args.owner, args.branch)
elif args.command == "fork":
    result = h.fork(args.owner, args.branch)
else:
    result = h.turn(args.owner, args.branch, args.request, args.action, args.version, args.close)
print(json.dumps(result, ensure_ascii=False, indent=2))
