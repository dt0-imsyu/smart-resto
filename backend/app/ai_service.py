import json
import os
import re
import time
from typing import Any

from sqlalchemy.orm import Session

from .models import MenuItem


def get_menu_context(db: Session, excluded_terms: list[str] | None = None) -> str:
    excluded_terms = excluded_terms or []
    items = (
        db.query(MenuItem)
        .filter(MenuItem.is_available.is_(True))
        .order_by(MenuItem.category, MenuItem.title)
        .all()
    )
    if excluded_terms:
        items = [item for item in items if not _matches_terms(item, excluded_terms)]
    payload = [
        {
            "id": item.id,
            "title": item.title,
            "category": item.category,
            "description": item.description,
            "price": item.price,
            "ingredients": _decode_ingredients(item.ingredients),
            "calories": item.calories,
        }
        for item in items
    ]
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def get_compact_menu_context(db: Session) -> str:
    items = (
        db.query(MenuItem)
        .filter(MenuItem.is_available.is_(True))
        .order_by(MenuItem.category, MenuItem.title)
        .all()
    )
    payload = [
        {
            "id": item.id,
            "title": item.title,
            "category": item.category,
            "price": item.price,
        }
        for item in items
    ]
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def chat_with_waiter(db: Session, user_message: str, current_cart: list[int]) -> tuple[str, str]:
    excluded_terms = _allergy_excluded_terms(user_message)
    context = get_menu_context(db, excluded_terms=excluded_terms)
    cart_titles = _cart_titles(db, current_cart)
    allergy_note = ""
    if excluded_terms:
        allergy_note = (
            f" Клиент сообщил об аллергии. Не рекомендуй блюда, где в названии, описании "
            f"или ингредиентах есть эти признаки аллергена: {excluded_terms}."
        )
    prompt = (
        "Ты — профессиональный, вежливый ИИ-официант ресторана SmartResto. "
        f"Твоя задача — помогать клиенту с выбором еды. Ты имеешь доступ к АКТУАЛЬНОМУ МЕНЮ ресторана: {context}. "
        "Отвечай строго на основе этого меню. Если клиент просит блюдо, которого нет в меню, "
        "вежливо откажи и предложи альтернативу из доступного списка. Учитывай его запросы по калориям, "
        f"аллергиям и вкусам. Если в корзине пользователя уже есть блюда {cart_titles}, "
        f"ты можешь предложить подходящие к ним напитки или десерты.{allergy_note} "
        f"Запрос клиента: {user_message}"
    )
    response = _call_gemini(prompt)
    if response and not _text_matches_terms(response, excluded_terms):
        return response, "gemini"
    return _fallback_chat(db, user_message, current_cart), "fallback"


def suggest_upsell(db: Session, current_cart: list[int]) -> tuple[list[dict[str, Any]], str]:
    context = get_compact_menu_context(db)
    cart_titles = _cart_titles(db, current_cart)
    cart_ids = sorted(set(current_cart))
    prompt = (
        f"Проанализируй корзину {cart_titles} с id {cart_ids}. Выбери из меню {context} ровно 2 позиции "
        "(id и название), которые лучше всего подходят к этому заказу, например соус к пицце, "
        f"напиток к стейку или десерт после горячего. Не выбирай позиции с id {cart_ids}, "
        "потому что они уже есть в корзине. Верни ответ строго в формате JSON: "
        "{ \"upsell_items\": [ { \"id\": 1, \"reason\": \"...\" } ] }."
    )
    response = _call_gemini(prompt, json_mode=True)
    parsed = _parse_upsell_response(db, response, current_cart) if response else []
    if len(parsed) == 2:
        return parsed, "gemini"
    return _fallback_upsell(db, current_cart), "fallback"


def _call_gemini(prompt: str, json_mode: bool = False) -> str | None:
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if not api_key:
        return None
    for attempt in range(3):
        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=api_key)
            config = None
            if json_mode:
                config = types.GenerateContentConfig(response_mime_type="application/json")
            response = client.models.generate_content(
                model=os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
                contents=prompt,
                config=config,
            )
            text = getattr(response, "text", None)
            if text and text.strip():
                return text.strip()
        except Exception:
            if attempt == 2:
                return None
        time.sleep(0.75 * (attempt + 1))
    return None


def _parse_upsell_response(db: Session, response: str, current_cart: list[int]) -> list[dict[str, Any]]:
    try:
        data = json.loads(response)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", response, flags=re.DOTALL)
        if not match:
            return []
        try:
            data = json.loads(match.group(0))
        except json.JSONDecodeError:
            return []

    raw_items = data.get("upsell_items", [])
    if not isinstance(raw_items, list):
        return []

    cart_ids = set(current_cart)
    menu_by_id = {
        item.id: item
        for item in db.query(MenuItem).filter(MenuItem.is_available.is_(True)).all()
    }
    result = []
    for raw in raw_items:
        item_id = raw.get("id") if isinstance(raw, dict) else None
        if isinstance(item_id, str) and item_id.isdigit():
            item_id = int(item_id)
        if item_id in menu_by_id and item_id not in cart_ids:
            result.append(
                {
                    "id": item_id,
                    "title": menu_by_id[item_id].title,
                    "reason": str(raw.get("reason") or "Хорошо дополнит ваш заказ."),
                }
            )
        if len(result) == 2:
            break
    return result


