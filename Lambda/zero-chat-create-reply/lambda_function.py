import base64
import json
import os
from datetime import datetime, timezone
from decimal import Decimal

import boto3

POSTS_TABLE_NAME = os.environ["POSTS_TABLE_NAME"]
PROFILES_TABLE_NAME = os.environ["PROFILES_TABLE_NAME"]

# 本文の最大文字数 (アプリの入力欄と揃える)
MAX_TEXT_LENGTH = 180

# 同時に返信されて保存がぶつかったときに、読み直して保存し直す回数
MAX_ATTEMPTS = 3

# ログインの仕組みができる前の投稿と同じく、返信した人の番号は 0 にする
AUTHOR_ID = 0

dynamodb = boto3.resource("dynamodb")
posts_table = dynamodb.Table(POSTS_TABLE_NAME)
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


def _post_id(event):
    """URL の {id} を投稿の番号にする。番号として読めなければ None を返す"""
    value = (event.get("pathParameters") or {}).get("id", "")
    if not value.isdigit():
        return None
    post_id = int(value)
    # 0 は投稿の番号を数える項目なので、投稿ではない
    return post_id if post_id >= 1 else None


def _parse_body(event):
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")
    return json.loads(body)


def _validate(body):
    """リクエストの中身を確かめる。問題があればその内容、なければ None を返す"""
    if not isinstance(body, dict):
        return "body must be a JSON object"

    text = body.get("text")
    if not isinstance(text, str) or not text.strip():
        return "text is required"
    if len(text.strip()) > MAX_TEXT_LENGTH:
        return f"text must be at most {MAX_TEXT_LENGTH} characters"

    return None


def _append_reply(post_id, author, text):
    """投稿に返信を 1 件書き足し、書き足した返信を返す。投稿がなければ None を返す"""
    for _ in range(MAX_ATTEMPTS):
        post = posts_table.get_item(
            Key={"id": post_id},
            ProjectionExpression="id, feed, replies",
        ).get("Item")
        # feed がない項目 (番号を数える項目など) は投稿ではない
        if post is None or "feed" not in post:
            return None

        replies = post.get("replies", [])
        reply = {
            # 投稿の中で一意な番号 (今ある返信の番号の最大値 + 1)
            "id": max((int(r["id"]) for r in replies), default=0) + 1,
            "author": author,
            "text": text,
            # UTC の ISO 8601 形式 (例: 2026-10-16T09:00:00Z)。投稿の postedAt と同じ形
            "repliedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }

        # 読んだときから返信が増えていなければ書き足す。増えていたら番号がぶつかるので読み直す
        if "replies" in post:
            condition = "size(replies) = :count"
            values = {":count": len(replies)}
        else:
            condition = "attribute_not_exists(replies)"
            values = {}
        try:
            posts_table.update_item(
                Key={"id": post_id},
                UpdateExpression="SET replies = list_append(if_not_exists(replies, :empty), :new)",
                ConditionExpression=condition,
                ExpressionAttributeValues={**values, ":empty": [], ":new": [reply]},
            )
            return reply
        except posts_table.meta.client.exceptions.ConditionalCheckFailedException:
            continue

    raise RuntimeError(f"replies of post {post_id} kept changing")


def lambda_handler(event, context):
    user_id = _user_id(event)
    if not user_id:
        # オーソライザーを付け忘れたルートから呼ばれたとき
        return _response(401, {"message": "Unauthorized"})

    post_id = _post_id(event)
    if post_id is None:
        return _response(404, {"message": "post not found"})

    try:
        body = _parse_body(event)
    except (ValueError, UnicodeDecodeError):
        return _response(400, {"message": "body must be valid JSON"})

    error = _validate(body)
    if error:
        return _response(400, {"message": error})

    # 返信した人は、アプリから送られた値ではなくプロフィールから決める
    profile = profiles_table.get_item(Key={"userId": user_id}).get("Item")
    if profile is None:
        return _response(400, {"message": "profile is required"})
    author = {
        "id": AUTHOR_ID,
        "name": profile["name"],
        "role": profile["role"],
        "color1": profile["color1"],
        "color2": profile["color2"],
    }

    reply = _append_reply(post_id, author, body["text"].strip())
    if reply is None:
        return _response(404, {"message": "post not found"})

    return _response(201, {"reply": reply})
