from __future__ import annotations


def is_active_user(user) -> bool:
    return user is not None and user.deleted_at is None

