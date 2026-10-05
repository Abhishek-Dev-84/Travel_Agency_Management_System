from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from .models import User


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.ReadOnlyField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'full_name', 'role', 'phone', 'address', 'blood_group',
            'identity_type', 'identity_number', 'is_active', 'date_joined'
        ]
        read_only_fields = ['id', 'date_joined', 'full_name', 'is_active']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    name = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ['email', 'password', 'name', 'phone', 'address']

    def validate_email(self, value):
        norm_email = value.lower().strip()
        if User.objects.filter(email__iexact=norm_email).exists():
            raise serializers.ValidationError("An account with this email address already exists.")
        return norm_email

    def create(self, validated_data):
        password = validated_data.pop('password')
        name = validated_data.pop('name', '').strip()
        email = validated_data.get('email').lower().strip()

        # Derive first and last name
        first_name = name
        last_name = ''
        if ' ' in name:
            parts = name.split(' ', 1)
            first_name = parts[0]
            last_name = parts[1]

        # Use email prefix or unique slug as username
        username = email.split('@')[0]
        base_username = username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1

        user = User(
            username=username,
            first_name=first_name,
            last_name=last_name,
            role=User.Role.CUSTOMER,
            **validated_data
        )
        user.set_password(password)
        user.save()
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)
    role = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        login_id = attrs.get('email', '').strip()
        password = attrs.get('password', '')
        requested_role = attrs.get('role', '').strip().upper()

        if not login_id or not password:
            raise serializers.ValidationError("Please provide both email/username and password.")

        # Find user by email (case-insensitive) or by username
        user = None
        user_by_email = User.objects.filter(email__iexact=login_id).first()
        if user_by_email:
            user = authenticate(username=user_by_email.username, password=password)
        else:
            user = authenticate(username=login_id, password=password)

        if not user:
            raise serializers.ValidationError("Invalid credentials. Please check your email and password.")

        if not user.is_active:
            raise serializers.ValidationError("This account has been deactivated.")

        # If user explicitly selected a role (e.g. on frontend role toggle), check role matching
        if requested_role and user.role != requested_role and not user.is_superuser:
            # Allow admin to access staff or if requested role matches user's role
            if not (user.role == 'ADMIN' and requested_role in ['ADMIN', 'STAFF']):
                raise serializers.ValidationError(
                    f"Account role is {user.get_role_display()}, but you attempted to sign in as {requested_role.capitalize()}."
                )

        attrs['user'] = user
        return attrs


class ProfileUpdateSerializer(serializers.ModelSerializer):
    name = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            'name', 'first_name', 'last_name', 'phone', 'address',
            'blood_group', 'identity_type', 'identity_number'
        ]

    def update(self, instance, validated_data):
        name = validated_data.pop('name', None)
        if name is not None:
            name = name.strip()
            if ' ' in name:
                parts = name.split(' ', 1)
                instance.first_name = parts[0]
                instance.last_name = parts[1]
            else:
                instance.first_name = name
                instance.last_name = ''
        return super().update(instance, validated_data)