def _fallback_chat(db: Session, user_message: str, current_cart: list[int]) -> str:
    message = user_message.lower()
    excluded_terms = _allergy_excluded_terms(user_message)
    items = db.query(MenuItem).filter(MenuItem.is_available.is_(True)).all()
    if excluded_terms:
        items = [item for item in items if not _matches_terms(item, excluded_terms)]
    candidates = items
    if any(word in message for word in ["легк", "низкокал", "калори", "диет"]):
        candidates = sorted(items, key=lambda item: item.calories)[:3]
    elif any(word in message for word in ["пицц", "pepperoni", "маргар"]):
        candidates = [item for item in items if item.category == "Пицца"][:3]
    elif any(word in message for word in ["суш", "ролл", "рыб", "лосос"]):
        candidates = [item for item in items if item.category in {"Суши", "Горячее"}][:3]
    elif any(word in message for word in ["десерт", "слад"]):
        candidates = [item for item in items if item.category == "Десерты"][:3]

    if not candidates:
        candidates = items[:3]
    chosen = ", ".join(f"{item.title} ({item.calories} ккал)" for item in candidates[:3])
    cart_note = ""
    if current_cart:
        upsell = _fallback_upsell(db, current_cart)
        if upsell:
            cart_note = f" К текущей корзине также подойдут: {', '.join(item['title'] for item in upsell)}."
    return (
        "Могу предложить только позиции из актуального меню SmartResto. "
        f"По вашему запросу лучше всего подходят: {chosen}.{cart_note}"
    )


def _fallback_upsell(db: Session, current_cart: list[int]) -> list[dict[str, Any]]:
    cart_ids = set(current_cart)
    cart_items = db.query(MenuItem).filter(MenuItem.id.in_(cart_ids)).all() if cart_ids else []
    categories = {item.category for item in cart_items}

    preferred_categories: list[str]
    if "Пицца" in categories:
        preferred_categories = ["Напитки", "Закуски", "Десерты"]
    elif "Суши" in categories:
        preferred_categories = ["Напитки", "Десерты", "Закуски"]
    elif "Горячее" in categories:
        preferred_categories = ["Салаты", "Напитки", "Десерты"]
    else:
        preferred_categories = ["Напитки", "Десерты", "Закуски"]

    items = (
        db.query(MenuItem)
        .filter(MenuItem.is_available.is_(True), MenuItem.id.notin_(cart_ids or {0}))
        .all()
    )
    ranked = sorted(
        items,
        key=lambda item: (
            preferred_categories.index(item.category)
            if item.category in preferred_categories
            else len(preferred_categories),
            item.price,
        ),
    )
    return [
        {
            "id": item.id,
            "title": item.title,
            "reason": _fallback_reason(item, categories),
        }
        for item in ranked[:2]
    ]


def _fallback_reason(item: MenuItem, cart_categories: set[str]) -> str:
    if item.category == "Напитки":
        return "Освежающий напиток сбалансирует вкус основных блюд."
    if item.category == "Десерты":
        return "Легко завершит заказ сладким акцентом."
    if item.category == "Закуски":
        return "Подойдет как дополнительная позиция к основному заказу."
    if "Горячее" in cart_categories and item.category == "Салаты":
        return "Свежий салат хорошо дополнит горячее блюдо."
    return "Хорошо сочетается с выбранными позициями."


def _cart_titles(db: Session, current_cart: list[int]) -> list[str]:
    if not current_cart:
        return []
    items = db.query(MenuItem).filter(MenuItem.id.in_(set(current_cart))).all()
    return [item.title for item in items]


def _decode_ingredients(raw: str) -> list[str]:
    try:
        decoded = json.loads(raw)
        return decoded if isinstance(decoded, list) else [str(decoded)]
    except json.JSONDecodeError:
        return [raw]


def _allergy_excluded_terms(user_message: str) -> list[str]:
    message = user_message.lower()
    if "аллерг" not in message:
        return []
    fish_markers = ["рыб", "мореп", "лосос", "тунец", "краб", "кревет", "суш", "ролл"]
    if any(marker in message for marker in fish_markers):
        return ["рыб", "мореп", "лосос", "тунец", "краб", "кревет", "суши", "ролл"]
    return []


def _matches_terms(item: MenuItem, terms: list[str]) -> bool:
    haystack = " ".join(
        [
            item.title,
            item.description,
            item.category,
            item.ingredients,
        ]
    ).lower()
    return _text_matches_terms(haystack, terms)


def _text_matches_terms(text: str, terms: list[str]) -> bool:
    lowered = text.lower()
    return any(term in lowered for term in terms)
