from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'role', 'phone', 'is_staff')
    list_filter = ('role', 'is_staff', 'is_superuser', 'is_active')
    fieldsets = BaseUserAdmin.fieldsets + (
        ('TAMS Profile', {
            'fields': ('role', 'phone', 'address', 'blood_group', 'identity_type', 'identity_number')
        }),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('TAMS Profile', {
            'fields': ('role', 'phone', 'address', 'blood_group', 'identity_type', 'identity_number')
        }),
    )
