import base64
import json
import os
import re
from datetime import datetime, timezone

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
ROLES = {"エンジニア", "デザイナー", "プロダクトマネージャー", "セールス", "コーポレート"}

# 名前の最大文字数 (アプリの入力欄と揃える)
MAX_NAME_LENGTH = 30

# アバターのグラデーションの色 (#RRGGBB)
COLOR_PATTERN = re.compile(r"#[0-9A-Fa-f]{6}")

table = boto3.resource("dynamodb").Table(TABLE_NAME)


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json; charset=utf-8"},
        "body": json.dumps(body, ensure_ascii=False),
    }


def _user_id(event):
    """JWT オーソライザーが確かめたトークンから、サインインしている人の番号 (sub) を取り出す"""
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    return claims.get("sub")


def _parse_body(event):
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")
    return json.loads(body)


def _validate(body):
    """リクエストの中身を確かめる。問題があればその内容、なければ None を返す"""
    if not isinstance(body, dict):
        return "body must be a JSON object"

    name = body.get("name")
    if not isinstance(name, str) or not name.strip():
        return "name is required"
    if len(name.strip()) > MAX_NAME_LENGTH:
        return f"name must be at most {MAX_NAME_LENGTH} characters"
    if body.get("role") not in ROLES:
        return f"unknown role: {body.get('role')}"

    for key in ("color1", "color2"):
        color = body.get(key)
        if not isinstance(color, str) or not COLOR_PATTERN.fullmatch(color):
            return f"{key} must be a color like #E8BD79"

    return None


def lambda_handler(event, context):
    user_id = _user_id(event)
    if not user_id:
        # オーソライザーを付け忘れたルートから呼ばれたとき
        return _response(401, {"message": "Unauthorized"})

    try:
        body = _parse_body(event)
    except (ValueError, UnicodeDecodeError):
        return _response(400, {"message": "body must be valid JSON"})

    error = _validate(body)
    if error:
        return _response(400, {"message": error})

    profile = {
        "name": body["name"].strip(),
        "role": body["role"],
        # 大文字・小文字の違いで別の色に見えないよう、大文字にそろえる
        "color1": body["color1"].upper(),
        "color2": body["color2"].upper(),
        # UTC の ISO 8601 形式 (例: 2026-10-16T09:00:00Z)。投稿の postedAt と同じ形
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    # 初めてなら作成、あれば丸ごと置き換える (PUT なので何度送っても同じ結果になる)
    table.put_item(Item={"userId": user_id, **profile})

    return _response(200, {"profile": profile})
