import json
import re
import sys

if __name__ == "__main__":
    data = json.load(sys.stdin)
    for feat in data["features"]:
        keys = list(feat["properties"].keys())
        for key in keys:
            feat["properties"][
                re.sub(r"[^a-z\s]", "", key.lower()).replace(" ", "_")
            ] = feat["properties"].pop(key)
    json.dump(data, sys.stdout)
