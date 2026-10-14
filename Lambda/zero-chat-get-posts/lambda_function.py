import json
import os
from decimal import Decimal

import boto3
from boto3.dynamodb.conditions import Key

TABLE_NAME = os.environ["TABLE_NAME"]
CATEGORIES = {"announcement", "dailyReport", "selfStudy"}

# 1 回のリクエストで返す投稿の最大件数
PAGE_SIZE = 10

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
    result = table.query(ScanIndexForward=False, Limit=PAGE_SIZE, **query)

    posts = [
        {
            "id": item["id"],
            "author": item["author"],
            "category": item["category"],
            "text": item["text"],
            "postedAt": item["postedAt"],
            "replies": item.get("replies", []),
        }
        for item in result["Items"]
    ]
    return _response(200, {"posts": posts})
