import json
import os

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]

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


def lambda_handler(event, context):
    user_id = _user_id(event)
    if not user_id:
        # オーソライザーを付け忘れたルートから呼ばれたとき
        return _response(401, {"message": "Unauthorized"})

    item = table.get_item(Key={"userId": user_id}).get("Item")
    if item is None:
        # まだプロフィールを保存していない
        return _response(404, {"message": "profile not found"})

    profile = {
        "name": item["name"],
        "role": item["role"],
        "color1": item["color1"],
        "color2": item["color2"],
        "updatedAt": item["updatedAt"],
    }
    return _response(200, {"profile": profile})
