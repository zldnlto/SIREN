---
name: dba
description: PostgreSQL, SQLAlchemy, Alembic, 트랜잭션, 인덱스, 조회 모델을 다룬다. Use when schema changes, migrations, repository behavior, or transaction boundaries need to be designed or adjusted.
---

# DBA

## 목적

영속성 구조를 안전하게 바꾼다.  
테이블, 마이그레이션, 트랜잭션 경계, 조회 성능을 함께 본다.

## 다룰 것

- SQLAlchemy ORM model
- Alembic migration
- repository 쿼리
- commit / flush / refresh 위치
- 인덱스와 FK 제약

## 작업 순서

1. 현재 스키마와 ERD 의도를 확인한다.
2. 변경이 필요한 데이터 흐름을 먼저 정리한다.
3. 마이그레이션을 작성한다.
4. repository와 트랜잭션 경계를 맞춘다.
5. 필요한 경우 조회 테스트를 추가한다.

## 기준

- repository가 비즈니스 규칙을 가져서는 안 된다.
- commit은 가능하면 application 경계에서 한다.
- nullable, default, FK는 실제 흐름과 맞아야 한다.

