import base64
import json
import os
from datetime import datetime, timezone
from decimal import Decimal

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
PROFILES_TABLE_NAME = os.environ["PROFILES_TABLE_NAME"]
CATEGORIES = {"announcement", "dailyReport", "selfStudy"}

# 本文の最大文字数 (アプリの入力欄と揃える)
MAX_TEXT_LENGTH = 180

# 投稿の番号を数えるための項目のキー。
# feed / category / postedAt を持たないので、インデックスに載らずタイムラインには出ない
COUNTER_KEY = {"id": 0}

# 投稿した人の番号。プロフィールで名前・役職・色を決めるようになったが、番号はまだ使わないので 0 にする
AUTHOR_ID = 0

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
profiles_table = dynamodb.Table(PROFILES_TABLE_NAME)


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
    """リクエストの中身を確かめる。問題があればその内容、なければ None を返す

    投稿した人 (author) は送られてきても使わないので確かめない
    """
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

    # 投稿した人は、アプリから送られた値ではなくプロフィールから決める
    profile = profiles_table.get_item(Key={"userId": user_id}).get("Item")
    if profile is None:
        return _response(400, {"message": "profile is required"})

    post = {
        "id": _next_post_id(),
        "author": {
            "id": AUTHOR_ID,
            "name": profile["name"],
            "role": profile["role"],
            "color1": profile["color1"],
            "color2": profile["color2"],
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
