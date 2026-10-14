"""Read-only selected OOC product evidence; no app/backend execution."""
import argparse
import hashlib
import json
import zipfile
from inspect_apk import hermes_strings

GROUPS = {
    "reply_presentation": ["LoadingMessage", "StreamLoading",
        "appendChunkToStreamingMessage", "handleStopStreaming", "MessageStreamingSync"],
    "publication": ["VISIBILITY_PUBLIC", "VISIBILITY_PRIVATE", "VISIBILITY_SECRET",
        "usePatchStoryVisibility", "/ooc-api/story-drafts", "/ooc-api/story-drafts/v2"],
    "community": ["storyCommentControllerCreate", "storyCommentControllerReport",
        "storyCommentControllerPin", "profileControllerSearchProfile",
        "New from Creators You Follow", "FollowingCreatorDetailScreen"],
    "creation_and_memory": ["StoryUserNoteScreen", "chatV3ControllerCreateSummary",
        "chatV3ControllerUpdateSummary", "chatV3ControllerGetSummariesVersion",
        "getOOCOriginalStatsConfig"],
    "branching": ["parent_chat_id", "chatV3ControllerApplySnapshot",
        "chatV3ControllerBranchChat", "useCreateBranch"],
    "endings": ["EndingCollectionScreen", "EndingDetailScreen",
        "CreateStoryDraftEndingConditionRequestGroupOperator",
        "CreateStoryEndingConditionRuleRequestComparisonOperator", "EndingHintSheet"],
    "shortcuts": ["My Slash Commands", "Slash Command Hub",
        "The prompt to inject when this slash command is used",
        "Other users can find and save your slash command."],
    "creator_program": ["Official Creator", "Certified Creator",
        "/ooc-api/creators/me/revenue", "/ooc-api/creators/missions/status"],
    "ai_rpg": ["AIRPGGameScreen", "AIRPGReturnByDeathUpdateCard",
        "AIRPGRespawnUpdateCard", "AIRPGRequiredDice", "useAIRPGSocket"],
}

def inspect(path):
    digest = hashlib.sha256()
    with open(path, "rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    with zipfile.ZipFile(path) as apk:
        strings = hermes_strings(apk.read("assets/index.android.bundle"))
        index = {value: i for i, value in enumerate(strings)}
        evidence = {group: [{"value": term, "string_id": index[term]}
                    for term in terms if term in index]
                    for group, terms in GROUPS.items()}
        missing = {group: [term for term in terms if term not in index]
                   for group, terms in GROUPS.items()}
        return {"sha256": digest.hexdigest(), "hermes_version": 96,
                "string_count": len(strings), "static_only": True,
                "interpretation": "Presence of references, not runtime verification",
                "evidence": evidence, "missing": missing}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk")
    args = parser.parse_args()
    print(json.dumps(inspect(args.apk), ensure_ascii=False, indent=2))
