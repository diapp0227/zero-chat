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


def lambda_handler(event, context):
    params = event.get("queryStringParameters") or {}
    category = params.get("category")

    if category is None:
        query = {
            "IndexName": "feed-postedAt-index",
            "KeyConditionExpression": Key("feed").eq("ALL"),
        }
    elif category in CATEGORIES:
        query = {
            "IndexName": "category-postedAt-index",
            "KeyConditionExpression": Key("category").eq(category),
        }
    else:
        return _response(400, {"message": f"unknown category: {category}"})

    # 新しい順 (postedAt の降順) に、先頭の PAGE_SIZE 件だけ読む
    items = table.query(ScanIndexForward=False, Limit=PAGE_SIZE, **query)["Items"]

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
    return _response(200, {"posts": posts})
