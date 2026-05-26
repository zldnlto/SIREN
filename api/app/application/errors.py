class UseCaseError(Exception):
    pass


class NotFoundError(UseCaseError):
    pass


class ForbiddenError(UseCaseError):
    pass


class InvalidInputError(UseCaseError):
    pass


class InvalidCredentialsError(UseCaseError):
    pass


class UnsupportedMediaTypeError(UseCaseError):
    pass


class PayloadTooLargeError(UseCaseError):
    pass


class InvalidUploadKeyError(UseCaseError):
    pass


class UploadVerificationError(UseCaseError):
    pass


class ConflictError(UseCaseError):
    pass
