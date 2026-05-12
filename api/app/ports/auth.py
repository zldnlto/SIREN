from collections.abc import Callable

CreateAccessTokenFn = Callable[..., str]
VerifyPasswordFn = Callable[..., bool]

