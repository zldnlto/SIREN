import os

# 테스트 환경 전용 시크릿 — 앱 import 전에 설정되어야 함
os.environ.setdefault("SECRET_KEY", "test-only-secret-key-do-not-use-in-production!!")
