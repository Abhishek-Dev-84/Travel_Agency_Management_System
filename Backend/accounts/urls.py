from django.urls import path
from .views import RegisterView, LoginView, LogoutView, CurrentUserView, UserListCreateView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='api-register'),
    path('login/', LoginView.as_view(), name='api-login'),
    path('logout/', LogoutView.as_view(), name='api-logout'),
    path('me/', CurrentUserView.as_view(), name='api-me'),
    path('users/', UserListCreateView.as_view(), name='api-users'),
]
