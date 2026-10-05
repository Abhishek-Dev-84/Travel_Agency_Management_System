from rest_framework import generics, status, views, permissions
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import login as django_login, logout as django_logout

from .models import User
from .serializers import (
    UserSerializer,
    RegisterSerializer,
    LoginSerializer,
    ProfileUpdateSerializer
)
from .permissions import IsStaffOrAdminUser


class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Generate auth token
        token, _ = Token.objects.get_or_create(user=user)

        # Also create customer record in bookings.models if available
        try:
            from bookings.models import Customer
            Customer.objects.get_or_create(
                user=user,
                defaults={
                    'name': user.full_name,
                    'email': user.email,
                    'phone': user.phone,
                    'address': user.address,
                    'identity_type': user.identity_type,
                    'identity_number': user.identity_number,
                }
            )
        except Exception:
            pass

        return Response({
            'message': 'Account created successfully.',
            'token': token.key,
            'user': UserSerializer(user).data
        }, status=status.HTTP_201_CREATED)


class LoginView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']

        django_login(request, user)
        token, _ = Token.objects.get_or_create(user=user)

        # Determine dashboard URL by role
        dashboards = {
            'ADMIN': 'admin-dashboard.html',
            'STAFF': 'admin-dashboard.html',
            'DRIVER': 'driver-dashboard.html',
            'CUSTOMER': 'customer-dashboard.html',
        }

        return Response({
            'message': 'Signed in successfully.',
            'token': token.key,
            'role': user.role.lower(),
            'dashboard': dashboards.get(user.role, 'index.html'),
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)


class LogoutView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        if request.user.is_authenticated:
            Token.objects.filter(user=request.user).delete()
            django_logout(request)
        return Response({'message': 'Signed out successfully.'}, status=status.HTTP_200_OK)


class CurrentUserView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        serializer = ProfileUpdateSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Update customer record if exists
        try:
            from bookings.models import Customer
            cust = Customer.objects.filter(user=user).first()
            if cust:
                if 'first_name' in request.data or 'last_name' in request.data:
                    cust.name = user.full_name
                if 'phone' in request.data:
                    cust.phone = user.phone
                if 'address' in request.data:
                    cust.address = user.address
                if 'identity_type' in request.data:
                    cust.identity_type = user.identity_type
                if 'identity_number' in request.data:
                    cust.identity_number = user.identity_number
                cust.save()
        except Exception:
            pass

        return Response({
            'message': 'Profile updated successfully.',
            'user': UserSerializer(user).data
        })


class UserListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsStaffOrAdminUser]
    serializer_class = UserSerializer

    def get_queryset(self):
        role = self.request.query_params.get('role')
        qs = User.objects.all().order_by('-date_joined')
        if role:
            qs = qs.filter(role__iexact=role)
        return qs
