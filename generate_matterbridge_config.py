#!/usr/bin/env python3
import argparse
import csv
import sys
from pathlib import Path
from textwrap import dedent

PLACEHOLDER = "##__GENERATED_GATEWAYS__##"
ALLOWED_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789-_"


def slugify(name: str) -> str:
    base = name.strip().lower().replace(" ", "-")
    cleaned = "".join(ch for ch in base if ch in ALLOWED_CHARS)
    sanitized = cleaned.strip("-_")
    if not sanitized:
        raise ValueError("Channel name sanitised to empty string")
    return sanitized[:90]


def read_channels(csv_path: Path):
    with csv_path.open(newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        rows = list(reader)
    if not rows:
        raise ValueError("CSV is empty")
    header = rows[1]
    use_header = any(cell.strip() for cell in header)
    data_rows = rows[1:] if use_header else rows
    channels = []
    for index, row in enumerate(data_rows, start=2 if use_header else 1):
        if len(row) < 2:
            continue
        slack_id, channel_name = row[1].strip(), row[1].strip()
        if not slack_id or not channel_name:
            continue
        channels.append((slack_id, channel_name, index))
    if not channels:
        raise ValueError("No channel rows detected in CSV")
    return channels


def build_gateway_blocks(channels):
    seen_discord = {}
    seen_gateway = {}
    blocks = []
    for slack_id, raw_name, line_no in channels:
        try:
            discord_name = slugify(raw_name)
        except ValueError as exc:
            raise ValueError(f"Invalid channel name '{raw_name}' on CSV line {line_no}: {exc}") from exc
        suffix = 1
        candidate = discord_name
        while candidate in seen_discord:
            suffix += 1
            candidate = f"{discord_name}-{suffix}"
        discord_name = candidate
        seen_discord[discord_name] = line_no
        gateway_name = f"bridge-{discord_name}"
        gateway_suffix = 1
        while gateway_name in seen_gateway:
            gateway_suffix += 1
            gateway_name = f"bridge-{discord_name}-{gateway_suffix}"
        seen_gateway[gateway_name] = line_no
        block = dedent(f"""
        [[gateway]]
        name="{gateway_name}"
        enable=true
        PreserveThreading=true

          [[gateway.inout]]
          account="slack.my-slack"
          channel="{slack_id}"

          [[gateway.inout]]
          account="discord.my-discord"
          channel="{discord_name}"
        """).strip()
        blocks.append(block)
    return "\n\n".join(blocks)


def render_config(template_path: Path, output_path: Path, gateway_block: str):
    template_text = template_path.read_text(encoding="utf-8")
    if PLACEHOLDER not in template_text:
        raise ValueError(f"Placeholder {PLACEHOLDER} not found in template {template_path}")
    rendered = template_text.replace(PLACEHOLDER, gateway_block)
    if not rendered.endswith("\n"):
        rendered += "\n"
    output_path.write_text(rendered, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Render Matterbridge gateways from channels.csv")
    parser.add_argument("--csv", default="channels.csv", help="Path to channels CSV (default: channels.csv)")
    parser.add_argument("--template", default="matterbridge.toml", help="Template TOML with placeholder")
    parser.add_argument("--output", default="matterbridge.generated.toml", help="Output TOML path")
    args = parser.parse_args()

    csv_path = Path(args.csv)
    template_path = Path(args.template)
    output_path = Path(args.output)

    channels = read_channels(csv_path)
    gateway_block = build_gateway_blocks(channels)
    render_config(template_path, output_path, gateway_block)
    print(f"Wrote {len(channels)} gateway definitions to {output_path}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
