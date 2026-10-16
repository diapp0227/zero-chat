import base64
import binascii
import json
import os
from decimal import Decimal

import boto3
from boto3.dynamodb.conditions import Key

TABLE_NAME = os.environ["TABLE_NAME"]
PROFILES_TABLE_NAME = os.environ["PROFILES_TABLE_NAME"]
CATEGORIES = {"announcement", "dailyReport", "selfStudy"}

# 1 回のリクエストで返す投稿の最大件数
PAGE_SIZE = 10

# BatchGetItem で 1 回に読めるキーの最大数
BATCH_GET_LIMIT = 100

# プロフィールから、投稿・返信の author に上書きする項目
PROFILE_FIELDS = ("name", "role", "color1", "color2")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


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


def _load_profiles(user_ids):
    """userId (Cognito の sub) ごとの最新のプロフィールを読む。見つからない人は含めない"""
    profiles = {}
    keys = [{"userId": user_id} for user_id in sorted(user_ids)]
    for start in range(0, len(keys), BATCH_GET_LIMIT):
        request = {PROFILES_TABLE_NAME: {"Keys": keys[start : start + BATCH_GET_LIMIT]}}
        # 読み切れなかったキー (UnprocessedKeys) が返ってきたら、読み切るまで続ける
        while request:
            result = dynamodb.batch_get_item(RequestItems=request)
            for item in result["Responses"].get(PROFILES_TABLE_NAME, []):
                profiles[item["userId"]] = item
            request = result.get("UnprocessedKeys") or None
    return profiles


def _to_author(author, profiles):
    """保存してある author を、最新のプロフィールで上書きした形にする

    userId がない (古い投稿・返信) か、プロフィールが見つからないときは、保存してある値のまま。
    userId (sub) はレスポンスに含めない
    """
    profile = profiles.get(author.get("userId"))
    latest = {field: profile[field] for field in PROFILE_FIELDS if field in profile} if profile else {}
    return {k: v for k, v in {**author, **latest}.items() if k != "userId"}


def _encode_cursor(last_key):
    """DynamoDB の LastEvaluatedKey を、URL に入れられる文字列 (nextCursor) にする"""
    if not last_key:
        return None
    raw = json.dumps(last_key, default=_to_json, separators=(",", ":"))
    return base64.urlsafe_b64encode(raw.encode("utf-8")).decode("ascii").rstrip("=")


def _decode_cursor(cursor, index_key):
    """cursor を Query の ExclusiveStartKey に戻す。読めないときや、別の一覧の目印なら None を返す

    [index_key] は今の一覧のインデックスのキー (例: {"feed": "ALL"})。
    手で作った目印を DynamoDB に渡してエラー (500) にならないよう、形を確かめる
    """
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        key = json.loads(base64.urlsafe_b64decode(padded.encode("ascii")))
    except (ValueError, UnicodeError, binascii.Error):
        return None
    expected = {"id", "postedAt", *index_key}
    if not isinstance(key, dict) or set(key) != expected:
        return None
    if not isinstance(key["id"], int) or not isinstance(key["postedAt"], str):
        return None
    if any(key[name] != value for name, value in index_key.items()):
        return None
    return key


def lambda_handler(event, context):
    params = event.get("queryStringParameters") or {}
    category = params.get("category")

    if category is None:
        index_key = {"feed": "ALL"}
        query = {
            "IndexName": "feed-postedAt-index",
            "KeyConditionExpression": Key("feed").eq("ALL"),
        }
    elif category in CATEGORIES:
        index_key = {"category": category}
        query = {
            "IndexName": "category-postedAt-index",
            "KeyConditionExpression": Key("category").eq(category),
        }
    else:
        return _response(400, {"message": f"unknown category: {category}"})

    # cursor があれば、前回のページの続き (それより古い投稿) から読む
    cursor = params.get("cursor")
    if cursor is not None:
        start_key = _decode_cursor(cursor, index_key)
        if start_key is None:
            return _response(400, {"message": "invalid cursor"})
        query["ExclusiveStartKey"] = start_key

    # 新しい順 (postedAt の降順) に、PAGE_SIZE 件だけ読む
    result = table.query(ScanIndexForward=False, Limit=PAGE_SIZE, **query)
    items = result["Items"]

    # 表示する投稿・返信の人のプロフィールを、まとめて 1 回 (100 人ごと) で読む
    user_ids = {
        author["userId"]
        for item in items
        for author in [item["author"], *(r["author"] for r in item.get("replies", []))]
        if "userId" in author
    }
    profiles = _load_profiles(user_ids) if user_ids else {}

    posts = [
        {
            "id": item["id"],
            "author": _to_author(item["author"], profiles),
            "category": item["category"],
            "text": item["text"],
            "postedAt": item["postedAt"],
            "replies": [
                {**reply, "author": _to_author(reply["author"], profiles)}
                for reply in item.get("replies", [])
            ],
        }
        for item in items
    ]
    # 続きがあるときだけ、次のページの目印を返す (最後のページなら null)
    next_cursor = _encode_cursor(result.get("LastEvaluatedKey"))
    return _response(200, {"posts": posts, "nextCursor": next_cursor})
