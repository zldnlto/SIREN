from collections.abc import Awaitable, Callable
from typing import Any

GeneratePresignedPutUrlFn = Callable[..., Awaitable[str]]
UploadFileFn = Callable[..., Awaitable[str]]
DeleteFileFn = Callable[..., Awaitable[None]]
GetObjectEtagFn = Callable[..., Awaitable[str | None]]
RunInferenceFn = Callable[..., Awaitable[list[Any]]]
