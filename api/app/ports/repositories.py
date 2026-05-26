from collections.abc import Awaitable, Callable
from typing import Any

CreateInspectionFn = Callable[..., Awaitable[Any]]
GetInspectionByIdFn = Callable[..., Awaitable[Any]]
UpdateInspectionStatusFn = Callable[..., Awaitable[Any]]
UpdateInspectionImageKeysFn = Callable[..., Awaitable[Any]]
CreateManyDefectsFn = Callable[..., Awaitable[Any]]
GetUserByEmployeeIdFn = Callable[..., Awaitable[Any]]
GetGuidanceByOntologyIdFn = Callable[..., Awaitable[Any]]
CreateDetectionJobFn = Callable[..., Awaitable[Any]]
GetActiveDetectionJobFn = Callable[..., Awaitable[Any]]
UpdateDetectionJobStatusFn = Callable[..., Awaitable[Any]]
