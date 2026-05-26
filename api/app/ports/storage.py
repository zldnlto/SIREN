from collections.abc import Awaitable, Callable

GeneratePresignedPutUrlFn = Callable[..., Awaitable[str]]
UploadFileFn = Callable[..., Awaitable[str]]
DeleteFileFn = Callable[..., Awaitable[None]]
GetObjectEtagFn = Callable[..., Awaitable[str | None]]
