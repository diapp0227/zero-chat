import base64
import json
import os
from datetime import datetime, timezone
from decimal import Decimal

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
CATEGORIES = {"announcement", "dailyReport", "selfStudy"}
ROLES = {"エンジニア", "デザイナー", "プロダクトマネージャー", "セールス", "コーポレート"}

# 本文・名前の最大文字数 (アプリの入力欄と揃える)
MAX_TEXT_LENGTH = 180
MAX_NAME_LENGTH = 30

# 投稿の番号を数えるための項目のキー。
# feed / category / postedAt を持たないので、インデックスに載らずタイムラインには出ない
COUNTER_KEY = {"id": 0}

# ログインの仕組みができるまでは、投稿した人の番号を固定にする
GUEST_AUTHOR_ID = 0

table = boto3.resource("dynamodb").Table(TABLE_NAME)


def _to_json(value):
    # DynamoDB の数値は Decimal で返るので int に戻す
    if isinstance(value, Decimal):
        return int(value)
    raise TypeError


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json; charset=utf-8"},
        "body": json.dumps(body, ensure_ascii=False, default=_to_json),
    }


def _parse_body(event):
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")
    return json.loads(body)


def _validate(body):
    """リクエストの中身を確かめる。問題があればその内容、なければ None を返す"""
    if not isinstance(body, dict):
        return "body must be a JSON object"

    category = body.get("category")
    if category not in CATEGORIES:
        return f"unknown category: {category}"

    text = body.get("text")
    if not isinstance(text, str) or not text.strip():
        return "text is required"
    if len(text) > MAX_TEXT_LENGTH:
        return f"text must be at most {MAX_TEXT_LENGTH} characters"

    author = body.get("author")
    if not isinstance(author, dict):
        return "author is required"
    name = author.get("name")
    if not isinstance(name, str) or not name.strip():
        return "author.name is required"
    if len(name) > MAX_NAME_LENGTH:
        return f"author.name must be at most {MAX_NAME_LENGTH} characters"
    if author.get("role") not in ROLES:
        return f"unknown author.role: {author.get('role')}"

    return None


def _next_post_id():
    # 番号の項目を 1 増やし、増やした後の値を受け取る。
    # 同時に投稿されても DynamoDB が 1 つずつ順に処理するので、番号は重ならない
    result = table.update_item(
        Key=COUNTER_KEY,
        UpdateExpression="ADD lastPostId :one",
        ExpressionAttributeValues={":one": 1},
        ReturnValues="UPDATED_NEW",
    )
    return int(result["Attributes"]["lastPostId"])


def lambda_handler(event, context):
    try:
        body = _parse_body(event)
    except (ValueError, UnicodeDecodeError):
        return _response(400, {"message": "body must be valid JSON"})

    error = _validate(body)
    if error:
        return _response(400, {"message": error})

    post = {
        "id": _next_post_id(),
        "author": {
            "id": GUEST_AUTHOR_ID,
            "name": body["author"]["name"].strip(),
            "role": body["author"]["role"],
        },
        "category": body["category"],
        "text": body["text"].strip(),
        # UTC の ISO 8601 形式 (例: 2026-10-15T09:00:00Z)。文字列の順と日時の順を揃える
        "postedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "replies": [],
    }

    # 同じ番号の投稿がすでにあれば書き込まない (上書き防止)
    table.put_item(
        Item={**post, "feed": "ALL"},
        ConditionExpression="attribute_not_exists(id)",
    )

    return _response(201, {"post": post})
