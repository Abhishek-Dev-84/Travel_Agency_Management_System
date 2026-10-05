from rest_framework import permissions


class IsAdminUserRole(permissions.BasePermission):
    """
    Allows access only to users with the ADMIN role or superuser status.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role == 'ADMIN' or request.user.is_superuser)
        )


class IsStaffOrAdminUser(permissions.BasePermission):
    """
    Allows access to operational staff and administrators.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role in ['ADMIN', 'STAFF'] or request.user.is_staff or request.user.is_superuser)
        )


class IsDriverUser(permissions.BasePermission):
    """
    Allows access to drivers.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.role == 'DRIVER'
        )


class IsCustomerUser(permissions.BasePermission):
    """
    Allows access to customers.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.role == 'CUSTOMER'
        )


class ReadOnlyOrStaffAdmin(permissions.BasePermission):
    """
    Safe methods (GET, HEAD, OPTIONS) allowed for authenticated users.
    Write operations restricted to Staff and Admins.
    """
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role in ['ADMIN', 'STAFF'] or request.user.is_staff or request.user.is_superuser)
        )
